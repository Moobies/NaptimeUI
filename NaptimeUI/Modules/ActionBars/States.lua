-- Modules/ActionBars/States.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.ActionBarStates = ns.Modules.ActionBarStates or {}
local S = ns.Modules.ActionBarStates

local BUTTON_PREFIXES = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
    "PetActionButton",
    "StanceButton",
}

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return nil end
    if type(cfg.actionbars) ~= "table" then return nil end
    return cfg.actionbars
end

local function GetIcon(btn)
    if not btn then return nil end
    return btn.icon
        or btn.Icon
        or btn.IconTexture
        or (btn.GetName and _G[btn:GetName() .. "Icon"])
end

local function SetDesatOff(icon)
    if not icon then return end
    if icon.SetDesaturated then pcall(icon.SetDesaturated, icon, false) end
    if icon.SetDesaturation then pcall(icon.SetDesaturation, icon, 0) end
end

local function GetMaxForPrefix(prefix)
    if prefix == "PetActionButton" then
        return _G.NUM_PET_ACTION_SLOTS or 10
    elseif prefix == "StanceButton" then
        return _G.NUM_STANCE_SLOTS or 10
    end
    return 12
end

local function ForEachActionButton(fn)
    if type(fn) ~= "function" then return end
    for _, prefix in ipairs(BUTTON_PREFIXES) do
        local max = GetMaxForPrefix(prefix)
        for i = 1, max do
            local btn = _G[prefix .. i]
            if btn then
                fn(btn, prefix, i)
            end
        end
    end
end

-- -------------------------
-- EQUIPPED helper
-- -------------------------
local function IsEquipped(btn)
    if not btn or type(btn.action) ~= "number" then return false end
    if type(_G.IsEquippedAction) ~= "function" then return false end
    return _G.IsEquippedAction(btn.action) == true
end

-- -------------------------
-- BORDER helpers (base border via ns.Border)
-- -------------------------
local function SetBorder(btn, rgba)
    if not btn then return end
    local ab = GetCfg()
    if not ab then return end
    if not (ns.Border and ns.Border.Update) then return end
    if not btn.__nolBorder then return end

    local px = tonumber(ab.borderPx) or 1
    ns.Border:Update(btn, px, rgba)
end

local function RestoreBorder(btn)
    if not btn then return end
    local ab = GetCfg()
    if not ab then return end

    local normal = ab.borderRGBA or { 0, 0, 0, 1 }
    local equip  = ab.equippedRGBA or { 0.2, 1, 0.2, 1 }

    if IsEquipped(btn) then
        SetBorder(btn, equip)
    else
        SetBorder(btn, normal)
    end
end

-- -------------------------
-- Interrupt border overlay (red fades over existing border)
-- -------------------------
local function GetFadeOverlay(btn)
    if btn.__nolInterruptOverlay then return btn.__nolInterruptOverlay end

    local ov = CreateFrame("Frame", nil, btn)
    ov:SetAllPoints(btn)
    ov:EnableMouse(false)
    ov:SetFrameStrata(btn:GetFrameStrata())
    ov:SetFrameLevel(btn:GetFrameLevel() + 50)

    local function edge()
        local t = ov:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        return t
    end

    ov.t = edge()
    ov.b = edge()
    ov.l = edge()
    ov.r = edge()

    ov:Hide()
    btn.__nolInterruptOverlay = ov
    return ov
end

local function SetFadeOverlayColor(btn, r, g, b, a)
    if not btn then return end
    local ov = GetFadeOverlay(btn)

    local ab = GetCfg()
    ab = ab or {}
    local px = tonumber(ab.borderPx) or 1

    ov.t:ClearAllPoints()
    ov.t:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    ov.t:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    ov.t:SetHeight(px)

    ov.b:ClearAllPoints()
    ov.b:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    ov.b:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    ov.b:SetHeight(px)

    ov.l:ClearAllPoints()
    ov.l:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    ov.l:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    ov.l:SetWidth(px)

    ov.r:ClearAllPoints()
    ov.r:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    ov.r:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    ov.r:SetWidth(px)

    ov.t:SetVertexColor(r, g, b, a)
    ov.b:SetVertexColor(r, g, b, a)
    ov.l:SetVertexColor(r, g, b, a)
    ov.r:SetVertexColor(r, g, b, a)

    ov:Show()
end

local function HideFadeOverlay(btn)
    local ov = btn and btn.__nolInterruptOverlay
    if ov then ov:Hide() end
end

-- -------------------------
-- Interrupt border fade (smooth over N seconds)
-- -------------------------
local activeFadeButtons = setmetatable({}, { __mode = "k" })
local fadeTicker

local function StartInterruptBorderFade(btn)
    if not btn then return end
    btn.__nolInterruptFadeStart = GetTime()
    activeFadeButtons[btn] = true
end

local function UpdateInterruptBorderFade(btn)
    local t0 = btn and btn.__nolInterruptFadeStart
    if not t0 then return false end

    local ab = GetCfg()
    ab = ab or {}

    local dur = tonumber(ab.cancelBorderFadeSecs) or 1.0
    if dur <= 0 then dur = 1.0 end

    local t = (GetTime() - t0) / dur
    if t >= 1 then
        btn.__nolInterruptFadeStart = nil
        activeFadeButtons[btn] = nil
        HideFadeOverlay(btn)
        return false
    end

    local base = ab.cancelBorderRGBA or { 1, 0.2, 0.2, 1 }
    local a0 = base[4]
    if a0 == nil then a0 = 1 end

    local a = a0 * (1 - t)
    SetFadeOverlayColor(btn, base[1] or 1, base[2] or 0.2, base[3] or 0.2, a)
    return true
end

local function EnsureFadeTicker()
    if fadeTicker then return end
    fadeTicker = CreateFrame("Frame")
    fadeTicker:Hide()

    fadeTicker:SetScript("OnUpdate", function(self)
        local any = false

        for btn in pairs(activeFadeButtons) do
            if btn and btn.__nolInterruptFadeStart then
                if UpdateInterruptBorderFade(btn) then
                    any = true
                end
            else
                activeFadeButtons[btn] = nil
            end
        end

        if not any then
            self:Hide()
        end
    end)
end

local function StartFadeTicker()
    EnsureFadeTicker()
    if fadeTicker and not fadeTicker:IsShown() then
        fadeTicker:Show()
    end
end

-- -------------------------
-- RANGE (red tint on icon)
-- -------------------------
local function UpdateRange(btn)
    if not btn or type(btn.action) ~= "number" then return end
    local icon = GetIcon(btn)
    if not icon then return end

    local ab = GetCfg()
    if not ab then return end

    local inRange = IsActionInRange(btn.action)

    if inRange == false then
        SetDesatOff(icon)
        local c = ab.rangeRGBA or { 1, 0.2, 0.2, 1 }
        icon:SetVertexColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
        return true
    end

    return false
end

-- -------------------------
-- USABLE (power/state/etc)
-- -------------------------
local function UpdateUsable(btn)
    if not btn or type(btn.action) ~= "number" then return end
    local icon = GetIcon(btn)
    if not icon then return end

    local ab = GetCfg()
    ab = ab or {}

    local usable, notEnoughPower = IsUsableAction(btn.action)

    local function SetColor(r, g, b, a)
        SetDesatOff(icon)
        icon:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
    end

    if not usable and not notEnoughPower then
        local c = ab.unusableRGBA or { 0.55, 0.55, 0.55, 1 }
        SetColor(c[1], c[2], c[3], c[4])
        return
    end

    if not usable and notEnoughPower then
        local c = ab.noPowerRGBA or { 0.55, 0.55, 0.55, 1 }
        SetColor(c[1], c[2], c[3], c[4])
        return
    end

    SetColor(1, 1, 1, 1)
end

-- -------------------------
-- HARD HIDE HELPERS
-- -------------------------
local function KillAndKeepHidden(obj)
    if not obj or obj.__nolKeepHidden then return end
    obj.__nolKeepHidden = true

    local function forceHide(self)
        if self.Hide then pcall(self.Hide, self) end
        if self.SetAlpha then pcall(self.SetAlpha, self, 0) end
        if self.SetShown then pcall(self.SetShown, self, false) end
    end

    forceHide(obj)

    if obj.HookScript then
        pcall(obj.HookScript, obj, "OnShow", forceHide)
    end
    if obj.Show then
        pcall(hooksecurefunc, obj, "Show", forceHide)
    end
    if obj.SetShown then
        pcall(hooksecurefunc, obj, "SetShown", function(self, shown)
            if shown then forceHide(self) end
        end)
    end
end

-- -------------------------
-- CASTBAR SHINE (cancel/finish cast) -> hide
-- -------------------------
local function KillCastbarShine()
    local bar = _G.PlayerCastingBarFrame
    if not bar then return end
    local shine = bar.Shine
    if shine then
        KillAndKeepHidden(shine)
    end
end

-- -------------------------
-- InterruptDisplay -> start border fade
-- -------------------------
local function ReplaceInterruptDisplayWithBorder(btn)
    if not btn or btn.__nolInterruptHooked then return end
    btn.__nolInterruptHooked = true

    local id = btn.InterruptDisplay or (btn.GetName and _G[btn:GetName() .. "InterruptDisplay"])
    if not id then return end

    local function suppress(self)
        if self.SetAlpha then pcall(self.SetAlpha, self, 0) end
        if self.SetScale then pcall(self.SetScale, self, 0.0001) end
    end

    if id.HookScript then
        id:HookScript("OnShow", function(self)
            suppress(self)
            StartInterruptBorderFade(btn)
            StartFadeTicker()
        end)
        id:HookScript("OnHide", function(self)
            suppress(self)
        end)
    end

    if id.Show then
        hooksecurefunc(id, "Show", function(self)
            suppress(self)
        end)
    end

    suppress(id)
end

-- -------------------------
-- NEW SPELL / AUTOPLACED glow (gold/white) -> hide
-- -------------------------
local function KillNewSpellGlow(btn)
    if not btn or btn.__nolNewGlowKilled then return end
    btn.__nolNewGlowKilled = true

    KillAndKeepHidden(btn.NewActionTexture or btn.newActionTexture)
    KillAndKeepHidden(btn.SpellActivationAlert or btn.spellActivationAlert)
    KillAndKeepHidden(btn.SpellHighlightTexture or (btn.GetName and _G[btn:GetName() .. "SpellHighlightTexture"]))
end

-- -------------------------
-- CASTING VISUALS (optional disable)
-- -------------------------
local function GetSpellCastOverlayObject(btn)
    return btn.SpellCastOverlay
        or btn.spellCastOverlay
        or (btn.GetName and _G[btn:GetName() .. "SpellCastOverlay"])
end

local function GetSpellCastAnimFrame(btn)
    return btn.SpellCastAnimFrame
        or btn.spellCastAnimFrame
        or (btn.GetName and _G[btn:GetName() .. "SpellCastAnimFrame"])
end

local function KillCastingVisuals(btn)
    if not btn then return end

    local o = GetSpellCastOverlayObject(btn)
    if o then KillAndKeepHidden(o) end

    local hl = btn.SpellHighlightTexture
        or (btn.GetName and _G[btn:GetName() .. "SpellHighlightTexture"])
    if hl then KillAndKeepHidden(hl) end

    local flash = btn.Flash
        or (btn.GetName and _G[btn:GetName() .. "Flash"])
    if flash then KillAndKeepHidden(flash) end

    local f = GetSpellCastAnimFrame(btn)
    if f then
        KillAndKeepHidden(f)

        if f.Fill then
            KillAndKeepHidden(f.Fill)

            if f.Fill.InnerGlowTexture then
                KillAndKeepHidden(f.Fill.InnerGlowTexture)
            end

            if f.Fill.FillMask then
                KillAndKeepHidden(f.Fill.FillMask)
            end
            if f.Fill.FillMaskTexture then
                KillAndKeepHidden(f.Fill.FillMaskTexture)
            end
        end
    end
end

-- -------------------------
-- EQUIPPED (green pixel border)
-- -------------------------
local function UpdateEquippedBorder(btn)
    if not btn then return end

    local ab = GetCfg()
    if not ab then return end

    if not btn.__nolBorder then return end
    if not (ns.Border and ns.Border.Update) then return end

    local px     = tonumber(ab.borderPx) or 1
    local normal = ab.borderRGBA or { 0, 0, 0, 1 }
    local equip  = ab.equippedRGBA or { 0.2, 1, 0.2, 1 }

    if IsEquipped(btn) then
        ns.Border:Update(btn, px, equip)
    else
        ns.Border:Update(btn, px, normal)
    end
end

local function RefreshButton(btn)
    if not btn then return end

    local outOfRange = UpdateRange(btn)
    if not outOfRange then
        UpdateUsable(btn)
    end

    UpdateEquippedBorder(btn)

    ReplaceInterruptDisplayWithBorder(btn)
    UpdateInterruptBorderFade(btn)

    KillNewSpellGlow(btn)

    local _, ab = GetCfg()
    if not ab or ab.disableCastOverlay ~= false then
        KillCastingVisuals(btn)
    end
end

local function RefreshAllButtons()
    KillCastbarShine()
    ForEachActionButton(RefreshButton)
end

local refreshQueued = false
local function QueueRefreshAll()
    if refreshQueued then return end
    refreshQueued = true

    local function run()
        refreshQueued = false
        RefreshAllButtons()
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0, run)
    else
        run()
    end
end

function S:Enable()
    if self.__enabled then return end
    self.__enabled = true

    if type(ActionButton_UpdateRangeIndicator) == "function" then
        hooksecurefunc("ActionButton_UpdateRangeIndicator", function(btn)
            RefreshButton(btn)
        end)
    end

    if type(ActionButton_UpdateUsable) == "function" then
        hooksecurefunc("ActionButton_UpdateUsable", function(btn)
            RefreshButton(btn)
        end)
    end

    if type(ActionButton_UpdateSpellCastOverlay) == "function" then
        hooksecurefunc("ActionButton_UpdateSpellCastOverlay", function(btn)
            local _, ab = GetCfg()
            if ab and ab.disableCastOverlay == false then return end
            KillCastingVisuals(btn)
        end)
    end

    if type(ActionButton_UpdateSpellHighlight) == "function" then
        hooksecurefunc("ActionButton_UpdateSpellHighlight", function(btn)
            local _, ab = GetCfg()
            if ab and ab.disableCastOverlay == false then return end
            KillCastingVisuals(btn)
        end)
    end

    local function HandleEvent(event, unit)
        if event == "UNIT_POWER_UPDATE" and unit and unit ~= "player" then
            return
        end
        QueueRefreshAll()
    end

    if ns.Events then
        local E = ns.Events
        E:RegisterMany({
            "PLAYER_LOGIN",
            "PLAYER_ENTERING_WORLD",
            "ACTIONBAR_SLOT_CHANGED",
            "ACTIONBAR_UPDATE_STATE",
            "ACTIONBAR_UPDATE_USABLE",
            "PLAYER_TARGET_CHANGED",
            "UPDATE_SHAPESHIFT_FORM",
            "PLAYER_EQUIPMENT_CHANGED",
            "BAG_UPDATE_DELAYED",
        }, HandleEvent, { throttle = true })

        if E.RegisterUnitEvent then
            E:RegisterUnitEvent("UNIT_POWER_UPDATE", "player", HandleEvent, { throttle = true })
        else
            E:Register("UNIT_POWER_UPDATE", HandleEvent, { throttle = true })
        end
    else
        local f = CreateFrame("Frame")
        self.__driver = f
        f:RegisterEvent("PLAYER_LOGIN")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
        f:RegisterEvent("ACTIONBAR_UPDATE_STATE")
        f:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
        f:RegisterEvent("UNIT_POWER_UPDATE")
        f:RegisterEvent("PLAYER_TARGET_CHANGED")
        f:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
        f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        f:RegisterEvent("BAG_UPDATE_DELAYED")

        f:SetScript("OnEvent", HandleEvent)
    end

    QueueRefreshAll()
end
