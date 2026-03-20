-- Modules/Minimap/Config.lua
local ADDON, ns = ...
ns = ns or {}

local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
if type(cfg) ~= "table" then
    ns.Config = {}
    cfg = ns.Config
end

cfg.minimap = cfg.minimap or {
    point = "TOPRIGHT",
    relPoint = "TOPRIGHT",
    x = -20,
    y = -20,

    sizePx = 220,

    queueScale = 0.5,

    borderPx = 1,
    borderRGBA = {0,0,0,1},
    bgRGBA = {0.08,0.08,0.08,0.65},

    mail = { point="TOPLEFT", relPoint="TOPLEFT", x=3, y=-3 },
    clock = { point="BOTTOM", relPoint="BOTTOM", x=0, y=2 },
    zoneText = { point="TOP", relPoint="TOP", x=0, y=-6 },

    instanceDifficulty = { point="TOPLEFT", relPoint="TOPLEFT", x=2, y=-2 },
    guildDifficulty    = { point="TOPLEFT", relPoint="TOPLEFT", x=2, y=-18 },

    tracking = { point="BOTTOMRIGHT", relPoint="BOTTOMRIGHT", x=-2, y=2 },
    queue    = { point="BOTTOMLEFT", relPoint="BOTTOMLEFT", x=2, y=2 },

    font = {
        name  = "Secondary",
        clockSize = 10,
        zoneSize  = 10,
        flags = "OUTLINEMONOCHROME",
        rgba  = {1,1,1,1},
    },
}
