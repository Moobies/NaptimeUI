local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.CooldownManager = ns.Modules.CooldownManager or {}
local CM = ns.Modules.CooldownManager
CM.Power = CM.Power or {}

local P = CM.Power
local WHITE = "Interface\\Buttons\\WHITE8X8"

local DEFAULT_CFG = {
    enabled = true,

    font = "Primary",
    mainSize = 16,
    mainFlags = "OUTLINE",
    subSize = 12,
    subFlags = "OUTLINE",

    showText = true,
    showComboText = true,

    showPowerCombatOnly = false,
    showComboCombatOnly = false,

    borderRGBA = {0, 0, 0, 1},
    textRGBA = {1, 1, 1, 1},

    bar = {
        width = 220,
        height = 10,
        point = {"CENTER", "CENTER"},
        x = 0,
        y = -140,
        bgRGBA = {0.08, 0.08, 0.08, 0.85},
    },

    combo = {
        enabled = true,
        width = 220,
        height = 8,
        point = {"CENTER", "CENTER"},
        x = 0,
        y = -156,
        bgRGBA = {0.08, 0.08, 0.08, 0.85},
        fillRGBA = {1.00, 0.84, 0.00, 1.00},
        extraFillRGBA = {0.20, 1.00, 0.20, 1.00},
        dividerRGBA = {0, 0, 0, 1},
        spacing = 0,
    },
}

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then
        cfg = {}
        ns.Config = cfg
    end

    if type(cfg.cooldownManager) ~= "table" then
        cfg.cooldownManager = {}
    end

    if type(cfg.cooldownManager.power) ~= "table" then
        cfg.cooldownManager.power = {}
    end

    local p = cfg.cooldownManager.power
    if type(p.bar) ~= "table" then p.bar = {} end
    if type(p.combo) ~= "table" then p.combo = {} end

    return p
end

local function ResolveFont(fontKey)
    if type(fontKey) ~= "string" or fontKey == "" then
        return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    end

    if ns.GetFont then
        local ok, path = pcall(ns.GetFont, ns, fontKey)
        if ok and type(path) == "string" and path ~= "" then
            return path
        end
    end

    return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

local function SafeSetFont(fs, fontKey, size, flags)
    if not (fs and fs.SetFont) then return end
    pcall(fs.SetFont, fs, ResolveFont(fontKey), tonumber(size) or 16, flags or "")
end

local function PixelPerfect(value)
    value = tonumber(value) or 0

    if ns.Pixel then
        if type(ns.Pixel) == "table" then
            if type(ns.Pixel.Size) == "function" then
                local ok, out = pcall(ns.Pixel.Size, ns.Pixel, value)
                if ok and type(out) == "number" then
                    return out
                end
            end

            if type(ns.Pixel.Get) == "function" then
                local ok, out = pcall(ns.Pixel.Get, ns.Pixel, value)
                if ok and type(out) == "number" then
                    return out
                end
            end
        elseif type(ns.Pixel) == "function" then
            local ok, out = pcall(ns.Pixel, value)
            if ok and type(out) == "number" then
                return out
            end
        end
    end

    local _, screenHeight = GetPhysicalScreenSize()
    local uiScale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    local pixelSize = 768 / screenHeight / uiScale
    return pixelSize * math.floor(value / pixelSize + 0.5333)
end

local function GetPowerColor(powerType)
    if PowerBarColor and PowerBarColor[powerType] then
        local c = PowerBarColor[powerType]
        return c.r or 1, c.g or 1, c.b or 1
    end

    if powerType == 0 then return 0.00, 0.55, 1.00 end
    if powerType == 1 then return 1.00, 0.00, 0.00 end
    if powerType == 3 then return 1.00, 1.00, 0.00 end
    if powerType == 8 then return 0.80, 0.30, 0.85 end
    return 1, 1, 1
end

local function GetMainPower()
    local powerType, powerToken = UnitPowerType("player")
    local cur = UnitPower("player", powerType)
    local max = UnitPowerMax("player", powerType)
    return powerType or 0, powerToken, cur or 0, max or 0
end

local function GetComboPoints()
    local comboType = (Enum and Enum.PowerType and Enum.PowerType.ComboPoints) or 4
    return UnitPower("player", comboType) or 0, UnitPowerMax("player", comboType) or 0
end

local function ShouldShowComboPoints(powerType)
    local ENERGY = (Enum and Enum.PowerType and Enum.PowerType.Energy) or 3
    return powerType == ENERGY
end

local function ShouldShowPowerFrame(cfg)
    if type(cfg) ~= "table" then return true end
    if cfg.showPowerCombatOnly then
        return InCombat()
    end
    return true
end

local function ShouldShowComboFrame(cfg)
    if type(cfg) ~= "table" then return true end
    if cfg.showComboCombatOnly then
        return InCombat()
    end
    return true
end

local function IsRogue()
    local _, class = UnitClass("player")
    return class == "ROGUE"
end

local function EnsureBorder(frame)
    if frame.__powerBorder then return end

    local border = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
    border:SetAllPoints(frame)
    border:SetFrameLevel((frame:GetFrameLevel() or 0) + 5)

    if border.SetBackdrop then
        border:SetBackdrop({
            bgFile = WHITE,
            edgeFile = WHITE,
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
    end

    frame.__powerBorder = border
end

local function SetBorderColor(frame, rgba)
    if frame and frame.__powerBorder and frame.__powerBorder.SetBackdropBorderColor then
        frame.__powerBorder:SetBackdropColor(0, 0, 0, 0)
        frame.__powerBorder:SetBackdropBorderColor(
            rgba[1] or 0,
            rgba[2] or 0,
            rgba[3] or 0,
            rgba[4] or 1
        )
    end
end

local function EnsurePowerFrame(self)
    if self.powerFrame then return self.powerFrame end

    local f = CreateFrame("Frame", ADDON .. "CooldownManagerPowerBarFrame", UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(20)

    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetStatusBarTexture(WHITE)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    bar:SetAllPoints(f)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetAllPoints(bar)
    bar.BG = bg

    local textHolder = CreateFrame("Frame", nil, f)
    textHolder:SetAllPoints(f)
    textHolder:SetFrameStrata(f:GetFrameStrata())
    textHolder:SetFrameLevel((f:GetFrameLevel() or 20) + 10)
    f.TextHolder = textHolder

    local text = textHolder:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", f, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetDrawLayer("OVERLAY", 7)

    f.Bar = bar
    f.Text = text

    EnsureBorder(f)

    self.powerFrame = f
    return f
end

local function EnsureComboFrame(self)
    if self.comboFrame then return self.comboFrame end

    local f = CreateFrame("Frame", ADDON .. "CooldownManagerComboBarFrame", UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(20)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetAllPoints(f)
    f.BG = bg

    local textHolder = CreateFrame("Frame", nil, f)
    textHolder:SetAllPoints(f)
    textHolder:SetFrameStrata(f:GetFrameStrata())
    textHolder:SetFrameLevel((f:GetFrameLevel() or 20) + 10)
    f.TextHolder = textHolder

    local text = textHolder:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", f, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetDrawLayer("OVERLAY", 7)
    f.Text = text

    EnsureBorder(f)

    f.__fills = {}
    f.__dividers = {}

    self.comboFrame = f
    return f
end

local function ApplyPowerStyle(self)
    local cfg = GetCfg()
    local f = EnsurePowerFrame(self)

    local barCfg = cfg.bar or DEFAULT_CFG.bar
    local width = tonumber(barCfg.width) or DEFAULT_CFG.bar.width
    local height = tonumber(barCfg.height) or DEFAULT_CFG.bar.height

    f:ClearAllPoints()
    f:SetSize(width, height)
    f:SetPoint(
        (barCfg.point and barCfg.point[1]) or DEFAULT_CFG.bar.point[1],
        UIParent,
        (barCfg.point and barCfg.point[2]) or DEFAULT_CFG.bar.point[2],
        tonumber(barCfg.x) or DEFAULT_CFG.bar.x,
        tonumber(barCfg.y) or DEFAULT_CFG.bar.y
    )

    SafeSetFont(
        f.Text,
        cfg.font or DEFAULT_CFG.font,
        cfg.mainSize or DEFAULT_CFG.mainSize,
        cfg.mainFlags or DEFAULT_CFG.mainFlags
    )

    if f.Text.SetShadowOffset then
        f.Text:SetShadowOffset(0, 0)
    end

    local bgc = barCfg.bgRGBA or DEFAULT_CFG.bar.bgRGBA
    f.Bar.BG:SetVertexColor(bgc[1] or 0, bgc[2] or 0, bgc[3] or 0, bgc[4] or 1)

    local bc = cfg.borderRGBA or DEFAULT_CFG.borderRGBA
    SetBorderColor(f, bc)
end

local function ApplyComboStyle(self)
    local cfg = GetCfg()
    local f = EnsureComboFrame(self)

    local comboCfg = cfg.combo or DEFAULT_CFG.combo
    local width = tonumber(comboCfg.width) or DEFAULT_CFG.combo.width
    local height = tonumber(comboCfg.height) or DEFAULT_CFG.combo.height

    f:ClearAllPoints()
    f:SetSize(width, height)
    f:SetPoint(
        (comboCfg.point and comboCfg.point[1]) or DEFAULT_CFG.combo.point[1],
        UIParent,
        (comboCfg.point and comboCfg.point[2]) or DEFAULT_CFG.combo.point[2],
        tonumber(comboCfg.x) or DEFAULT_CFG.combo.x,
        tonumber(comboCfg.y) or DEFAULT_CFG.combo.y
    )

    SafeSetFont(
        f.Text,
        cfg.font or DEFAULT_CFG.font,
        cfg.subSize or DEFAULT_CFG.subSize,
        cfg.subFlags or DEFAULT_CFG.subFlags
    )

    if f.Text.SetShadowOffset then
        f.Text:SetShadowOffset(0, 0)
    end

    local bgc = comboCfg.bgRGBA or DEFAULT_CFG.combo.bgRGBA
    f.BG:SetVertexColor(bgc[1] or 0, bgc[2] or 0, bgc[3] or 0, bgc[4] or 1)

    local bc = cfg.borderRGBA or DEFAULT_CFG.borderRGBA
    SetBorderColor(f, bc)
end

local function LayoutComboSegments(self, maxPoints)
    local cfg = GetCfg()
    local f = EnsureComboFrame(self)
    local comboCfg = cfg.combo or DEFAULT_CFG.combo

    local width = tonumber(comboCfg.width) or DEFAULT_CFG.combo.width
    local height = tonumber(comboCfg.height) or DEFAULT_CFG.combo.height
    local spacing = tonumber(comboCfg.spacing) or DEFAULT_CFG.combo.spacing

    local fillRGBA = comboCfg.fillRGBA or DEFAULT_CFG.combo.fillRGBA
    local extraFillRGBA = comboCfg.extraFillRGBA or DEFAULT_CFG.combo.extraFillRGBA
    local dividerRGBA = comboCfg.dividerRGBA or DEFAULT_CFG.combo.dividerRGBA

    local rogue = IsRogue()

    if not maxPoints or maxPoints <= 0 then
        for i = 1, #f.__fills do
            f.__fills[i]:Hide()
        end
        for i = 1, #f.__dividers do
            f.__dividers[i]:Hide()
        end
        return
    end

    local inset = PixelPerfect(1)
    local innerWidth = width - (inset * 2)
    local totalSpacing = spacing * (maxPoints - 1)
    local segmentWidth = (innerWidth - totalSpacing) / maxPoints
    local dividerWidth = math.max(1, PixelPerfect(1))

    for i = 1, maxPoints do
        local seg = f.__fills[i]
        if not seg then
            seg = f:CreateTexture(nil, "ARTWORK")
            f.__fills[i] = seg
        end

        local left = inset + ((i - 1) * (segmentWidth + spacing))
        local right = left + segmentWidth

        seg:ClearAllPoints()
        seg:SetPoint("TOPLEFT", f, "TOPLEFT", PixelPerfect(left), -inset)
        seg:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", PixelPerfect(right), inset)
        seg:SetTexture(WHITE)

        local c = fillRGBA
        if rogue and i > 4 then
            c = extraFillRGBA
        end

        seg:SetVertexColor(
            c[1] or 1,
            c[2] or 1,
            c[3] or 1,
            c[4] or 1
        )
        seg:Show()
    end

    for i = maxPoints + 1, #f.__fills do
        f.__fills[i]:Hide()
    end

    local dividerCount = maxPoints - 1
    for i = 1, dividerCount do
        local div = f.__dividers[i]
        if not div then
            div = f:CreateTexture(nil, "OVERLAY")
            f.__dividers[i] = div
        end

        local x = inset + ((segmentWidth + spacing) * i) - (spacing * 0.5)

        div:ClearAllPoints()
        div:SetPoint("TOP", f, "TOPLEFT", PixelPerfect(x), -inset)
        div:SetPoint("BOTTOM", f, "BOTTOMLEFT", PixelPerfect(x), inset)
        div:SetWidth(dividerWidth)
        div:SetColorTexture(
            dividerRGBA[1] or 0,
            dividerRGBA[2] or 0,
            dividerRGBA[3] or 0,
            dividerRGBA[4] or 1
        )
        div:Show()
    end

    for i = dividerCount + 1, #f.__dividers do
        f.__dividers[i]:Hide()
    end
end

local function UpdateComboSegments(self, curPoints, maxPoints)
    local f = EnsureComboFrame(self)
    if not f.__fills then return end

    for i = 1, maxPoints do
        local seg = f.__fills[i]
        if seg then
            seg:SetShown(i <= (curPoints or 0))
        end
    end
end

local function UpdatePowerBar(self)
    local cfg = GetCfg()
    local f = EnsurePowerFrame(self)
    ApplyPowerStyle(self)

    if cfg.enabled == false or not ShouldShowPowerFrame(cfg) then
        f:Hide()
        return
    end

    local powerType, _, cur, max = GetMainPower()
    if not max or max <= 0 then
        f:Hide()
        return
    end

    local r, g, b = GetPowerColor(powerType)
    f.Bar:SetMinMaxValues(0, max)
    f.Bar:SetValue(cur)
    f.Bar:SetStatusBarColor(r, g, b, 1)

    if cfg.showText ~= false then
        local tc = cfg.textRGBA or DEFAULT_CFG.textRGBA
        f.Text:SetText(tostring(cur))
        f.Text:SetTextColor(tc[1] or 1, tc[2] or 1, tc[3] or 1, tc[4] or 1)
        f.Text:Show()
    else
        f.Text:SetText("")
        f.Text:Hide()
    end

    f:Show()
end

local function UpdateComboBar(self)
    local cfg = GetCfg()
    local f = EnsureComboFrame(self)
    ApplyComboStyle(self)

    if cfg.enabled == false or not ShouldShowComboFrame(cfg) then
        f:Hide()
        return
    end

    local powerType = UnitPowerType("player")
    local comboCfg = cfg.combo or DEFAULT_CFG.combo

    if comboCfg.enabled == false or not ShouldShowComboPoints(powerType) then
        f:Hide()
        return
    end

    local cpCur, cpMax = GetComboPoints()
    if not cpMax or cpMax <= 0 then
        f:Hide()
        return
    end

    LayoutComboSegments(self, cpMax)
    UpdateComboSegments(self, cpCur, cpMax)

    if cfg.showComboText ~= false then
        local tc = cfg.textRGBA or DEFAULT_CFG.textRGBA
        f.Text:SetText(tostring(cpCur or 0))
        f.Text:SetTextColor(tc[1] or 1, tc[2] or 1, tc[3] or 1, tc[4] or 1)
        f.Text:Show()
    else
        f.Text:SetText("")
        f.Text:Hide()
    end

    f:Show()
end

local function UpdateAll(self)
    UpdatePowerBar(self)
    UpdateComboBar(self)
end

function P:Enable()
    if self.__enabled then return end
    self.__enabled = true

    EnsurePowerFrame(self)
    EnsureComboFrame(self)
    ApplyPowerStyle(self)
    ApplyComboStyle(self)

    local ev = CreateFrame("Frame")
    self.eventFrame = ev

    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    ev:RegisterEvent("UNIT_DISPLAYPOWER")
    ev:RegisterEvent("UNIT_POWER_UPDATE")
    ev:RegisterEvent("UNIT_MAXPOWER")
    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    ev:RegisterEvent("PLAYER_REGEN_DISABLED")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")

    ev:SetScript("OnEvent", function(_, _, unit)
        if unit and unit ~= "player" then return end
        UpdateAll(self)
    end)

    C_Timer.After(0, function()
        if self and self.__enabled then
            UpdateAll(self)
        end
    end)
end

function P:Disable()
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        self.eventFrame:SetScript("OnEvent", nil)
    end

    if self.powerFrame then
        self.powerFrame:Hide()
    end

    if self.comboFrame then
        self.comboFrame:Hide()
    end

    self.__enabled = nil
end
