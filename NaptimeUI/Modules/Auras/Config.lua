-- Modules/Auras/Config.lua
local ADDON, ns = ...
ns = ns or {}

local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
if type(cfg) ~= "table" then
    ns.Config = {}
    cfg = ns.Config
end

cfg.auras = cfg.auras or {
    enabled = true,

    sizePx = 38,
    gapPx  = 2,
    perRow = 12,

    iconZoom = 0.10,

    borderPx   = 1,
    borderRGBA = { 0, 0, 0, 1 },

    bgRGBA = { 0, 0, 0, 0.35 },

    buffAnchor = {
        point = "TOPRIGHT",
        relPoint = "TOPRIGHT",
        x = -242,
        y = -20,
        perRow = 12,
    },

    debuffAnchor = {
        point = "TOPRIGHT",
        relPoint = "TOPRIGHT",
        x = -242,
        y = -202,
        perRow = 12,
    },

    showWeaponEnchants = true,
    hideBlizzardBuffs = true,

    blockedBuffs = {},

    buffCount = {
        font = "Primary",
        size = 12,
        flags = "OUTLINE",
        rgba = {1,1,1,1},
        point = {"BOTTOMRIGHT", -1, 1},
        justifyH = "RIGHT",
    },

    buffTime = {
        font = "Primary",
        size = 11,
        flags = "OUTLINE",
        rgba = {1,1,1,1},
        point = {"CENTER", 0, 0},
        justifyH = "CENTER",
    },

    debuffCount = {
        font = "Primary",
        size = 12,
        flags = "OUTLINE",
        rgba = {1,1,1,1},
        point = {"BOTTOMRIGHT", -1, 1},
        justifyH = "RIGHT",
    },

    debuffTime = {
        font = "Primary",
        size = 11,
        flags = "OUTLINE",
        rgba = {1,1,1,1},
        point = {"TOP", 0, -1},
        justifyH = "CENTER",
    },
}
