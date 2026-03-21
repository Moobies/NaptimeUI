-- Modules/CooldownManager/Config.lua
local ADDON, ns = ...
ns = ns or {}

local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
if type(cfg) ~= "table" then
    ns.Config = {}
    cfg = ns.Config
end

cfg.cooldownManager = cfg.cooldownManager or {
    enabled    = true,
    borderPx   = 1,
    borderRGBA = { 0, 0, 0, 1 },
    iconZoom   = 0.10,

    -- Wide icon globals
    wideIcons      = true,
    wideIconHeight = 27,
    wideIconZoom   = 0.08,

    -- Gap between icons
    gapPx = 2,

    -- Per-viewer overrides (falls back to globals above if not set)
    viewers = {
        essential = {
            iconWidth  = 42,
            iconHeight = 27,
            iconZoom   = 0.02,
            gapPx      = 2,
            borderPx   = 1,
            borderRGBA = { 0, 0, 0, 1 },
        },
        utility = {
            iconHeight = 27,
            gapPx      = 2,
        },
        buff = {
            iconHeight = 27,
            gapPx      = 2,
        },
    },

    power = {
        enabled            = true,
        font               = "Secondary",
        mainSize           = 10,
        mainFlags          = "OUTLINEMONOCHROME",
        subSize            = 12,
        subFlags           = "OUTLINE",
        showText           = true,
        showComboText      = false,
        showPowerCombatOnly = false,
        showComboCombatOnly = false,
        borderRGBA         = { 0, 0, 0, 1 },
        textRGBA           = { 1, 1, 1, 1 },

        bar = {
            width  = 204,
            height = 11,
            point  = { "CENTER", "CENTER" },
            x      = 0,
            y      = -231,
            bgRGBA = { 0.08, 0.08, 0.08, 0.85 },
        },

        combo = {
            enabled    = true,
            width      = 204,
            height     = 10,
            point      = { "CENTER", "CENTER" },
            x          = 0,
            y          = -220,
            bgRGBA     = { 0.08, 0.08, 0.08, 0.85 },
            fillRGBA   = { 1.00, 0.84, 0.00, 1.00 },
            dividerRGBA = { 0, 0, 0, 1 },
            spacing    = 0,
        },
    },
}
