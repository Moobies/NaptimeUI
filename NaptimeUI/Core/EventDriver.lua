-- Core/EventDriver.lua
local ADDON, ns = ...
ns = ns or {}

ns.Events = ns.Events or {}
local E = ns.Events

-- eventName -> { [callback] = true, ... }
E._handlers = E._handlers or {}

-- eventName -> true (coalesce rapid events; last args win)
E._throttle = E._throttle or {}

-- eventName -> { args = {...} }
E._pending = E._pending or {}

-- eventName -> { [callback] = { [unitToken] = true, ... }, ... }
-- only callbacks present here are unit-event registrations
E._unitMap = E._unitMap or {}

-- The actual frame that receives Blizzard events
E._frame = E._frame or CreateFrame("Frame", "NaptimeUI_EventDriver")

-- ------------------------------------------------------------
-- Internals
-- ------------------------------------------------------------
local function safeCall(fn, event, ...)
    local ok, err = pcall(fn, event, ...)
    if not ok then
        geterrorhandler()(string.format(
            "%s: Event callback error on %s: %s",
            tostring(ADDON), tostring(event), tostring(err)
        ))
    end
end

local function hasAnyHandler(event)
    local t = E._handlers[event]
    if not t then return false end
    for _, enabled in pairs(t) do
        if enabled then
            return true
        end
    end
    return false
end

local function dispatch(event, ...)
    local t = E._handlers[event]
    if not t then return end

    for fn, enabled in pairs(t) do
        if enabled then
            safeCall(fn, event, ...)
        end
    end
end

-- Throttled dispatch: at most once per frame per event (last args win)
local function dispatchThrottled(event, ...)
    if E._pending[event] then
        E._pending[event].args = { ... }
        return
    end

    E._pending[event] = { args = { ... } }
    C_Timer.After(0, function()
        local p = E._pending[event]
        E._pending[event] = nil
        if p then
            dispatch(event, unpack(p.args))
        end
    end)
end

local function eventHasUnitRegistrations(event)
    local evt = E._unitMap[event]
    if not evt then return false end

    for _, unitSet in pairs(evt) do
        if type(unitSet) == "table" and next(unitSet) then
            return true
        end
    end
    return false
end

local function collectUnitsForEvent(event)
    local out = {}
    local seen = {}

    local evt = E._unitMap[event]
    if not evt then
        return out
    end

    for _, unitSet in pairs(evt) do
        if type(unitSet) == "table" then
            for unit in pairs(unitSet) do
                if not seen[unit] then
                    seen[unit] = true
                    out[#out + 1] = unit
                end
            end
        end
    end

    return out
end

local function rebuildFrameRegistration(event)
  if E._frame.IsEventRegistered and E._frame:IsEventRegistered(event) then
  E._frame:UnregisterEvent(event)
end

    if not hasAnyHandler(event) then
        E._handlers[event] = nil
        E._throttle[event] = nil
        E._pending[event] = nil
        E._unitMap[event] = nil
        return
    end

    if eventHasUnitRegistrations(event) then
        local units = collectUnitsForEvent(event)
        if #units > 0 then
            E._frame:RegisterUnitEvent(event, unpack(units))
            return
        end
    end

    E._frame:RegisterEvent(event)
end

local function callbackHasUnitRegistration(event, fn)
    local evt = E._unitMap[event]
    if not evt then return false end
    local units = evt[fn]
    return type(units) == "table" and next(units) ~= nil
end

-- ------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------

-- Register a callback for a standard event.
-- opts = { throttle=true } to coalesce rapid-fire events.
function E:Register(event, fn, opts)
    if type(event) ~= "string" or type(fn) ~= "function" then return end

    E._handlers[event] = E._handlers[event] or {}
    E._handlers[event][fn] = true

    -- If this callback was previously registered as a unit callback for this event,
    -- clear that mapping so this registration is treated as a normal event callback.
    if E._unitMap[event] then
        E._unitMap[event][fn] = nil
        if not next(E._unitMap[event]) then
            E._unitMap[event] = nil
        end
    end

    if opts and opts.throttle then
        E._throttle[event] = true
    end

    rebuildFrameRegistration(event)
end

-- Register a callback for a unit event (e.g., UNIT_AURA on "player").
-- opts = { throttle=true } is supported but avoid it for UNIT_AURA aura-cache logic.
function E:RegisterUnitEvent(event, unit, fn, opts)
    if type(event) ~= "string" or type(unit) ~= "string" or type(fn) ~= "function" then return end

    E._handlers[event] = E._handlers[event] or {}
    E._handlers[event][fn] = true

    E._unitMap[event] = E._unitMap[event] or {}
    E._unitMap[event][fn] = E._unitMap[event][fn] or {}
    E._unitMap[event][fn][unit] = true

    if opts and opts.throttle then
        E._throttle[event] = true
    end

    rebuildFrameRegistration(event)
end

-- Unregister a callback from an event.
function E:Unregister(event, fn)
    local t = E._handlers[event]
    if not t then return end

    t[fn] = nil

    if E._unitMap[event] then
        E._unitMap[event][fn] = nil
        if not next(E._unitMap[event]) then
            E._unitMap[event] = nil
        end
    end

    rebuildFrameRegistration(event)
end

-- Convenience: register a list of events to the same callback
function E:RegisterMany(events, fn, opts)
    if type(events) ~= "table" or type(fn) ~= "function" then return end
    for _, ev in ipairs(events) do
        E:Register(ev, fn, opts)
    end
end

-- Convenience: register a list of unit events to the same callback
function E:RegisterManyUnit(events, unit, fn, opts)
    if type(events) ~= "table" or type(unit) ~= "string" or type(fn) ~= "function" then return end
    for _, ev in ipairs(events) do
        E:RegisterUnitEvent(ev, unit, fn, opts)
    end
end

-- Optional helper: unregister a list of events from the same callback
function E:UnregisterMany(events, fn)
    if type(events) ~= "table" or type(fn) ~= "function" then return end
    for _, ev in ipairs(events) do
        E:Unregister(ev, fn)
    end
end

-- Optional helper: clear all handlers and registrations
function E:Reset()
    for event in pairs(E._handlers) do
        E._frame:UnregisterEvent(event)
    end

    wipe(E._handlers)
    wipe(E._throttle)
    wipe(E._pending)
    wipe(E._unitMap)
end

-- ------------------------------------------------------------
-- Driver
-- ------------------------------------------------------------

E._frame:SetScript("OnEvent", function(_, event, ...)
    if E._throttle[event] then
        dispatchThrottled(event, ...)
    else
        dispatch(event, ...)
    end
end)
