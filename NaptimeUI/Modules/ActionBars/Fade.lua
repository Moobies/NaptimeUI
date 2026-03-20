-- Modules/ActionBars/Fade.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.ActionBars = ns.Modules.ActionBars or {}
local AB = ns.Modules.ActionBars
AB.Fade = AB.Fade or {}
local F = AB.Fade

local Fade = ns.Fade

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return nil end
    if type(cfg.actionbars) ~= "table" then return nil end
    return cfg.actionbars
end

-- Bind fade to a button (safe even when containers are secure)
local function BindButton(btn, anchor)
    if not (Fade and Fade.BindMouseover and btn and anchor) then return end
    if anchor.visibility ~= "mouseover" then return end

    -- Prevent double-binding
    btn.__nolABFadeBound = btn.__nolABFadeBound or {}
    local key = tostring(anchor) -- table identity
    if btn.__nolABFadeBound[key] then return end
    btn.__nolABFadeBound[key] = true

    -- Bind mouseover to the button itself
    Fade:BindMouseover(btn, btn, anchor)
end

-- Apply fade settings to the bar container (alpha only, no show/hide)
local function ApplyContainer(container, anchor)
    if not (Fade and Fade.Apply and container and anchor) then return end
    Fade:Apply(container, anchor)
end

-- Public API used by ActionBars.lua
function F:BindBar(container, buttons, anchor)
    if not anchor or not buttons then return end
    if not (Fade and Fade.BindMouseover) then return end

    -- In combat, avoid touching anything if Fade module uses protected ops internally.
    -- Binding scripts is usually okay, but we keep it conservative.
    if InCombat() then return end

    for _, btn in ipairs(buttons) do
        BindButton(btn, anchor)
    end

    -- Apply alpha settings to container (safe)
    ApplyContainer(container, anchor)
end
