-- Modules/CooldownManager/CooldownManager.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.CooldownManager = ns.Modules.CooldownManager or {}
local CM = ns.Modules.CooldownManager

local DEFAULT_CFG = {
    enabled = true,
    borderPx = 1,
    borderRGBA = {0, 0, 0, 1},
    iconZoom = 0.10,
}

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" or type(cfg.cooldownManager) ~= "table" then
        return DEFAULT_CFG
    end
    return cfg.cooldownManager
end

local function IsEnabled()
    local cfg = GetCfg()
    return cfg.enabled ~= false
end

local function GetViewers()
    return {
        _G.EssentialCooldownViewer,
        _G.UtilityCooldownViewer,
        _G.BuffIconCooldownViewer,
    }
end

local function GetDebugName(frame)
    if not frame then return nil end
    if frame.GetDebugName then return frame:GetDebugName() end
    if frame.GetName then return frame:GetName() end
    return nil
end

local function IsSelectionChild(frame)
    local name = GetDebugName(frame)
    return type(name) == "string" and name:find(".Selection", 1, true) ~= nil
end

local function GetChildIcon(child)
    if not child then return nil end

    if child.Icon then return child.Icon end
    if child.icon then return child.icon end

    if child.GetRegions then
        for _, region in ipairs({ child:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                local tex = region.GetTexture and region:GetTexture()
                if type(tex) == "string" and tex ~= "" and not tex:find("WHITE8X8", 1, true) then
                    return region
                end
            end
        end

        local r1 = select(1, child:GetRegions())
        if r1 and r1.GetObjectType and r1:GetObjectType() == "Texture" then
            return r1
        end
    end

    return nil
end

local TameCooldown

local function HookCooldown(child, icon)
    local cd = child and child.Cooldown
    if not cd or cd.__nolCMHooked then return end
    cd.__nolCMHooked = true

    local function RefreshCooldown()
        if not child or not icon then return end
        TameCooldown(child, icon)
    end

    if cd.HookScript then
        cd:HookScript("OnShow", RefreshCooldown)
    end

    if cd.SetCooldown then
        hooksecurefunc(cd, "SetCooldown", RefreshCooldown)
    end

    if cd.SetChargeCooldown then
        hooksecurefunc(cd, "SetChargeCooldown", RefreshCooldown)
    end
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

local function CreateBorderTextures(child)
    if child.__nolCMBorders then
        return unpack(child.__nolCMBorders)
    end

    local top = child:CreateTexture(nil, "OVERLAY")
    local bottom = child:CreateTexture(nil, "OVERLAY")
    local left = child:CreateTexture(nil, "OVERLAY")
    local right = child:CreateTexture(nil, "OVERLAY")

    child.__nolCMBorders = { top, bottom, left, right }
    return top, bottom, left, right
end

local function ApplyIconZoom(icon, zoom)
    if not (icon and icon.SetTexCoord) then return end

    zoom = tonumber(zoom) or 0.10
    icon.__nolIconZoom = zoom

    local function Apply(tex)
        if not tex or tex.__nolApplyingZoom then return end
        tex.__nolApplyingZoom = true

        local z = tex.__nolIconZoom or 0.10
        tex:SetTexCoord(z, 1 - z, z, 1 - z)

        tex.__nolApplyingZoom = nil
    end

    Apply(icon)

    if not icon.__nolZoomHooked then
        icon.__nolZoomHooked = true

        if icon.SetTexture then
            hooksecurefunc(icon, "SetTexture", Apply)
        end

        if icon.SetAtlas then
            hooksecurefunc(icon, "SetAtlas", Apply)
        end
    end
end

local function RemoveChildMasking(child, icon)
    if not (child and child.GetRegions and icon) then return end

    for _, region in ipairs({ child:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "MaskTexture" then
            if icon.RemoveMaskTexture then
                pcall(icon.RemoveMaskTexture, icon, region)
            end

            local cd = child.Cooldown
            if cd and cd.RemoveMaskTexture then
                pcall(cd.RemoveMaskTexture, cd, region)
            end
        end
    end
end

local function HideNonIconRegions(child, icon)
    if not (child and child.GetRegions and icon) then return end

    for _, region in ipairs({ child:GetRegions() }) do
        if region and region ~= icon and region.GetObjectType then
            local objType = region:GetObjectType()

            if objType == "Texture" then
                local name = region.GetDebugName and region:GetDebugName() or ""
                local layer = region.GetDrawLayer and region:GetDrawLayer() or ""
                local tex = region.GetTexture and region:GetTexture()

                local isWhite = type(tex) == "string" and tex:find("WHITE8X8", 1, true)
                local isOutOfRange = type(name) == "string" and name:find(".OutOfRange", 1, true)
                local isOverlay = (layer == "OVERLAY")

                if isOverlay and not isWhite and not isOutOfRange then
                    if region.Hide then
                        region:Hide()
                    elseif region.SetAlpha then
                        region:SetAlpha(0)
                    end
                end
            end
        end
    end
end

local function HideNonIconChildren(child, icon)
    if not (child and child.GetChildren) then return end

    for _, sub in ipairs({ child:GetChildren() }) do
        if sub and sub ~= icon then
            local name = GetDebugName(sub) or ""

            local isCooldown = (sub == child.Cooldown)
            local isChargeCount = (sub == child.ChargeCount)

            local isNamedIcon = type(name) == "string" and name:find(".Icon", 1, true)
            local isNamedCharge = type(name) == "string" and name:find(".ChargeCount", 1, true)
            local isNamedStack = type(name) == "string" and (
                name:find(".Stack", 1, true)
                or name:find(".Count", 1, true)
                or name:find(".Applications", 1, true)
            )

            if not isCooldown and not isChargeCount and not isNamedIcon and not isNamedCharge and not isNamedStack then
                if sub.Hide then
                    sub:Hide()
                elseif sub.SetAlpha then
                    sub:SetAlpha(0)
                end
            end
        end
    end
end

local function LayoutIconToFillChild(child, icon, cfg)
    if not (child and icon) then return end

    if icon.ClearAllPoints and icon.SetPoint then
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
        icon:SetPoint("BOTTOMRIGHT", child, "BOTTOMRIGHT", 0, 0)
    end

    if icon.SetDrawLayer then
        icon:SetDrawLayer("ARTWORK")
    end

    ApplyIconZoom(icon, (cfg and cfg.iconZoom) or DEFAULT_CFG.iconZoom)
end

local function GetCooldownOverscan(child)
    if not child then return 0 end

    local w = child.GetWidth and child:GetWidth() or 0
    local h = child.GetHeight and child:GetHeight() or 0
    local s = math.min(w, h)

    if s >= 36 then
        return 2
    elseif s >= 28 then
        return 1
    else
        return 0
    end
end

TameCooldown = function(child, icon)
    local cd = child and child.Cooldown
    if not cd then return end

    local o = GetCooldownOverscan(child)

    if cd.ClearAllPoints and cd.SetPoint then
        cd:ClearAllPoints()
        cd:SetPoint("TOPLEFT", child, "TOPLEFT", -o, o)
        cd:SetPoint("BOTTOMRIGHT", child, "BOTTOMRIGHT", o, -o)
    end

    if cd.SetDrawSwipe then
        pcall(cd.SetDrawSwipe, cd, true)
    end

    if cd.SetDrawBling then
        pcall(cd.SetDrawBling, cd, false)
    end

    if cd.SetDrawEdge then
        pcall(cd.SetDrawEdge, cd, false)
    end

    if cd.SetUseCircularEdge then
        pcall(cd.SetUseCircularEdge, cd, false)
    end

    if cd.SetHideCountdownNumbers then
        pcall(cd.SetHideCountdownNumbers, cd, false)
    end

    if cd.SetEdgeScale then
        pcall(cd.SetEdgeScale, cd, 0)
    end
end

local function ApplyBCDMStyleBorder(child, icon, cfg)
    if not (child and icon) then return false end

    local borderPx = tonumber(cfg and cfg.borderPx) or DEFAULT_CFG.borderPx
    local rgba = (cfg and cfg.borderRGBA) or DEFAULT_CFG.borderRGBA
    local px = PixelPerfect(borderPx)
    local show = borderPx > 0

    local top, bottom, left, right = CreateBorderTextures(child)

    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
    top:SetHeight(px)

    bottom:ClearAllPoints()
    bottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(px)

    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
    left:SetWidth(px)

    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(px)

    for _, tex in ipairs(child.__nolCMBorders) do
        tex:SetColorTexture(rgba[1] or 0, rgba[2] or 0, rgba[3] or 0, rgba[4] or 1)
        tex:SetShown(show)
    end

    return true
end

local function SkinChild(child, cfg)
    if not child or IsSelectionChild(child) then return false end

    local icon = GetChildIcon(child)
    if not icon then return false end

    local tex = icon.GetTexture and icon:GetTexture()
    local atlas = icon.GetAtlas and icon:GetAtlas()
    if not tex and not atlas then
        return false
    end

    RemoveChildMasking(child, icon)
    HideNonIconRegions(child, icon)
    HideNonIconChildren(child, icon)
    LayoutIconToFillChild(child, icon, cfg)
    TameCooldown(child, icon)
    HookCooldown(child, icon)

    return ApplyBCDMStyleBorder(child, icon, cfg)
end

local function SkinViewer(viewer, cfg)
    if not (viewer and viewer.GetChildren) then return false end

    local foundAny = false
    for _, child in ipairs({ viewer:GetChildren() }) do
        if child and child.IsObjectType and child:IsObjectType("Frame") then
            if SkinChild(child, cfg) then
                foundAny = true
            end
        end
    end
    return foundAny
end

local function HookViewer(viewer)
    if not viewer or not viewer.HookScript or viewer.__nolCMHooked then return end
    viewer.__nolCMHooked = true

    viewer:HookScript("OnShow", function(self)
        SkinViewer(self, GetCfg())
    end)
end

local function RefreshAll()
    if not IsEnabled() then return false end

    local cfg = GetCfg()
    local foundAny = false

    for _, viewer in ipairs(GetViewers()) do
        if viewer then
            HookViewer(viewer)
            if SkinViewer(viewer, cfg) then
                foundAny = true
            end
        end
    end

    return foundAny
end

function CM:Enable()
    if self.__enabled then return end
    self.__enabled = true

    if self.Power and self.Power.Enable then
        self.Power:Enable()
    end

    if self.Layout and self.Layout.Enable then
    self.Layout:Enable()
    end

    local driver = CreateFrame("Frame")
    self.__driver = driver

    driver:RegisterEvent("PLAYER_LOGIN")
    driver:RegisterEvent("PLAYER_ENTERING_WORLD")
    driver:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    driver:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

    driver:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit ~= "player" then
            return
        end

        C_Timer.After(0, RefreshAll)
        C_Timer.After(0.10, RefreshAll)
        C_Timer.After(0.30, RefreshAll)
    end)

    C_Timer.After(0, RefreshAll)
    C_Timer.After(0.10, RefreshAll)
    C_Timer.After(0.30, RefreshAll)
end

function CM:Disable()
    if self.Power and self.Power.Disable then
        self.Power:Disable()
    end
end
