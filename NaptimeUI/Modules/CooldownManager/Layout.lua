-- Modules/CooldownManager/Layout.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.CooldownManager = ns.Modules.CooldownManager or {}
local CM = ns.Modules.CooldownManager

CM.Layout = CM.Layout or {}
local L = CM.Layout

local WHITE = "Interface\\Buttons\\WHITE8X8"

-- -------------------------------------------------------
-- Helpers
-- -------------------------------------------------------

local function PixelPerfect(value)
    value = tonumber(value) or 0
    local _, screenHeight = GetPhysicalScreenSize()
    local uiScale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    local pixelSize = 768 / screenHeight / uiScale
    return pixelSize * math.floor(value / pixelSize + 0.5)
end

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return nil end
    return type(cfg.cooldownManager) == "table" and cfg.cooldownManager or nil
end

-- -------------------------------------------------------
-- Icon sizing
-- -------------------------------------------------------

function L:GetIconSize(barCfg)
    local cfg = GetCfg() or {}

    local w = tonumber(barCfg and barCfg.iconWidth)
    local h = tonumber(barCfg and barCfg.iconHeight)

    if not h then
        h = tonumber(cfg.wideIconHeight) or 27
    end
    if not w then
        if cfg.wideIcons then
            w = math.floor(h * (16 / 9))
        else
            w = h
        end
    end

    return w, h
end

-- -------------------------------------------------------
-- Texture crop
-- -------------------------------------------------------

function L:ApplyIconCrop(icon, w, h, barCfg)
    if not (icon and icon.SetTexCoord) then return end

    local cfg = GetCfg() or {}
    local zoom = tonumber(barCfg and barCfg.iconZoom)
        or tonumber(cfg.wideIconZoom)
        or tonumber(cfg.iconZoom)
        or 0.05

    if w == h then
        icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
        return
    end

    local frameAspect = w / h
    local visibleV    = 1 / frameAspect
    local cropV       = (1 - visibleV) * 0.5
    cropV = math.max(0, math.min(cropV, 0.35))

    local top    = cropV + zoom
    local bottom = 1 - cropV - zoom
    local left   = zoom
    local right  = 1 - zoom

    icon:SetTexCoord(left, right, top, bottom)
end

-- -------------------------------------------------------
-- Border
-- -------------------------------------------------------

function L:ApplyBorder(frame, w, h, barCfg)
    if not frame then return end

    local cfg  = GetCfg() or {}
    local rgba = (barCfg and barCfg.borderRGBA) or cfg.borderRGBA or { 0, 0, 0, 1 }
    local px   = PixelPerfect(tonumber(barCfg and barCfg.borderPx) or tonumber(cfg.borderPx) or 1)

    if px <= 0 then return end

    if not frame.__nolCMLayoutBorders then
        local top    = frame:CreateTexture(nil, "OVERLAY")
        local bottom = frame:CreateTexture(nil, "OVERLAY")
        local left   = frame:CreateTexture(nil, "OVERLAY")
        local right  = frame:CreateTexture(nil, "OVERLAY")

        for _, t in ipairs({ top, bottom, left, right }) do
            t:SetTexture(WHITE)
        end

        frame.__nolCMLayoutBorders = { top, bottom, left, right }
    end

    local r, g, b, a = rgba[1] or 0, rgba[2] or 0, rgba[3] or 0, rgba[4] or 1

    for _, t in ipairs(frame.__nolCMLayoutBorders) do
        t:SetVertexColor(r, g, b, a)
        t:Show()
    end

    local top, bottom, left, right = unpack(frame.__nolCMLayoutBorders)

    top:ClearAllPoints()
    top:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    top:SetHeight(px)

    bottom:ClearAllPoints()
    bottom:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  0, 0)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(px)

    left:ClearAllPoints()
    left:SetPoint("TOPLEFT",    frame, "TOPLEFT",    0, 0)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    left:SetWidth(px)

    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT",    frame, "TOPRIGHT",    0, 0)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(px)
end

-- -------------------------------------------------------
-- Force size on a child every frame
-- -------------------------------------------------------

local enforcedChildren = {}

local function StartSizeEnforce(child, w, h)
    if enforcedChildren[child] then return end
    enforcedChildren[child] = { w = w, h = h }
end

local sizeEnforceTicker
local function EnsureSizeEnforceTicker()
    if sizeEnforceTicker then return end
    sizeEnforceTicker = CreateFrame("Frame")
    sizeEnforceTicker:SetScript("OnUpdate", function()
        for child, size in pairs(enforcedChildren) do
            if child and child.SetSize then
                local cw = child:GetWidth()
                local ch = child:GetHeight()
                if math.abs(cw - size.w) > 0.5 or math.abs(ch - size.h) > 0.5 then
                    child:SetSize(size.w, size.h)
                end
            else
                enforcedChildren[child] = nil
            end
        end
    end)
end

-- -------------------------------------------------------
-- Skin a single child frame
-- -------------------------------------------------------

function L:SkinChild(child, barCfg)
    if not child then return false end

    local icon = child.Icon or child.icon
    if not icon then
        if child.GetRegions then
            for _, r in ipairs({ child:GetRegions() }) do
                if r and r.GetObjectType and r:GetObjectType() == "Texture" then
                    local tex = r.GetTexture and r:GetTexture()
                    if type(tex) == "string" and tex ~= ""
                    and not tex:find("WHITE8X8", 1, true) then
                        icon = r
                        break
                    end
                end
            end
        end
    end

    if not icon then return false end

    local w, h = self:GetIconSize(barCfg)

    -- Force size and keep enforcing it every frame
    child:SetSize(w, h)
    EnsureSizeEnforceTicker()
    StartSizeEnforce(child, w, h)

    -- Fit icon to fill child
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT",     child, "TOPLEFT",     0, 0)
    icon:SetPoint("BOTTOMRIGHT", child, "BOTTOMRIGHT", 0, 0)
    icon:SetSize(w, h)
    icon:SetDrawLayer("ARTWORK")

    -- Apply texture crop
    self:ApplyIconCrop(icon, w, h, barCfg)

    -- Hook crop to reapply if Blizzard resets the texture
    if not icon.__nolCropHooked then
        icon.__nolCropHooked = true
        if icon.SetTexture then
            hooksecurefunc(icon, "SetTexture", function(self)
                L:ApplyIconCrop(self, w, h, barCfg)
            end)
        end
        if icon.SetAtlas then
            hooksecurefunc(icon, "SetAtlas", function(self)
                L:ApplyIconCrop(self, w, h, barCfg)
            end)
        end
    end

    -- Remove mask textures
    if child.GetRegions then
        for _, r in ipairs({ child:GetRegions() }) do
            if r and r.GetObjectType and r:GetObjectType() == "MaskTexture" then
                if icon.RemoveMaskTexture then
                    pcall(icon.RemoveMaskTexture, icon, r)
                end
                local cd = child.Cooldown
                if cd and cd.RemoveMaskTexture then
                    pcall(cd.RemoveMaskTexture, cd, r)
                end
            end
        end
    end

    -- Fit cooldown frame
    local cd = child.Cooldown
    if cd then
        cd:ClearAllPoints()
        cd:SetPoint("TOPLEFT",     child, "TOPLEFT",     0, 0)
        cd:SetPoint("BOTTOMRIGHT", child, "BOTTOMRIGHT", 0, 0)
        if cd.SetDrawBling then pcall(cd.SetDrawBling, cd, false) end
        if cd.SetDrawEdge  then pcall(cd.SetDrawEdge,  cd, false) end
        if cd.SetEdgeScale then pcall(cd.SetEdgeScale, cd, 0)     end
    end

    -- Apply border
    self:ApplyBorder(child, w, h, barCfg)

    return true
end

-- -------------------------------------------------------
-- Layout a viewer: center-anchored horizontal row
-- -------------------------------------------------------

function L:LayoutViewer(viewer, barCfg)
    if not (viewer and viewer.GetChildren) then return end

    local cfg = GetCfg() or {}
    local gap = tonumber(barCfg and barCfg.gapPx) or tonumber(cfg.gapPx) or 2

    -- Collect valid children
    local children = {}
    for _, child in ipairs({ viewer:GetChildren() }) do
        if child and child.IsObjectType and child:IsObjectType("Frame") then
            local name = (child.GetDebugName and child:GetDebugName()) or ""

            if not name:find(".Selection", 1, true) then
                local icon = child.Icon or child.icon
                if not icon then
                    if child.GetRegions then
                        for _, r in ipairs({ child:GetRegions() }) do
                            if r and r.GetObjectType and r:GetObjectType() == "Texture" then
                                local tex = r.GetTexture and r:GetTexture()
                                if type(tex) == "string" and tex ~= ""
                                and not tex:find("WHITE8X8", 1, true) then
                                    icon = r
                                    break
                                end
                            end
                        end
                    end
                end

                local tex   = icon and icon.GetTexture and icon:GetTexture()
                local atlas = icon and icon.GetAtlas and icon:GetAtlas()
                if tex or atlas then
                    children[#children + 1] = child
                end
            end
        end
    end

    if #children == 0 then return end

    local w, h   = self:GetIconSize(barCfg)
    local stepPx = w + gap

    local totalWidth = (#children * w) + ((#children - 1) * gap)

    -- Resize viewer and re-center it on its current position
    local oldCenterX, oldCenterY
    if viewer.GetCenter then
        oldCenterX, oldCenterY = viewer:GetCenter()
    end

    viewer:SetSize(totalWidth, h)

    -- Re-anchor viewer to its center point so it expands equally both sides
    if oldCenterX and oldCenterY then
        viewer:ClearAllPoints()
        viewer:SetPoint("CENTER", UIParent, "BOTTOMLEFT", oldCenterX, oldCenterY)
    end

    -- Place each child from the left edge of the viewer
    for i, child in ipairs(children) do
        self:SkinChild(child, barCfg)
        child:ClearAllPoints()
        child:SetPoint("LEFT", viewer, "LEFT", (i - 1) * stepPx, 0)
        child:Show()
    end
end

-- -------------------------------------------------------
-- Apply to all viewers
-- -------------------------------------------------------

function L:RefreshAll()
    local cfg = GetCfg()
    if not cfg or cfg.enabled == false then return end

    local viewers = cfg.viewers or {}

    local viewerMap = {
        { frame = _G.EssentialCooldownViewer, key = "essential" },
        { frame = _G.UtilityCooldownViewer,   key = "utility"   },
        { frame = _G.BuffIconCooldownViewer,  key = "buff"      },
    }

    for _, entry in ipairs(viewerMap) do
        if entry.frame then
            local barCfg = viewers[entry.key] or {}
            self:LayoutViewer(entry.frame, barCfg)

            if not entry.frame.__nolLayoutHooked then
                entry.frame.__nolLayoutHooked = true
                entry.frame:HookScript("OnShow", function(self)
                    L:LayoutViewer(self, barCfg)
                end)
            end
        end
    end
end

-- -------------------------------------------------------
-- Enable
-- -------------------------------------------------------

function L:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local driver = CreateFrame("Frame")
    self.__driver = driver

    driver:RegisterEvent("PLAYER_LOGIN")
    driver:RegisterEvent("PLAYER_ENTERING_WORLD")
    driver:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    driver:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    driver:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

    driver:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit ~= "player" then return end
        C_Timer.After(0,    function() L:RefreshAll() end)
        C_Timer.After(0.15, function() L:RefreshAll() end)
        C_Timer.After(0.35, function() L:RefreshAll() end)
    end)

    C_Timer.After(0,    function() L:RefreshAll() end)
    C_Timer.After(0.15, function() L:RefreshAll() end)
    C_Timer.After(0.35, function() L:RefreshAll() end)
end
