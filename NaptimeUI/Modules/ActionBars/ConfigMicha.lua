-- Modules/ActionBars/Config.lua
local ADDON, ns = ...
ns = ns or {}

-- ActionBars-only defaults live here.
-- The rest of the UI config stays in Core/Config.lua.
local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
if type(cfg) ~= "table" then
    ns.Config = {}
    cfg = ns.Config
end

cfg.actionbars = cfg.actionbars or {
    -- Background Colour
    bgRGBA      = { 0.08, 0.08, 0.08, 0.65 },

    -- Sizes / layout
    buttonPx   = 38,
    gapPx      = 2,
    petButtonPx    = 32,
    stanceButtonPx = 32,

    -- Text toggles
    showHotkey = true,
    showMacro  = false,

    -- State overlays / highlight
    pushedRGBA    = {1, 1, 1, 0.5},
    checkedRGBA   = {1, 1, 1, 0.5},
    highlightRGBA = {1, 1, 1, 0.3},
    cancelBorderRGBA = { 1, 0.2, 0.2, 1 },
    cancelBorderFadeSecs = 1.0,

    -- Equipped border tint
    equippedRGBA = { 0.2, 1, 0.2, 1 },

    -- Casting / procs (visual suppression)
    disableProcGlow     = false,
    shrinkProcGlow      = false,
    disableCastOverlay  = true,
    castOverlayInsetPx  = 1,
    procGlowInsetPx     = 1,

    -- State tints
    rangeRGBA    = { 1, 0.2, 0.2, 1 },

    -- Keep icon full-colour; just darken (no desat)
    unusableRGBA = { 0.55, 0.55, 0.55, 1 },
    noPowerRGBA  = { 0.55, 0.55, 0.55, 1 },

    -- Hotkey text
    hotkeyFont  = "Primary",
    hotkeySize  = 9,
    hotkeyFlags = "OUTLINE",
    hotkeyRGBA  = {1,1,1,1},
    hotkeyPoint = {"TOPRIGHT", -1, -1},

    -- Macro text
    macroFont  = "Primary",
    macroSize  = 8,
    macroFlags = "OUTLINE",
    macroRGBA  = {1,1,1,1},
    macroPoint = {"BOTTOMLEFT", 2, 2},

    -- Cooldown count text (numbers on the swipe)
    cooldownFont  = "Primary",
    cooldownSize  = 10,
    cooldownFlags = "OUTLINE",
    cooldownRGBA  = {1,1,1,1},
    cooldownShadow = false,

    -- Charge Font
    chargeFont     = "Primary",
    chargeSize     = 9,
    chargeFlags    = "OUTLINE",
    chargeRGBA     = {1,1,1,1},
    chargePoint    = {"BOTTOMRIGHT", -1, 1},
    chargeJustifyH = "RIGHT",

    -- Experience Bar
    xpbar = {
        enabled = true,
        point = "TOP",
        relPoint = "BOTTOM",
        x = 0,
        y = -1,

        width = 220,
        height = 10,

        borderPx = 1,
        borderRGBA = {0,0,0,1},
        bgRGBA = {0,0,0,0.35},
        xpRGBA = {0.6, 0.0, 1.0, 1},
        restedRGBA = {0.2, 0.6, 1.0, 0.5},
    },

    vehicleExit = {
        sizePx = 36,
        borderPx = 1,
        borderRGBA = {0, 0, 0, 1},
        bgRGBA = {0.08, 0.08, 0.08, 0.75},
        iconZoom = 0.10,
        point = "BOTTOM",
        relPoint = "BOTTOM",
        x = 0,
        y = 120,
    },

    -- Layout anchors
    bar1 = { point="BOTTOM", relPoint="BOTTOM", x=0, y=10, layout="H", count=12 },
    bar2 = { point="BOTTOM", relPoint="BOTTOM", x=0, y=90, layout="H", count=12 },

    -- Right bars
    bar3 = { point="BOTTOM", relPoint="BOTTOM", x=-0, y=50, layout="H", count=12, },
    bar4 = { point="RIGHT", relPoint="RIGHT", x=-10, y=0, layout="V", count=12, },
    bar5 = { point="RIGHT", relPoint="RIGHT", x=-90, y=0, layout="V", count=12, enabled=false },

    -- Extra bars
    bar6 = { point="BOTTOM", relPoint="BOTTOM", x=500, y=10, layout="H", column=6, count=12, enabled=false },
    bar7 = { point="BOTTOM", relPoint="BOTTOM", x=500, y=50, layout="H", column=6, count=12, enabled=false },
    bar8 = { point="TOP", relPoint="TOP", x=0, y=-5, layout="H", column=1, count=12, enabled=false },

    -- Optional: Pet + Stance
    petBar    = { point="BOTTOM", relPoint="BOTTOM", x=0, y=90, layout="H" },
    stanceBar = { point="BOTTOM", relPoint="BOTTOM", x=0, y=130, layout="H" },
}
