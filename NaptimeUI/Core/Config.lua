local ADDON, ns = ...
ns = ns or {}

-- Saved vars
NOL_DB = NOL_DB or {}

-- ------------------------------------------------------------
-- Config (physical pixel intent)
-- ------------------------------------------------------------
ns.Config = {
    -- Shared style (used by multiple modules)
    iconZoom    = 0.10,
    cmIconZoom  = 0.10,
    iconInsetPx = 0,

    borderPx    = 1,
    borderRGBA  = { 0, 0, 0, 1 },

    bgRGBA      = { 0.08, 0.08, 0.08, 0.65 },

    shadow = {
        enabled = true,
        alpha   = 0.60,
        inset   = 24,
    },

    -- ToolTip
    tipRGBA       = { 0.12, 0.12, 0.12, 1.00 },
    tipBorderRGBA = { 0, 0, 0, 1 },
    tipBorderPx   = 1,

    flyoutIconZoom = 0.14,
    flyoutBGRGBA = { 0.08, 0.08, 0.08, 0.00 },
    flyoutKillIconMask = true,

    shadow = {
        enabled = true,
        alpha = 0.80,
        widthExtra = 20,
        height = 30,
        offsetY = -2,
    }
}

function ns:IsModuleEnabled(key)
    NOL_DB = NOL_DB or {}
    NOL_DB.modules = NOL_DB.modules or {}

    local val = NOL_DB.modules[key]
    if val == nil then
        return true
    end
    return val == true
end

-- Convenience: export
function ns:GetConfig()
    return ns.Config
end
