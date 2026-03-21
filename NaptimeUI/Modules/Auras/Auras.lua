-- Modules/Auras.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.Auras = ns.Modules.Auras or {}
local A = ns.Modules.Auras

local Pixel  = ns.Pixel
local Border = ns.Border

-- ============================================================
-- Constants / state
-- ============================================================

local MAX_BUFFS           = 32
local MAX_DEBUFFS         = 16
local MAX_WEAPON_ENCHANTS = 2

local buffContainer, debuffContainer
local buffFrames, debuffFrames = {}, {}

local initialized = false
local eventFrame
local onUpdateFrame

local needsUpdate = false
local throttleTimer = 0
local THROTTLE_INTERVAL = 0.10

local needsStyleRefresh = false
local needsPostCombatWork = false

local activeWeaponEnchantCount = 0

local auraNameCache = {}

local blizzardAuraHider
local blizzardAuraFramesHidden = false

local DEBUFF_COLORS = {
    Magic   = {0.2, 0.6, 1.0, 1},
    Curse   = {0.6, 0.0, 1.0, 1},
    Disease = {0.6, 0.4, 0.0, 1},
    Poison  = {0.0, 0.6, 0.0, 1},
    none    = {1.0, 0.0, 0.0, 1},
}

-- ============================================================
-- Config / helpers
-- ============================================================

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return nil end
    if type(cfg.auras) ~= "table" then return nil end
    return cfg.auras
end

local function Clamp(v, minv, maxv)
    v = tonumber(v) or minv
    if v < minv then return minv end
    if v > maxv then return maxv end
    return v
end

local function UnpackRGBA(t, r, g, b, a)
    if type(t) == "table" then
        return t[1] or r, t[2] or g, t[3] or b, t[4] or a
    end
    return r, g, b, a
end

local function IsEnabled()
    local cfg = GetCfg()
    return cfg and cfg.enabled ~= false
end

local function AuraSizePx()
    local cfg = GetCfg()
    return math.max(8, tonumber(cfg and cfg.sizePx) or 32)
end

local function AuraGapPx()
    local cfg = GetCfg()
    return math.max(0, tonumber(cfg and cfg.gapPx) or 2)
end

local function AuraPerRow(isDebuff)
    local cfg = GetCfg()
    if not cfg then return 12 end
    local anchor = isDebuff and cfg.debuffAnchor or cfg.buffAnchor
    local perRow = (type(anchor) == "table" and anchor.perRow) or cfg.perRow or 12
    return math.max(1, tonumber(perRow) or 12)
end

local function GetAnchor(isDebuff)
    local cfg = GetCfg()
    return cfg and (isDebuff and cfg.debuffAnchor or cfg.buffAnchor) or nil
end

local function AuraBorderPx()
    local cfg = GetCfg()
    return math.max(1, tonumber(cfg and cfg.borderPx) or 1)
end

local function AuraBorderRGBA()
    local cfg = GetCfg()
    return cfg and cfg.borderRGBA or {0,0,0,1}
end

local function AuraBGRGBA()
    local cfg = GetCfg()
    return cfg and cfg.bgRGBA or {0,0,0,0.35}
end

local function AuraIconZoom()
    local cfg = GetCfg()
    return Clamp(tonumber(cfg and cfg.iconZoom) or 0.10, 0, 0.35)
end

local function ShouldShowWeaponEnchants()
    local cfg = GetCfg()
    if not cfg then return true end
    if cfg.showWeaponEnchants == nil then return true end
    return cfg.showWeaponEnchants and true or false
end

local function ShouldHideBlizzardAuras()
    local cfg = GetCfg()
    if not cfg then return true end
    if cfg.hideBlizzardBuffs == nil then return true end
    return cfg.hideBlizzardBuffs and true or false
end

local function IsNameBlocked(name)
    local cfg = GetCfg()
    if not cfg or type(cfg.blockedBuffs) ~= "table" or not name then return false end
    local ok, result = pcall(function() return cfg.blockedBuffs[name] end)
    return ok and result or false
end

local function ResolveFont(fontKey)
    if type(fontKey) ~= "string" or fontKey == "" then
        return STANDARD_TEXT_FONT
    end

    if ns.GetFont then
        local ok, path = pcall(ns.GetFont, ns, fontKey)
        if ok and type(path) == "string" and path ~= "" then return path end
    end

    if ns.Media and ns.Media.GetFont then
        local ok, path = pcall(ns.Media.GetFont, ns.Media, fontKey)
        if ok and type(path) == "string" and path ~= "" then return path end
    end

    local cfg = GetCfg()
    if cfg and type(cfg.fonts) == "table" and type(cfg.fonts[fontKey]) == "string" then
        return cfg.fonts[fontKey]
    end

    if fontKey == "Default" then
        return STANDARD_TEXT_FONT
    end

    return STANDARD_TEXT_FONT
end

local function SafeSetFont(fs, fontKey, size, flags)
    if not (fs and fs.SetFont) then return end

    local pxSize = tonumber(size) or 11
    local fontFlags = flags or ""

    local primary = ResolveFont(fontKey)
    local fallbackDefault = ResolveFont("Default")
    local fallbackBlizz = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"

    local ok, ret = pcall(fs.SetFont, fs, primary, pxSize, fontFlags)
    if ok and ret ~= false then return end

    ok, ret = pcall(fs.SetFont, fs, fallbackDefault, pxSize, fontFlags)
    if ok and ret ~= false then return end

    pcall(fs.SetFont, fs, fallbackBlizz, pxSize, fontFlags)
end

local function SetTexCrop(tex, zoom)
    if not tex then return end
    tex:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
end

local function FormatTime(seconds)
    if not seconds or seconds <= 0 then return "" end
    if seconds >= 86400 then
        return string.format("%dd", math.ceil(seconds / 86400))
    elseif seconds >= 3600 then
        return string.format("%dh", math.ceil(seconds / 3600))
    elseif seconds >= 60 then
        return string.format("%dm", math.ceil(seconds / 60))
    else
        return string.format("%d", math.floor(seconds + 0.5))
    end
end

local function PxToLU(pxCount, frameOrScale)
    if Pixel and Pixel.Multiple then
        local scale
        if type(frameOrScale) == "number" then
            scale = frameOrScale
        elseif frameOrScale and frameOrScale.GetEffectiveScale then
            scale = frameOrScale:GetEffectiveScale()
        end
        return Pixel:Multiple(pxCount, scale)
    end
    return tonumber(pxCount) or 0
end

local function SetSizePx(frame, wPx, hPx)
    if not frame then return end
    if Pixel and Pixel.SetSizePx then
        Pixel:SetSizePx(frame, wPx, hPx)
    else
        frame:SetSize(wPx, hPx)
    end
end

local function SetPointPx(frame, point, rel, relPoint, xPx, yPx)
    if not frame then return end
    frame:ClearAllPoints()
    if Pixel and Pixel.SetPointPx then
        Pixel:SetPointPx(frame, point, rel, relPoint, xPx, yPx)
    else
        frame:SetPoint(point, rel or UIParent, relPoint or point, xPx or 0, yPx or 0)
    end
end

local function EnforcePixel(frame)
    if Pixel and Pixel.Enforce and frame and not frame.__nolAuraPixelEnforced then
        frame.__nolAuraPixelEnforced = true
        Pixel:Enforce(frame)
    end
end

-- ============================================================
-- Secret-safe aura cache (WoW 12.0)
-- ============================================================

local function CacheSetName(instanceID, name)
    if not instanceID or not name then return end

    local nameOk = pcall(function()
        local t = {}
        t[name] = true
    end)
    if not nameOk then return end

    pcall(function()
        auraNameCache[instanceID] = name
    end)
end

local function CacheGetName(instanceID)
    if not instanceID then return nil end
    local ok, val = pcall(function() return auraNameCache[instanceID] end)
    if not ok or type(val) ~= "string" then return nil end
    return val
end

local function CacheClearID(instanceID)
    if not instanceID then return end
    pcall(function() auraNameCache[instanceID] = nil end)
end

local function RebuildInitialAuraNameCache()
    wipe(auraNameCache)
    if not (AuraUtil and AuraUtil.ForEachAura) then return end

    AuraUtil.ForEachAura("player", "HELPFUL", nil, function(aura)
        if aura and aura.auraInstanceID then
            CacheSetName(aura.auraInstanceID, aura.name)
        end
    end, true)

    AuraUtil.ForEachAura("player", "HARMFUL", nil, function(aura)
        if aura and aura.auraInstanceID then
            CacheSetName(aura.auraInstanceID, aura.name)
        end
    end, true)
end

-- ============================================================
-- Blizzard aura frames hide (defer in combat)
-- ============================================================

local function HideBlizzardAuraFrames()
    if blizzardAuraFramesHidden then return end
    if not ShouldHideBlizzardAuras() then return end

    if InCombatLockdown and InCombatLockdown() then
        needsPostCombatWork = true
        return
    end

    if not blizzardAuraHider then
        blizzardAuraHider = CreateFrame("Frame", nil, UIParent)
        blizzardAuraHider:Hide()
    end

    if BuffFrame then BuffFrame:SetParent(blizzardAuraHider) end
    if DebuffFrame then DebuffFrame:SetParent(blizzardAuraHider) end

    blizzardAuraFramesHidden = true
end

-- ============================================================
-- Border wrapper
-- ============================================================

local function ApplyBorder(frame, thicknessPx, rgba)
    if not frame then return end

    if Border and Border.Apply then
        Border:Apply(frame, thicknessPx, rgba)
        return
    end

    if not frame.__auraFallbackBorder then
        local b = CreateFrame("Frame", nil, frame)
        b:SetAllPoints(frame)
        b:SetFrameLevel((frame:GetFrameLevel() or 0) + 10)
        b:EnableMouse(false)

        b.Top    = b:CreateTexture(nil, "OVERLAY", nil, 1)
        b.Bottom = b:CreateTexture(nil, "OVERLAY", nil, 1)
        b.Left   = b:CreateTexture(nil, "OVERLAY", nil, 1)
        b.Right  = b:CreateTexture(nil, "OVERLAY", nil, 1)

        for _, tex in ipairs({ b.Top, b.Bottom, b.Left, b.Right }) do
            tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        end

        frame.__auraFallbackBorder = b
    end

    local b = frame.__auraFallbackBorder
    local r, g, bl, a = UnpackRGBA(rgba, 0, 0, 0, 1)
    local t = PxToLU(thicknessPx or 1, frame)
    if not t or t <= 0 then t = 1 end

    for _, tex in ipairs({ b.Top, b.Bottom, b.Left, b.Right }) do
        tex:SetVertexColor(r, g, bl, a)
        tex:Show()
    end

    b.Top:ClearAllPoints()
    b.Top:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    b.Top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    b.Top:SetHeight(t)

    b.Bottom:ClearAllPoints()
    b.Bottom:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  0, 0)
    b.Bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    b.Bottom:SetHeight(t)

    b.Left:ClearAllPoints()
    b.Left:SetPoint("TOPLEFT",    frame, "TOPLEFT",    0, 0)
    b.Left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    b.Left:SetWidth(t)

    b.Right:ClearAllPoints()
    b.Right:SetPoint("TOPRIGHT",    frame, "TOPRIGHT",    0, 0)
    b.Right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    b.Right:SetWidth(t)
end

local function UpdateBorder(frame, thicknessPx, rgba)
    if not frame then return end
    if Border and Border.Update then
        Border:Update(frame, thicknessPx, rgba)
    else
        ApplyBorder(frame, thicknessPx, rgba)
    end
end

-- ============================================================
-- Weapon enchant helpers
-- ============================================================

local function GetEnchantTexture(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellTexture then
        local t = C_Spell.GetSpellTexture(spellID)
        if t then return t end
    end
    if GetSpellTexture then return GetSpellTexture(spellID) end
    return nil
end

local function GetEnchantName(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    end
    if GetSpellInfo then return GetSpellInfo(spellID) end
    return nil
end

-- ============================================================
-- Frame creation / style
-- ============================================================

local function ConfigureCooldownVisuals(cd, hideCountdownNumbers, fontKey, fontSize, fontFlags, fontRGBA)
    if not cd then return end
    cd:SetDrawEdge(false)
    if cd.SetDrawBling then cd:SetDrawBling(false) end
    cd:SetDrawSwipe(false)
    if cd.SetSwipeColor then cd:SetSwipeColor(0, 0, 0, 0) end
    cd:SetReverse(true)

    if hideCountdownNumbers ~= nil and cd.SetHideCountdownNumbers then
        cd:SetHideCountdownNumbers(hideCountdownNumbers and true or false)
    end

    if (not hideCountdownNumbers) and fontKey and cd.GetRegions then
        local r, g, b, a = UnpackRGBA(fontRGBA, 1, 1, 1, 1)
        local n = select("#", cd:GetRegions())
        for i = 1, n do
            local region = select(i, cd:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                SafeSetFont(region, fontKey, fontSize, fontFlags)
                region:SetShadowOffset(0, 0)
                region:SetTextColor(r, g, b, a)
            end
        end
    end
end

local function ApplyFontString(fs, fontKey, size, flags, rgba, pointInfo, justifyH)
    if not fs then return end

    fs:ClearAllPoints()
    SafeSetFont(fs, fontKey, size, flags)
    fs:SetShadowOffset(0, 0)
    fs:SetJustifyH(justifyH or "CENTER")

    local r, g, b, a = UnpackRGBA(rgba, 1, 1, 1, 1)
    fs:SetTextColor(r, g, b, a)

    if type(pointInfo) == "table" then
        local p = pointInfo[1] or "CENTER"
        local xPx = tonumber(pointInfo[2]) or 0
        local yPx = tonumber(pointInfo[3]) or 0
        fs:SetPoint(p, fs:GetParent(), p, PxToLU(xPx, fs:GetParent()), PxToLU(yPx, fs:GetParent()))
    else
        fs:SetPoint("CENTER", fs:GetParent(), "CENTER", 0, 0)
    end
end

local function ApplyTextStyle(frame, isDebuff)
    local cfg = GetCfg()
    if not cfg or not frame then return end

    if isDebuff then
        local c = cfg.debuffCount or {}
        local t = cfg.debuffTime or {}
        ApplyFontString(frame.count, c.font, c.size, c.flags, c.rgba, c.point, c.justifyH)
        ApplyFontString(frame.duration, t.font, t.size, t.flags, t.rgba, t.point, t.justifyH)
    else
        local c = cfg.buffCount or {}
        local t = cfg.buffTime or {}
        ApplyFontString(frame.count, c.font, c.size, c.flags, c.rgba, c.point, c.justifyH)
        ApplyFontString(frame.duration, t.font, t.size, t.flags, t.rgba, t.point, t.justifyH)
    end
end

local function CreateIconFrame(parent, isDebuff)
    local f = CreateFrame("Button", nil, parent)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel((parent:GetFrameLevel() or 1) + 2)
    EnforcePixel(f)

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetTexture("Interface\\Buttons\\WHITE8X8")

    f.icon = f:CreateTexture(nil, "ARTWORK")

    f.cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    ConfigureCooldownVisuals(f.cooldown, false)

    f.count    = f:CreateFontString(nil, "OVERLAY")
    f.duration = f:CreateFontString(nil, "OVERLAY")

    f.isDebuff        = isDebuff and true or false
    f.auraInstanceID  = nil
    f.buffIndex       = nil
    f.isWeaponEnchant = false
    f.enchantID       = nil
    f.enchantExpiry   = nil

    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")

        if self.isWeaponEnchant and self.enchantID then
            if GameTooltip.SetSpellByID then
                GameTooltip:SetSpellByID(self.enchantID)
            else
                GameTooltip:AddLine(GetEnchantName(self.enchantID) or "Weapon Enchant")
            end
        elseif self.auraInstanceID then
            if self.isDebuff then
                if GameTooltip.SetUnitDebuffByAuraInstanceID then
                    GameTooltip:SetUnitDebuffByAuraInstanceID("player", self.auraInstanceID)
                end
            else
                if GameTooltip.SetUnitBuffByAuraInstanceID then
                    GameTooltip:SetUnitBuffByAuraInstanceID("player", self.auraInstanceID)
                end
            end
        end

        GameTooltip:Show()
    end)

    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    if not isDebuff then
        f:RegisterForClicks("RightButtonUp")
        f:SetScript("OnClick", function(self, button)
            if button ~= "RightButton" then return end
            if self.isWeaponEnchant then return end
            if not self.buffIndex then return end
            if InCombatLockdown() then return end
            CancelUnitBuff("player", self.buffIndex)
        end)
    end

    f:Hide()
    return f
end

local function StyleIconFrame(frame, isDebuff)
    if not frame then return end

    local sizePx   = AuraSizePx()
    local borderPx = AuraBorderPx()
    local insetLU  = PxToLU(borderPx, frame)
    local zoom     = AuraIconZoom()

    SetSizePx(frame, sizePx, sizePx)

    frame.bg:ClearAllPoints()
    frame.bg:SetPoint("TOPLEFT",     frame, "TOPLEFT",     insetLU, -insetLU)
    frame.bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -insetLU, insetLU)
    frame.bg:SetColorTexture(UnpackRGBA(AuraBGRGBA(), 0, 0, 0, 0.35))

    frame.icon:ClearAllPoints()
    frame.icon:SetPoint("TOPLEFT",     frame, "TOPLEFT",     insetLU, -insetLU)
    frame.icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -insetLU, insetLU)
    SetTexCrop(frame.icon, zoom)

    frame.cooldown:ClearAllPoints()
    frame.cooldown:SetPoint("TOPLEFT",     frame, "TOPLEFT",     insetLU, -insetLU)
    frame.cooldown:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -insetLU, insetLU)

    local cfg = GetCfg()
    if cfg then
        local t = isDebuff and (cfg.debuffTime or {}) or (cfg.buffTime or {})
        ConfigureCooldownVisuals(frame.cooldown, false, t.font, t.size, t.flags, t.rgba)
    else
        ConfigureCooldownVisuals(frame.cooldown, false)
    end

    ApplyTextStyle(frame, isDebuff)
    ApplyBorder(frame, borderPx, AuraBorderRGBA())

    -- Shadow per icon
    if ns.Shadow then
        ns.Shadow:Apply(frame)
    end
end

local function EnsureContainers()
    if not buffContainer then
        buffContainer = CreateFrame("Frame", "NaptimeUI_BuffContainer", UIParent)
        buffContainer:SetFrameStrata("MEDIUM")
        buffContainer:SetFrameLevel(10)
        EnforcePixel(buffContainer)
    end

    if not debuffContainer then
        debuffContainer = CreateFrame("Frame", "NaptimeUI_DebuffContainer", UIParent)
        debuffContainer:SetFrameStrata("MEDIUM")
        debuffContainer:SetFrameLevel(10)
        EnforcePixel(debuffContainer)
    end

    local function LayoutContainer(container, isDebuff, rowsGuess)
        local perRow = AuraPerRow(isDebuff)
        local sizePx = AuraSizePx()
        local gapPx  = AuraGapPx()

        local widthPx  = (sizePx * perRow) + (gapPx * math.max(0, perRow - 1))
        local heightPx = (sizePx * rowsGuess) + (gapPx * math.max(0, rowsGuess - 1))
        SetSizePx(container, widthPx, heightPx)

        local a = GetAnchor(isDebuff)
        if type(a) == "table" then
            SetPointPx(container,
                a.point or "TOPLEFT",
                UIParent,
                a.relPoint or "TOPLEFT",
                tonumber(a.x) or 0,
                tonumber(a.y) or 0
            )
        else
            SetPointPx(container, "TOPRIGHT", UIParent, "TOPRIGHT", 185, isDebuff and -151 or -17)
        end
    end

    LayoutContainer(buffContainer, false, 4)
    LayoutContainer(debuffContainer, true, 2)

    for i = 1, MAX_BUFFS + MAX_WEAPON_ENCHANTS do
        if not buffFrames[i] then
            buffFrames[i] = CreateIconFrame(buffContainer, false)
        end
    end

    for i = 1, MAX_DEBUFFS do
        if not debuffFrames[i] then
            debuffFrames[i] = CreateIconFrame(debuffContainer, true)
        end
    end
end

local function ApplyStyleToAllFrames()
    if InCombatLockdown and InCombatLockdown() then
        needsStyleRefresh = true
        needsPostCombatWork = true
        return
    end

    EnsureContainers()

    for i = 1, #buffFrames do
        local f = buffFrames[i]
        if f then StyleIconFrame(f, false) end
    end

    for i = 1, #debuffFrames do
        local f = debuffFrames[i]
        if f then StyleIconFrame(f, true) end
    end

    needsStyleRefresh = false
end

local function HideAllFrames()
    for i = 1, #buffFrames do
        if buffFrames[i] then buffFrames[i]:Hide() end
    end
    for i = 1, #debuffFrames do
        if debuffFrames[i] then debuffFrames[i]:Hide() end
    end
end

local function ResetFrameState(f)
    if not f then return end
    f.auraInstanceID  = nil
    f.buffIndex       = nil
    f.isWeaponEnchant = false
    f.enchantID       = nil
    f.enchantExpiry   = nil

    f.count:SetText("")
    f.duration:SetText("")
    f.cooldown:Hide()

    UpdateBorder(f, AuraBorderPx(), AuraBorderRGBA())
end

-- ============================================================
-- Position icons — TOPLEFT anchored, simple and clean
-- ============================================================

local function PositionIcons(frames, container, isDebuff)
    if not container then return end

    local shown  = 0
    local perRow = AuraPerRow(isDebuff)
    local stepPx = AuraSizePx() + AuraGapPx()

    for i = 1, #frames do
        local f = frames[i]
        if f and f:IsShown() then
            shown = shown + 1
            local row = math.floor((shown - 1) / perRow)
            local col = (shown - 1) % perRow
            SetPointPx(f, "TOPRIGHT", container, "TOPRIGHT", -(col * stepPx), -(row * stepPx))
        end
    end
end

-- ============================================================
-- nBuff-style duration + stacks
-- ============================================================

local function ApplyAuraDurationToFrame(f, auraInstanceID)
    if not (f and auraInstanceID) then return end

    f.duration:SetText("")
    f.cooldown:Hide()

    if not (C_UnitAuras and C_UnitAuras.GetAuraDuration) then return end

    local durObj = C_UnitAuras.GetAuraDuration("player", auraInstanceID)
    if not durObj then return end

    if f.cooldown.SetCooldownFromDurationObject then
        f.cooldown:SetCooldownFromDurationObject(durObj)

        if C_UnitAuras.DoesAuraHaveExpirationTime and f.cooldown.SetAlphaFromBoolean then
            f.cooldown:SetAlphaFromBoolean(
                C_UnitAuras.DoesAuraHaveExpirationTime("player", auraInstanceID),
                1, 0
            )
        else
            f.cooldown:SetAlpha(1)
        end

        local cfg = GetCfg()
        if cfg then
            local t = f.isDebuff and (cfg.debuffTime or {}) or (cfg.buffTime or {})
            ConfigureCooldownVisuals(f.cooldown, false, t.font, t.size, t.flags, t.rgba)
        else
            ConfigureCooldownVisuals(f.cooldown, false)
        end

        f.cooldown:Show()
    end
end

local function SetStackText(f, auraInstanceID, fallbackApplications)
    if not f then return end

    local txt
    if C_UnitAuras and C_UnitAuras.GetAuraApplicationDisplayCount and auraInstanceID then
        txt = C_UnitAuras.GetAuraApplicationDisplayCount("player", auraInstanceID, 2, 999)
    end

    if not txt and type(fallbackApplications) == "number" and fallbackApplications > 1 then
        txt = tostring(fallbackApplications)
    end

    f.count:SetText(txt or "")
end

-- ============================================================
-- Weapon enchants
-- ============================================================

local function UpdateWeaponEnchantTexts()
    if activeWeaponEnchantCount <= 0 then return end

    for i = 1, activeWeaponEnchantCount do
        local f = buffFrames[i]
        if f and f:IsShown() and f.isWeaponEnchant and f.enchantExpiry then
            local rem = f.enchantExpiry - GetTime()
            if rem > 0 then
                f.duration:SetText(FormatTime(rem))
            else
                f.duration:SetText("")
                needsUpdate = true
            end
        end
    end
end

local function SetupWeaponEnchantFrames(startIndex)
    activeWeaponEnchantCount = 0

    if not ShouldShowWeaponEnchants() then return startIndex end
    if not GetWeaponEnchantInfo then return startIndex end

    local hasMain, mainExpMS, mainCharges, mainEnchantID,
          hasOff,  offExpMS,  offCharges,  offEnchantID = GetWeaponEnchantInfo()

    local idx = startIndex

    local function Setup(slotID, expMS, charges, enchantID)
        if activeWeaponEnchantCount >= MAX_WEAPON_ENCHANTS then return end

        local f = buffFrames[idx]
        if not f then return end

        ResetFrameState(f)

        local tex = GetEnchantTexture(enchantID)
            or GetInventoryItemTexture("player", slotID)
            or "Interface\\Icons\\INV_Misc_QuestionMark"
        f.icon:SetTexture(tex)

        local remSec = (tonumber(expMS) or 0) / 1000
        if remSec > 0 then
            f.cooldown:SetCooldown(GetTime(), remSec)
            ConfigureCooldownVisuals(f.cooldown, true)
            f.cooldown:Show()
            f.duration:SetText(FormatTime(remSec))
            f.enchantExpiry = GetTime() + remSec
        else
            f.cooldown:Hide()
            f.duration:SetText("")
            f.enchantExpiry = nil
        end

        if charges and charges > 0 then
            f.count:SetText(tostring(charges))
        else
            f.count:SetText("")
        end

        ApplyTextStyle(f, false)

        f.auraInstanceID  = nil
        f.buffIndex       = nil
        f.isWeaponEnchant = true
        f.enchantID       = enchantID

        UpdateBorder(f, AuraBorderPx(), { 0.6, 0.0, 1.0, 1 })
        f:Show()

        activeWeaponEnchantCount = activeWeaponEnchantCount + 1
        idx = idx + 1
    end

    if hasMain and mainEnchantID then Setup(16, mainExpMS, mainCharges, mainEnchantID) end
    if hasOff  and offEnchantID  then Setup(17, offExpMS,  offCharges,  offEnchantID)  end

    return idx
end

-- ============================================================
-- Core updates
-- ============================================================

local function UpdateBuffs()
    if not buffContainer or #buffFrames == 0 then return end

    for i = 1, MAX_BUFFS + MAX_WEAPON_ENCHANTS do
        local f = buffFrames[i]
        if f then
            f:Hide()
            f.isWeaponEnchant = false
            f.enchantExpiry   = nil
        end
    end

    local frameIndex = SetupWeaponEnchantFrames(1)

    if not (C_UnitAuras and C_UnitAuras.GetBuffDataByIndex) then
        PositionIcons(buffFrames, buffContainer, false)
        return
    end

    for buffIndex = 1, MAX_BUFFS do
        if frameIndex > (MAX_BUFFS + MAX_WEAPON_ENCHANTS) then break end

        local auraData = C_UnitAuras.GetBuffDataByIndex("player", buffIndex)
        if not auraData then break end

        local auraID   = auraData.auraInstanceID
        local auraName = CacheGetName(auraID)

        if not IsNameBlocked(auraName) then
            local f = buffFrames[frameIndex]
            if f then
                ResetFrameState(f)

                f.icon:SetTexture(auraData.icon)
                f.isWeaponEnchant = false
                f.isDebuff        = false
                ApplyAuraDurationToFrame(f, auraID)
                SetStackText(f, auraID, auraData.applications)
                ApplyTextStyle(f, false)

                f.auraInstanceID = auraID
                f.buffIndex      = buffIndex

                UpdateBorder(f, AuraBorderPx(), AuraBorderRGBA())
                f:Show()
                frameIndex = frameIndex + 1
            end
        end
    end

    PositionIcons(buffFrames, buffContainer, false)
end

local function UpdateDebuffs()
    if not debuffContainer or #debuffFrames == 0 then return end

    for i = 1, MAX_DEBUFFS do
        local f = debuffFrames[i]
        if f then
            f:Hide()
            f.isWeaponEnchant = false
        end
    end

    if not (C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex) then
        PositionIcons(debuffFrames, debuffContainer, true)
        return
    end

    local shown = 1
    for debuffIndex = 1, MAX_DEBUFFS do
        if shown > MAX_DEBUFFS then break end

        local auraData = C_UnitAuras.GetDebuffDataByIndex("player", debuffIndex)
        if not auraData then break end

        local auraID   = auraData.auraInstanceID
        local auraName = CacheGetName(auraID)

        if not IsNameBlocked(auraName) then
            local f = debuffFrames[shown]
            if f then
                ResetFrameState(f)

                f.icon:SetTexture(auraData.icon)
                f.isDebuff = true
                ApplyAuraDurationToFrame(f, auraID)
                SetStackText(f, auraID, auraData.applications)
                ApplyTextStyle(f, true)

                local dispelName
                if C_UnitAuras.GetAuraDispelName then
                    dispelName = C_UnitAuras.GetAuraDispelName("player", auraID)
                end
                local color = DEBUFF_COLORS[dispelName] or DEBUFF_COLORS.none
                UpdateBorder(f, AuraBorderPx(), color)

                f.auraInstanceID = auraID
                f:Show()
                shown = shown + 1
            end
        end
    end

    PositionIcons(debuffFrames, debuffContainer, true)
end

local function SafeRebuildAuras()
    local ok, err = pcall(function()
        UpdateBuffs()
        UpdateDebuffs()
    end)
    if not ok then
        geterrorhandler()(string.format("%s: Auras refresh error: %s", tostring(ADDON), tostring(err)))
        needsPostCombatWork = true
    end
end

local function RefreshNow_NBuffStyle()
    if not IsEnabled() then
        if buffContainer then buffContainer:Hide() end
        if debuffContainer then debuffContainer:Hide() end
        HideAllFrames()
        activeWeaponEnchantCount = 0
        return
    end

    if not buffContainer or not debuffContainer then
        if InCombatLockdown and InCombatLockdown() then
            needsPostCombatWork = true
            return
        end
        EnsureContainers()
        needsStyleRefresh = true
    end

    if InCombatLockdown and InCombatLockdown() then
        if buffContainer then buffContainer:Show() end
        if debuffContainer then debuffContainer:Show() end
        SafeRebuildAuras()
        return
    end

    if needsStyleRefresh then
        ApplyStyleToAllFrames()
    end

    HideBlizzardAuraFrames()

    if buffContainer then buffContainer:Show() end
    if debuffContainer then debuffContainer:Show() end

    SafeRebuildAuras()
end

-- ============================================================
-- Events / throttled OnUpdate
-- ============================================================

local function QueueUpdate()
    needsUpdate = true
end

local function QueueStyleUpdate()
    needsStyleRefresh = true
    needsUpdate = true
end

local function HandleUnitAuraUpdateInfo(updateInfo)
    if type(updateInfo) ~= "table" then return end

    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            if aura and aura.auraInstanceID then
                CacheSetName(aura.auraInstanceID, aura.name)
            end
        end
    end

    if updateInfo.removedAuraInstanceIDs then
        for _, id in ipairs(updateInfo.removedAuraInstanceIDs) do
            CacheClearID(id)
        end
    end
end

local function OnUnitAura(event, unit, updateInfo)
    if unit ~= "player" then return end
    HandleUnitAuraUpdateInfo(updateInfo)
    QueueUpdate()
end

local function OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.05, function()
            if not initialized then return end
            RebuildInitialAuraNameCache()
            QueueStyleUpdate()
        end)
        return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        if ShouldShowWeaponEnchants() then QueueUpdate() end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if needsPostCombatWork then
            needsPostCombatWork = false
            QueueStyleUpdate()
        end
        return
    end

    if event == "UI_SCALE_CHANGED"
        or event == "DISPLAY_SIZE_CHANGED"
        or event == "EDIT_MODE_LAYOUTS_UPDATED"
        or event == "PLAYER_SPECIALIZATION_CHANGED"
        or event == "TRAIT_CONFIG_UPDATED"
        or event == "ACTIVE_TALENT_GROUP_CHANGED"
    then
        QueueStyleUpdate()
        return
    end
end

local weaponEnchantTimer = 0
local WEAPON_ENCHANT_INTERVAL = 0.5

local function OnUpdate(_, elapsed)
    if not initialized then return end

    if activeWeaponEnchantCount > 0 then
        weaponEnchantTimer = weaponEnchantTimer + elapsed
        if weaponEnchantTimer >= WEAPON_ENCHANT_INTERVAL then
            weaponEnchantTimer = 0
            UpdateWeaponEnchantTexts()
        end
    end

    if needsUpdate then
        throttleTimer = throttleTimer + elapsed
        if throttleTimer >= THROTTLE_INTERVAL then
            throttleTimer = 0
            needsUpdate   = false
            RefreshNow_NBuffStyle()
        end
    end
end

-- ============================================================
-- Public API
-- ============================================================

function A:ApplyConfig()
    if not initialized then return end
    QueueStyleUpdate()
end

function A:Refresh()
    if not initialized then return end
    QueueUpdate()
end

function A:Enable()
    if initialized then return end
    initialized = true

    RebuildInitialAuraNameCache()

    onUpdateFrame = onUpdateFrame or CreateFrame("Frame")
    onUpdateFrame:SetScript("OnUpdate", OnUpdate)

    if ns.Events then
        local E = ns.Events

        if E.RegisterUnitEvent then
            E:RegisterUnitEvent("UNIT_AURA", "player", OnUnitAura)
        else
            E:Register("UNIT_AURA", OnUnitAura)
        end

        E:RegisterMany({
            "PLAYER_ENTERING_WORLD",
            "PLAYER_EQUIPMENT_CHANGED",
            "PLAYER_REGEN_ENABLED",
            "UI_SCALE_CHANGED",
            "DISPLAY_SIZE_CHANGED",
            "EDIT_MODE_LAYOUTS_UPDATED",
            "PLAYER_SPECIALIZATION_CHANGED",
            "TRAIT_CONFIG_UPDATED",
            "ACTIVE_TALENT_GROUP_CHANGED",
        }, OnEvent)
    else
        eventFrame = eventFrame or CreateFrame("Frame", "NaptimeUI_AurasEventFrame")
        eventFrame:RegisterEvent("UNIT_AURA")
        eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        eventFrame:RegisterEvent("UI_SCALE_CHANGED")
        eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
        eventFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
        eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
        eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
        eventFrame:SetScript("OnEvent", function(_, event, ...)
            if event == "UNIT_AURA" then
                OnUnitAura(event, ...)
            else
                OnEvent(event, ...)
            end
        end)
    end

    QueueStyleUpdate()
end

function A:Disable()
    if buffContainer then buffContainer:Hide() end
    if debuffContainer then debuffContainer:Hide() end
    HideAllFrames()
    activeWeaponEnchantCount = 0
end

function A:Init()
    self:Enable()
end

C_Timer.After(0, function()
    if A and A.Init then
        A:Init()
    end
end)
