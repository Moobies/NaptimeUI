-- Modules/ActionBars/ActionBars.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.ActionBars = ns.Modules.ActionBars or {}
local AB = ns.Modules.ActionBars
AB.Layout = AB.Layout or {}
AB.Fade   = AB.Fade or {}
local L = AB.Layout
local F = AB.Fade

local Pixel  = ns.Pixel
local Border = ns.Border
local Fade   = ns.Fade

local WHITE = "Interface\\Buttons\\WHITE8X8"

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return nil end
    if type(cfg.actionbars) ~= "table" then return nil end
    return cfg.actionbars
end

-- -------------------------------------------------------
-- Containers
-- -------------------------------------------------------
local function EnsureContainer(name, secure)
    local f = _G[name]
    if f then return f end

    if secure then
        f = CreateFrame("Frame", name, UIParent, "SecureHandlerStateTemplate")
    else
        f = CreateFrame("Frame", name, UIParent)
    end

    f:SetClampedToScreen(true)
    f:EnableMouse(false)
    _G[name] = f

    if Pixel and Pixel.Enforce then
        Pixel:Enforce(f)
    end

    return f
end

local function ResolveRelFrame(anchor)
    if type(anchor) ~= "table" then return UIParent end
    if anchor.relTo then
        return _G[anchor.relTo] or UIParent
    end
    return UIParent
end

-- -------------------------------------------------------
-- Blizzard bar suppression
--
-- __nolBarHooked: set once when hook is installed, never cleared
-- __nolBarKilled: set when suppressing, cleared when releasing
-- The hook checks __nolBarKilled before acting so toggling
-- just flips the flag — no rehooking or relog needed.
-- -------------------------------------------------------
local function KillBlizzardBar(prefix)
    local blizzFrame = _G[prefix:gsub("Button", "")]
    if not blizzFrame then return end

    if RegisterStateDriver then
        RegisterStateDriver(blizzFrame, "visibility", "hide")
    end

    if not blizzFrame.__nolBarHooked then
        blizzFrame.__nolBarHooked = true
        hooksecurefunc(blizzFrame, "Show", function(self)
            if self.__nolBarKilled then
                self:Hide()
            end
        end)
    end

    blizzFrame.__nolBarKilled = true
end

local function UnkillBlizzardBar(prefix)
    local blizzFrame = _G[prefix:gsub("Button", "")]
    if not blizzFrame then return end

    blizzFrame.__nolBarKilled = nil

    if UnregisterStateDriver then
        UnregisterStateDriver(blizzFrame, "visibility")
    end
end

-- -------------------------------------------------------
-- Button region helpers
-- -------------------------------------------------------
local function GetIcon(btn)
    return btn and (btn.icon or btn.Icon or btn.IconTexture)
end

local function GetHotkeyFS(btn)
    if not btn then return nil end
    return btn.HotKey
        or btn.HotKeyText
        or btn.hotkey
        or (btn.GetName and _G[btn:GetName() .. "HotKey"])
end

local function GetMacroFS(btn)
    if not btn then return nil end
    return btn.Name
        or btn.NameText
        or btn.name
        or (btn.GetName and _G[btn:GetName() .. "Name"])
end

local function GetChargeFS(btn)
    if not btn then return nil end
    return btn.Count
        or btn.CountText
        or btn.count
        or (btn.GetName and _G[btn:GetName() .. "Count"])
end

local function ApplyIconZoom(btn, zoom)
    local icon = GetIcon(btn)
    if not (icon and icon.SetTexCoord) then return end

    local z = tonumber(zoom) or 0.10
    if z < 0 then z = 0 end
    if z > 0.35 then z = 0.35 end

    icon:SetTexCoord(z, 1 - z, z, 1 - z)
end

local function IsFlyoutButton(btn)
    if not btn then return false end

    if btn.FlyoutArrow
        or btn.flyoutArrow
        or btn.FlyoutBorder
        or btn.SpellFlyout
        or btn.spellFlyout
        or (btn.GetAttribute and btn:GetAttribute("flyoutDirection"))
    then
        return true
    end

    if type(btn.action) == "number" and type(GetActionInfo) == "function" then
        local actionType = GetActionInfo(btn.action)
        if actionType == "flyout" then
            return true
        end
    end

    return false
end

local function StripFlyoutTriggerArt(btn)
    if not btn then return end

    local function HideAndKill(obj)
        if not obj then return end

        if obj.Hide then obj:Hide() end
        if obj.SetAlpha then obj:SetAlpha(0) end

        if obj.__nolFlyoutTriggerKilled then return end
        obj.__nolFlyoutTriggerKilled = true

        if obj.HookScript then
            pcall(obj.HookScript, obj, "OnShow", function(self)
                if self.Hide then self:Hide() end
                if self.SetAlpha then self:SetAlpha(0) end
            end)
        end

        if obj.Show then
            pcall(hooksecurefunc, obj, "Show", function(self)
                if self.Hide then self:Hide() end
                if self.SetAlpha then self:SetAlpha(0) end
            end)
        end
    end

    local name = btn.GetName and btn:GetName()
    if name then
        local keys = {
            name .. "NormalTexture",
            name .. "BorderShadow",
            name .. "SlotBackground",
            name .. "HighlightTexture",
            name .. "PushedTexture",
            name .. "CheckedTexture",
        }

        for _, key in ipairs(keys) do
            HideAndKill(_G[key])
        end
    end

    if btn.GetNormalTexture then
        local t = btn:GetNormalTexture()
        HideAndKill(t)
        pcall(btn.SetNormalTexture, btn, nil)
    end

    if btn.GetHighlightTexture then
        local t = btn:GetHighlightTexture()
        HideAndKill(t)
        pcall(btn.SetHighlightTexture, btn, nil)
    end

    if btn.GetPushedTexture then
        local t = btn:GetPushedTexture()
        HideAndKill(t)
        pcall(btn.SetPushedTexture, btn, nil)
    end

    if btn.GetCheckedTexture then
        local t = btn:GetCheckedTexture()
        HideAndKill(t)
        pcall(btn.SetCheckedTexture, btn, nil)
    end
end

-- -------------------------------------------------------
-- Fonts / Text
-- -------------------------------------------------------
local function ApplyFont(fs, cfg, which)
    if not (fs and fs.SetFont) then return end
    if type(cfg) ~= "table" then return end
    if type(which) ~= "string" then return end

    local fontKeyOrPath = cfg[which .. "Font"] or "Default"
    local fontPath = ns.GetFont and ns:GetFont(fontKeyOrPath) or "Fonts\\FRIZQT__.TTF"

    local size  = tonumber(cfg[which .. "Size"]) or 10
    local flags = cfg[which .. "Flags"] or "OUTLINE"

    local ok, ret = pcall(fs.SetFont, fs, fontPath, size, flags)
    if (not ok) or (ret == false) then
        pcall(fs.SetFont, fs, "Fonts\\FRIZQT__.TTF", size, flags)
    end
end

local function ApplyColor(fs, rgba)
    if not (fs and fs.SetTextColor) then return end
    if type(rgba) ~= "table" then return end
    fs:SetTextColor(rgba[1] or 1, rgba[2] or 1, rgba[3] or 1, rgba[4] or 1)
end

local function ForceShowHide(fs, show)
    if not fs then return end
    if show then
        if fs.SetAlpha then fs:SetAlpha(1) end
        if fs.Show then fs:Show() end
    else
        if fs.SetAlpha then fs:SetAlpha(0) end
        if fs.Hide then fs:Hide() end
    end
end

local function ApplyText(btn, ab)
    if not btn or type(ab) ~= "table" then return end

    local hk = GetHotkeyFS(btn)
    if hk then
        ApplyFont(hk, ab, "hotkey")
        ApplyColor(hk, ab.hotkeyRGBA)

        hk:ClearAllPoints()
        local p = ab.hotkeyPoint or { "TOPRIGHT", -2, -2 }
        hk:SetPoint(p[1], btn, p[1], p[2] or 0, p[3] or 0)

        ForceShowHide(hk, ab.showHotkey ~= false)

        if AB.ButtonText and AB.ButtonText.UpdateHotkey then
            AB.ButtonText:UpdateHotkey(btn)
        end
    end

    local mc = GetMacroFS(btn)
    if mc then
        ApplyFont(mc, ab, "macro")
        ApplyColor(mc, ab.macroRGBA)

        mc:ClearAllPoints()
        local p = ab.macroPoint or { "BOTTOMLEFT", 2, 2 }
        mc:SetPoint(p[1], btn, p[1], p[2] or 0, p[3] or 0)

        ForceShowHide(mc, ab.showMacro == true)
    end

    local ct = GetChargeFS(btn)
    if ct then
        ApplyFont(ct, ab, "charge")
        ApplyColor(ct, ab.chargeRGBA)
        if ct.SetJustifyH then
            ct:SetJustifyH(ab.chargeJustifyH or "RIGHT")
        end

        ct:ClearAllPoints()
        local p = ab.chargePoint or { "BOTTOMRIGHT", -1, 1 }
        ct:SetPoint(p[1], btn, p[1], p[2] or 0, p[3] or 0)
        ForceShowHide(ct, true)
    end
end

-- -------------------------------------------------------
-- State overlays (pushed/checked) + hover highlight
-- -------------------------------------------------------
local function EnsureStateTextures(btn, ab)
    if not btn or type(ab) ~= "table" then return end
    local icon = GetIcon(btn)

    if btn.SetPushedTexture then
        btn:SetPushedTexture(WHITE)
        local tex = btn:GetPushedTexture()
        if tex then
            tex:SetAllPoints(icon or btn)
            tex:SetDrawLayer("ARTWORK", 6)
            tex:SetVertexColor(unpack(ab.pushedRGBA or { 0, 0, 0, 0.35 }))
        end
    end

    if btn.SetCheckedTexture then
        btn:SetCheckedTexture(WHITE)
        local tex = btn:GetCheckedTexture()
        if tex then
            tex:SetAllPoints(icon or btn)
            tex:SetDrawLayer("ARTWORK", 5)
            tex:SetVertexColor(unpack(ab.checkedRGBA or { 1, 1, 1, 0.12 }))
        end
    end
end

local function EnsureHoverOverlay(btn)
    if btn.__nolHover then
        return btn.__nolHover
    end

    local icon = GetIcon(btn)

    local overlay = btn:CreateTexture(nil, "ARTWORK", nil, 4)
    overlay:SetTexture(WHITE)
    overlay:SetAllPoints(icon or btn)
    overlay:SetBlendMode("ADD")
    overlay:Hide()

    btn.__nolHover = overlay
    return overlay
end

-- -------------------------------------------------------
-- Background
-- -------------------------------------------------------
local function EnsureBackground(btn)
    if not btn.__nolBG then
        local bg = btn:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetTexture(WHITE)
        btn.__nolBG = bg
    end
    return btn.__nolBG
end

-- -------------------------------------------------------
-- Shadow / Container BG helper
-- -------------------------------------------------------
local function ApplyContainerShadow(c)
    local shadowEnabled = ns.Shadow and ns.Shadow.Apply and (function()
        local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
        if type(cfg) ~= "table" or type(cfg.shadow) ~= "table" then return true end
        return cfg.shadow.enabled ~= false
    end)()

    if not c.__nolContainerBG then
        local bg = c:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetTexture(WHITE)
        bg:SetAllPoints(c)
        c.__nolContainerBG = bg
    end

    if shadowEnabled then
        c.__nolContainerBG:SetVertexColor(0, 0, 0, 0.85)
        c.__nolContainerBG:Show()
        ns.Shadow:Apply(c)
    else
        c.__nolContainerBG:SetVertexColor(0, 0, 0, 0)
        c.__nolContainerBG:Hide()
        if ns.Shadow then ns.Shadow:Hide(c) end
    end
end

-- -------------------------------------------------------
-- Skin apply
-- -------------------------------------------------------
local function ApplySkin(btn)
    local ab = GetCfg()
    if not btn or type(ab) ~= "table" then return end

    if IsFlyoutButton(btn) then
        if btn.SetClipsChildren then
            btn:SetClipsChildren(false)
        end
    end

    if btn.__nolSkinned then
        if Border and Border.Update then
            Border:Update(btn, ab.borderPx, ab.borderRGBA)
        end
        ApplyText(btn, ab)
        EnsureStateTextures(btn, ab)
        if AB.ButtonText and AB.ButtonText.ApplyCooldown then
            AB.ButtonText:ApplyCooldown(btn)
        end
        return
    end

    btn.__nolSkinned = true

    if ns.ButtonArt and ns.ButtonArt.Strip then
        ns.ButtonArt:Strip(btn)
    end

    local icon = GetIcon(btn)
    if icon then
        icon:ClearAllPoints()
        icon:SetAllPoints(btn)
        ApplyIconZoom(btn, ab.iconZoom)
    end

    if btn.SetClipsChildren then
        btn:SetClipsChildren(true)
    end

    local bg = EnsureBackground(btn)
    bg:ClearAllPoints()
    bg:SetAllPoints(icon or btn)
    if ab.bgRGBA then
        bg:SetVertexColor(ab.bgRGBA[1] or 0, ab.bgRGBA[2] or 0, ab.bgRGBA[3] or 0, ab.bgRGBA[4] or 0)
    end
    bg:Show()

    if Border and Border.Apply then
        Border:Apply(btn, ab.borderPx, ab.borderRGBA)
    end

    local function FitCooldownFrame(cdf)
        if cdf and icon and cdf.ClearAllPoints and cdf.SetAllPoints then
            cdf:ClearAllPoints()
            cdf:SetAllPoints(icon)
        end
    end

    local function FitToIcon(f)
        if f and icon and f.ClearAllPoints and f.SetAllPoints then
            f:ClearAllPoints()
            f:SetAllPoints(icon)
        end
    end

    FitCooldownFrame(btn.cooldown or btn.Cooldown)
    FitCooldownFrame(btn.LossOfControlCooldown)
    FitCooldownFrame(btn.lossOfControlCooldown)
    FitCooldownFrame(btn.LossOfControl)
    FitCooldownFrame(btn.lossOfControl)

    local function FitReticle(rf)
        if not rf then return end
        FitToIcon(rf)
        if rf.Base then FitToIcon(rf.Base) end
        if rf.Highlight then FitToIcon(rf.Highlight) end
        if rf.Mask then FitToIcon(rf.Mask) end
        if rf.Base and rf.Base.SetTexCoord then rf.Base:SetTexCoord(0, 1, 0, 1) end
        if rf.Highlight and rf.Highlight.SetTexCoord then rf.Highlight:SetTexCoord(0, 1, 0, 1) end
    end

    FitReticle(btn.TargetReticleAnimFrame)
    FitReticle(btn.targetReticleAnimFrame)
    FitReticle(btn.TargetReticle)
    FitReticle(btn.targetReticle)

    local name = btn.GetName and btn:GetName()
    if name then
        FitReticle(_G[name .. "TargetReticleAnimFrame"])
        FitReticle(_G[name .. "TargetReticle"])
    end

    ApplyText(btn, ab)
    EnsureStateTextures(btn, ab)

    if AB.ButtonText and AB.ButtonText.ApplyCooldown then
        AB.ButtonText:ApplyCooldown(btn)
    end

    if not btn.__nolHoverHooked then
        btn.__nolHoverHooked = true
        local overlay = EnsureHoverOverlay(btn)

        btn:HookScript("OnEnter", function()
            local c = ab.highlightRGBA
            if c then
                overlay:SetVertexColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 0.12)
                overlay:Show()
            end
        end)

        btn:HookScript("OnLeave", function()
            overlay:Hide()
        end)
    end
end

-- -------------------------------------------------------
-- Visibility / Fade
-- -------------------------------------------------------
local function IsDisabled(anchor)
    return (anchor and (anchor.enabled == false or anchor.visibility == "hide")) == true
end

local function ApplyVisibility(container, anchor)
    if not (container and anchor) then return end
    if IsDisabled(anchor) then
        if container.SetAlpha then container:SetAlpha(0) end
        if container.Show then container:Show() end
        return
    end
end

local function ApplyMouseoverFade(container, buttons, anchor)
    if not anchor then return end
    if IsDisabled(anchor) then return end
    if anchor.visibility ~= "mouseover" then return end

    if F and F.BindBar then
        F:BindBar(container, buttons, anchor)
        return
    end

    if Fade and Fade.BindMouseover then
        for _, b in ipairs(buttons) do
            Fade:BindMouseover(b, b, anchor)
        end
    end
    if Fade and Fade.Apply then
        Fade:Apply(container, anchor)
    end
end

-- -------------------------------------------------------
-- Fade (folded in from Fade.lua)
-- -------------------------------------------------------
local function BindButton(btn, anchor)
    if not (Fade and Fade.BindMouseover and btn and anchor) then return end
    if anchor.visibility ~= "mouseover" then return end

    btn.__nolABFadeBound = btn.__nolABFadeBound or {}
    local key = tostring(anchor)
    if btn.__nolABFadeBound[key] then return end
    btn.__nolABFadeBound[key] = true

    Fade:BindMouseover(btn, btn, anchor)
end

function F:BindBar(container, buttons, anchor)
    if not anchor or not buttons then return end
    if not (Fade and Fade.BindMouseover) then return end
    if InCombat() then return end

    for _, btn in ipairs(buttons) do
        BindButton(btn, anchor)
    end

    if Fade and Fade.Apply then
        Fade:Apply(container, anchor)
    end
end

-- -------------------------------------------------------
-- Placement helpers
-- -------------------------------------------------------
local function PlaceBar(barName, prefix, count, anchor, sizeOverridePx, secureVisibilityDriver)
    if InCombat() then return end
    if not (Pixel and Pixel.SetPointPx and Pixel.SetSizePx) then return end
    if type(anchor) ~= "table" then return end

    -- If bar is disabled, hide our container and suppress the Blizzard bar
    if anchor.enabled == false then
        local c = EnsureContainer(barName, true)
        if RegisterStateDriver then
            RegisterStateDriver(c, "visibility", "hide")
        end
        c:Hide()
        KillBlizzardBar(prefix)
        return
    end

    -- Bar is enabled — release Blizzard suppression and clear our container
    -- state driver so it isn't stuck with "hide" from a previous disable
    UnkillBlizzardBar(prefix)

    local c = EnsureContainer(barName, true)
    if UnregisterStateDriver then
        UnregisterStateDriver(c, "visibility")
    end
    c.__nolDriver = nil

    local ab = GetCfg()

    c:ClearAllPoints()
    local rel = ResolveRelFrame(anchor)
    Pixel:SetPointPx(c, anchor.point, rel, anchor.relPoint or anchor.point, anchor.x or 0, anchor.y or 0)

    local size = tonumber(sizeOverridePx or ab.buttonPx) or 36
    local gap  = tonumber(ab.gapPx) or 2
    local stepPx = size + gap

    local layout = anchor.layout or "H"
    local cols = tonumber(anchor.columns or anchor.column) or count
    if cols < 1 then cols = 1 end
    if cols > count then cols = count end
    local rows = math.ceil(count / cols)

    local wPx, hPx = size, size
    if layout == "H" then
        wPx = (count * size) + ((count - 1) * gap)
        hPx = size
    elseif layout == "V" then
        wPx = size
        hPx = (count * size) + ((count - 1) * gap)
    elseif layout == "G" then
        wPx = (cols * size) + ((cols - 1) * gap)
        hPx = (rows * size) + ((rows - 1) * gap)
    end

    Pixel:SetSizePx(c, wPx, hPx)

    L.AllButtons = L.AllButtons or {}
    local btns = {}

    for i = 1, count do
        local btn = _G[prefix .. i]
        if btn then
            btn:SetParent(c)
            btn:ClearAllPoints()

            Pixel:SetSizePx(btn, size, size)

            local xPx, yPx = 0, 0
            if layout == "H" then
                xPx = (i - 1) * stepPx
                yPx = 0
            elseif layout == "V" then
                xPx = 0
                yPx = -((i - 1) * stepPx)
            elseif layout == "G" then
                local gcols = tonumber(anchor.columns or anchor.column) or count
                if gcols < 1 then gcols = 1 end
                if gcols > count then gcols = count end

                local col = (i - 1) % gcols
                local row = math.floor((i - 1) / gcols)

                xPx = col * stepPx
                yPx = -(row * stepPx)
            end

            Pixel:SetPointPx(btn, "TOPLEFT", c, "TOPLEFT", xPx, yPx)
            ApplySkin(btn)
            btn:Show()

            L.AllButtons[btn] = true
            btns[#btns + 1] = btn
        end
    end

    local hasDriver = false
    if secureVisibilityDriver and RegisterStateDriver then
        hasDriver = true
        if c.__nolDriver ~= secureVisibilityDriver then
            RegisterStateDriver(c, "visibility", secureVisibilityDriver)
            c.__nolDriver = secureVisibilityDriver
        end
    end

    if not hasDriver then
        c:Show()
    end

    ApplyContainerShadow(c)
    ApplyMouseoverFade(c, btns, anchor)
    ApplyVisibility(c, anchor)
end

local function PlaceButtonList(container, buttons, anchor, sizeOverridePx, secureVisibilityDriver)
    if InCombat() then return end
    if not (container and buttons and #buttons > 0) then return end
    if not (Pixel and Pixel.SetPointPx and Pixel.SetSizePx) then return end
    if type(anchor) ~= "table" then return end

    local ab = GetCfg()

    local needDriverUpdate = false
    if secureVisibilityDriver then
        if container.__ntVisibilityDriver ~= secureVisibilityDriver then
            needDriverUpdate = true
            if container.Hide then container:Hide() end
            if container.SetAlpha then container:SetAlpha(0) end
        end
    end

    local size = tonumber(sizeOverridePx or ab.buttonPx) or 36
    local gap  = tonumber(ab.gapPx) or 2
    local stepPx = size + gap

    container:ClearAllPoints()
    local rel = ResolveRelFrame(anchor)
    Pixel:SetPointPx(container, anchor.point, rel, anchor.relPoint or anchor.point, anchor.x or 0, anchor.y or 0)

    local layout = anchor.layout or "H"
    local count = #buttons

    local cols = tonumber(anchor.columns or anchor.column) or count
    if cols < 1 then cols = 1 end
    if cols > count then cols = count end
    local rows = math.ceil(count / cols)

    local wPx, hPx = size, size
    if layout == "H" then
        wPx = (count * size) + ((count - 1) * gap)
        hPx = size
    elseif layout == "V" then
        wPx = size
        hPx = (count * size) + ((count - 1) * gap)
    elseif layout == "G" then
        wPx = (cols * size) + ((cols - 1) * gap)
        hPx = (rows * size) + ((rows - 1) * gap)
    end

    Pixel:SetSizePx(container, wPx, hPx)

    L.AllButtons = L.AllButtons or {}

    for i, btn in ipairs(buttons) do
        btn:SetParent(container)
        btn:ClearAllPoints()
        Pixel:SetSizePx(btn, size, size)

        local xPx, yPx = 0, 0
        if layout == "H" then
            xPx = (i - 1) * stepPx
            yPx = 0
        elseif layout == "V" then
            xPx = 0
            yPx = -((i - 1) * stepPx)
        elseif layout == "G" then
            local gcols = tonumber(anchor.columns or anchor.column) or count
            if gcols < 1 then gcols = 1 end
            if gcols > count then gcols = count end

            local col = (i - 1) % gcols
            local row = math.floor((i - 1) / gcols)

            xPx = col * stepPx
            yPx = -(row * stepPx)
        end

        Pixel:SetPointPx(btn, "TOPLEFT", container, "TOPLEFT", xPx, yPx)
        ApplySkin(btn)
        if not secureVisibilityDriver then btn:Show() end

        L.AllButtons[btn] = true
    end

    local hasDriver = false
    if secureVisibilityDriver and RegisterStateDriver then
        hasDriver = true
        if needDriverUpdate then
            UnregisterStateDriver(container, "visibility")
            RegisterStateDriver(container, "visibility", secureVisibilityDriver)
            container.__ntVisibilityDriver = secureVisibilityDriver
        end
    end

    if not hasDriver then
        container:Show()
    end

    ApplyContainerShadow(container)

    if needDriverUpdate and container.SetAlpha then
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if container and container.SetAlpha then container:SetAlpha(1) end
            end)
        else
            container:SetAlpha(1)
        end
    end

    ApplyMouseoverFade(container, buttons, anchor)
    ApplyVisibility(container, anchor)
end

-- -------------------------------------------------------
-- Apply all bars
-- -------------------------------------------------------
local function ApplyAll()
    if InCombat() then return end
    local ab = GetCfg()
    if type(ab) ~= "table" then return end

    PlaceBar("NOL_ActionBar1", "ActionButton",             (ab.bar1 and ab.bar1.count) or 12, ab.bar1, ab.buttonPx, "[petbattle] hide; show")
    PlaceBar("NOL_ActionBar2", "MultiBarBottomLeftButton",  (ab.bar2 and ab.bar2.count) or 12, ab.bar2, ab.buttonPx, "[petbattle] hide; show")
    PlaceBar("NOL_ActionBar3", "MultiBarBottomRightButton", (ab.bar3 and ab.bar3.count) or 12, ab.bar3, ab.buttonPx, "[petbattle] hide; show")
    PlaceBar("NOL_ActionBar4", "MultiBarRightButton",       (ab.bar4 and ab.bar4.count) or 12, ab.bar4, ab.buttonPx, "[petbattle] hide; show")
    PlaceBar("NOL_ActionBar5", "MultiBarLeftButton",        (ab.bar5 and ab.bar5.count) or 12, ab.bar5, ab.buttonPx, "[petbattle] hide; show")
    PlaceBar("NOL_ActionBar6", "MultiBar5Button",           (ab.bar6 and ab.bar6.count) or 12, ab.bar6, ab.buttonPx, "[petbattle] hide; show")
    PlaceBar("NOL_ActionBar7", "MultiBar6Button",           (ab.bar7 and ab.bar7.count) or 12, ab.bar7, ab.buttonPx, "[petbattle] hide; show")
    PlaceBar("NOL_ActionBar8", "MultiBar7Button",           (ab.bar8 and ab.bar8.count) or 12, ab.bar8, ab.buttonPx, "[petbattle] hide; show")

    if ab.petBar then
        local pet = EnsureContainer("NOL_PetBar", true)
        local max = _G.NUM_PET_ACTION_SLOTS or 10
        local btns = {}
        for i = 1, max do
            local b = _G["PetActionButton" .. i]
            if b then btns[#btns + 1] = b end
        end
        PlaceButtonList(pet, btns, ab.petBar, ab.petButtonPx, "[petbattle][vehicleui] hide; [nopet] hide; show")
    end

    if ab.stanceBar then
        local stance = EnsureContainer("NOL_StanceBar", true)

        local num = 0
        if type(GetNumShapeshiftForms) == "function" then
            num = GetNumShapeshiftForms() or 0
        end

        local max = _G.NUM_STANCE_SLOTS or 10
        local n = math.max(0, math.min(num, max))

        local btns = {}
        for i = 1, n do
            local b = _G["StanceButton" .. i]
            if b then btns[#btns + 1] = b end
        end

        for i = n + 1, max do
            local b = _G["StanceButton" .. i]
            if b and b.Hide then b:Hide() end
        end

        if n == 0 then
            UnregisterStateDriver(stance, "visibility")
            RegisterStateDriver(stance, "visibility", "[petbattle][vehicleui] hide; hide")
        else
            PlaceButtonList(stance, btns, ab.stanceBar, ab.stanceButtonPx, "[petbattle][vehicleui] hide; show")
        end
    end
end

function L:ApplyAll()
    ApplyAll()
end

function L:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local f = CreateFrame("Frame")
    self.__driver = f

    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UI_SCALE_CHANGED")
    f:RegisterEvent("DISPLAY_SIZE_CHANGED")
    f:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    f:RegisterEvent("TRAIT_CONFIG_UPDATED")
    f:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    f:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    f:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    f:RegisterEvent("SPELLS_CHANGED")
    f:RegisterEvent("UPDATE_BONUS_ACTIONBAR")

    local dirtyDuringCombat = false

    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if InCombat() then return end
            if dirtyDuringCombat then
                dirtyDuringCombat = false
                C_Timer.After(0, ApplyAll)
            end
            return
        end

        if InCombat() then
            dirtyDuringCombat = true
            return
        end

        C_Timer.After(0, ApplyAll)
    end)

    if not InCombat() then
        C_Timer.After(0, ApplyAll)
        C_Timer.After(0.10, ApplyAll)
        C_Timer.After(0.30, ApplyAll)
    end
end
