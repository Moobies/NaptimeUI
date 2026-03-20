local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.SpellFlyoutSkin = ns.Modules.SpellFlyoutSkin or {}
local F = ns.Modules.SpellFlyoutSkin

local Pixel  = ns.Pixel
local Border = ns.Border

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

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

local function ApplyIconZoom(icon, zoom)
    if not (icon and icon.SetTexCoord) then return end

    local z = tonumber(zoom) or 0.10
    if z < 0 then z = 0 end
    if z > 0.35 then z = 0.35 end

    icon:SetTexCoord(z, 1 - z, z, 1 - z)
end

local function HideObj(obj)
    if not obj then return end
    if obj.Hide then obj:Hide() end
    if obj.SetAlpha then obj:SetAlpha(0) end
end

local function HideNamed(parent, key)
    if not parent then return end
    local obj = parent[key]
    if obj then
        HideObj(obj)
    end
end

local function HideGlobal(name)
    local obj = _G[name]
    if obj then
        HideObj(obj)
    end
end

local function StripFlyoutFrameArt()
    if not SpellFlyout then return end

    HideNamed(SpellFlyout, "Background")
    HideNamed(SpellFlyout, "HorizontalBackground")
    HideNamed(SpellFlyout, "VerticalBackground")
    HideNamed(SpellFlyout, "TopEdge")
    HideNamed(SpellFlyout, "BottomEdge")
    HideNamed(SpellFlyout, "LeftEdge")
    HideNamed(SpellFlyout, "RightEdge")
    HideNamed(SpellFlyout, "TopLeftCorner")
    HideNamed(SpellFlyout, "TopRightCorner")
    HideNamed(SpellFlyout, "BottomLeftCorner")
    HideNamed(SpellFlyout, "BottomRightCorner")

    if SpellFlyout.Background then
        HideNamed(SpellFlyout.Background, "VerticalMiddle")
        HideNamed(SpellFlyout.Background, "HorizontalMiddle")
        HideNamed(SpellFlyout.Background, "Top")
        HideNamed(SpellFlyout.Background, "Bottom")
        HideNamed(SpellFlyout.Background, "Left")
        HideNamed(SpellFlyout.Background, "Right")
    end
end

local function SkinPopupButton(btn, cfg)
    if not (btn and cfg) then return end

    if Pixel and Pixel.Enforce then
        Pixel:Enforce(btn)
    end

    local name = btn.GetName and btn:GetName()
    if name then
        HideGlobal(name .. "SlotBackground")
        HideGlobal(name .. "NormalTexture")
    end

    HideNamed(btn, "SlotBackground")

    if btn.GetNormalTexture then
        local nt = btn:GetNormalTexture()
        if nt then HideObj(nt) end
    end

    local icon = GetIcon(btn)
    if icon then
        icon:ClearAllPoints()
        icon:SetAllPoints(btn)
        ApplyIconZoom(icon, tonumber(cfg.flyoutIconZoom) or tonumber(cfg.iconZoom) or 0.10)
        if icon.SetVertexColor then icon:SetVertexColor(1, 1, 1, 1) end
        if icon.SetAlpha then icon:SetAlpha(1) end
        icon:Show()
    end

    local cd = btn.cooldown or btn.Cooldown
    if cd and cd.ClearAllPoints and cd.SetAllPoints and icon then
        cd:ClearAllPoints()
        cd:SetAllPoints(icon)
    end

    if Border and Border.Apply then
        if not btn.__nolFlyoutBorderApplied then
            btn.__nolFlyoutBorderApplied = true
            Border:Apply(btn, tonumber(cfg.borderPx) or 1, cfg.borderRGBA or {0, 0, 0, 1})
        elseif Border.Update then
            Border:Update(btn, tonumber(cfg.borderPx) or 1, cfg.borderRGBA or {0, 0, 0, 1})
        end
    end

    local arrow = btn.FlyoutArrow or btn.Arrow
    if arrow and arrow.SetDrawLayer then
        arrow:SetDrawLayer("OVERLAY", 1)
    end
end

local function SkinVisibleFlyout()
    if InCombat() then return end
    if not SpellFlyout or not SpellFlyout:IsShown() then return end

    local cfg = GetCfg()
    if not cfg then return end

    StripFlyoutFrameArt()

    local count = tonumber(SpellFlyout.numSlots) or 12
    for i = 1, count do
        local btn = _G["SpellFlyoutPopupButton" .. i]
        if btn and btn:IsShown() then
            SkinPopupButton(btn, cfg)
        end
    end
end

local function QueueSkin()
    C_Timer.After(0, SkinVisibleFlyout)
    C_Timer.After(0.03, SkinVisibleFlyout)
    C_Timer.After(0.08, SkinVisibleFlyout)
end

function F:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local f = CreateFrame("Frame")
    self.__driver = f

    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("SPELLS_CHANGED")

    f:SetScript("OnEvent", function()
        if not SpellFlyout then return end

        if not self.__hooked then
            self.__hooked = true

            SpellFlyout:HookScript("OnShow", QueueSkin)

            if type(SpellFlyout_Toggle) == "function" then
                hooksecurefunc("SpellFlyout_Toggle", QueueSkin)
            end

            if type(SpellFlyout_UpdateFlyout) == "function" then
                hooksecurefunc("SpellFlyout_UpdateFlyout", QueueSkin)
            end
        end

        if SpellFlyout:IsShown() then
            QueueSkin()
        end
    end)
end
