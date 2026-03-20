-- Modules/CooldownManager/CDM_States.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.CooldownManager = ns.Modules.CooldownManager or {}
local CM = ns.Modules.CooldownManager

CM.State = CM.State or {}
local S = CM.State

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return nil end
    return type(cfg.cooldownManager) == "table" and cfg.cooldownManager or nil
end

function S:UseWideIcons()
    local cfg = GetCfg()
    return cfg and cfg.wideIcons == true
end

function S:GetIconSize()
    local cfg = GetCfg() or {}
    local h = tonumber(cfg.wideIconHeight) or 27

    if self:UseWideIcons() then
        return h * (16 / 9), h
    end

    return h, h
end

function S:GetIconZoom()
    local cfg = GetCfg() or {}
    return tonumber(cfg.wideIconZoom) or 0.02
end

function S:ApplyIconCrop(icon, width, height)
    if not (icon and icon.SetTexCoord and width and height) then return end

    local zoom = self:GetIconZoom()

    if not self:UseWideIcons() then
        icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
        return
    end

    local frameAspect = width / height
    local texAspect = 1

    local left, right = zoom, 1 - zoom
    local top, bottom = zoom, 1 - zoom

    if frameAspect > texAspect then
        local visibleWidth = texAspect / frameAspect
        local cropX = (1 - visibleWidth) * 0.5
        left = cropX + zoom
        right = 1 - cropX - zoom
    end

    icon:SetTexCoord(left, right, top, bottom)
end
