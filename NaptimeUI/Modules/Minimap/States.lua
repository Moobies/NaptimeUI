-- Modules/Minimap/States.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.MinimapStates = ns.Modules.MinimapStates or {}
local S = ns.Modules.MinimapStates

S.__queueReady = S.__queueReady or false

local function GetRootCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    return (type(cfg) == "table") and cfg or nil
end

local function GetCfg()
    local cfg = GetRootCfg()
    if not cfg then return nil end
    return (type(cfg.minimap) == "table") and cfg.minimap or nil
end

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function GetMinimap()
    return _G.Minimap
end

local function GetQueueButton()
    return _G.QueueStatusButton
        or _G.QueueStatusMinimapButton
        or (_G.MinimapCluster and _G.MinimapCluster.IndicatorFrame and _G.MinimapCluster.IndicatorFrame.QueueStatusButton)
end

local function RaiseAboveMinimap(elem, mm, extraLevel)
    if not elem or not mm then return end
    extraLevel = extraLevel or 60

    if elem.SetFrameStrata then
        pcall(elem.SetFrameStrata, elem, "MEDIUM")
    end
    if elem.SetFrameLevel and mm.GetFrameLevel then
        pcall(elem.SetFrameLevel, elem, (mm:GetFrameLevel() or 0) + extraLevel)
    end
end

local function Restore(obj)
    if not obj then return end
    obj.__nolKilled = nil
    if obj.SetScale then pcall(obj.SetScale, obj, 1) end
    if obj.SetAlpha then pcall(obj.SetAlpha, obj, 1) end
    if obj.SetShown then pcall(obj.SetShown, obj, true) end
    if obj.Show then pcall(obj.Show, obj) end
end

local function HideObject(obj)
    if not obj then return end
    if obj.SetAlpha then pcall(obj.SetAlpha, obj, 0) end
    if obj.Hide then pcall(obj.Hide, obj) end
    if obj.SetShown then pcall(obj.SetShown, obj, false) end
end

local function PlaceElementNoParent(elem, parent, cfgElem)
    if not elem or not parent then return end

    if cfgElem and cfgElem.hide == true then
        HideObject(elem)
        return
    end

    Restore(elem)

    local p  = (cfgElem and cfgElem.point) or "TOPRIGHT"
    local rp = (cfgElem and cfgElem.relPoint) or p
    local x  = tonumber(cfgElem and cfgElem.x) or 0
    local y  = tonumber(cfgElem and cfgElem.y) or 0

    if elem.ClearAllPoints and elem.SetPoint then
        elem:ClearAllPoints()
        elem:SetPoint(p, parent, rp, x, y)
    end

    RaiseAboveMinimap(elem, parent, 70)
end

local function ResetQueueButton(btn)
    if not btn then return end

    local cfg = GetCfg() or {}
    local scale = tonumber(cfg.queueScale) or 1

    Restore(btn)

    if btn.SetScale then
        pcall(btn.SetScale, btn, 1)
    end

    local icon = _G.QueueStatusButtonIcon
        or btn.Icon
        or btn.icon

    if icon then
        if icon.SetScale then
            pcall(icon.SetScale, icon, scale)
        end

        if icon.ClearAllPoints and icon.SetPoint then
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        end

        if icon.SetAlpha then pcall(icon.SetAlpha, icon, 1) end
        if icon.Show then pcall(icon.Show, icon) end
    end
end

local function OpenCalendar()
    if ToggleCalendar then
        pcall(ToggleCalendar)
        return
    end
    if TimeManager_Toggle then
        pcall(TimeManager_Toggle)
    end
end

local function ApplyClicks()
    local mm = GetMinimap()
    if not mm or mm.__nolMinimapClicksApplied then return end
    mm.__nolMinimapClicksApplied = true

    if mm.EnableMouse then
        pcall(mm.EnableMouse, mm, true)
    end

    if mm.RegisterForClicks then
        pcall(mm.RegisterForClicks, mm, "LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    end

    mm:HookScript("OnMouseUp", function(_, button)
        if button == "MiddleButton" then
            OpenCalendar()
        end
    end)
end

local function ApplyStatefulElements()
    local mm = GetMinimap()
    local cfg = GetCfg()
    if not mm or not cfg then return end
    if InCombat() then return end

    do
        local queueBtn = GetQueueButton()
        if queueBtn then
            if not S.__queueReady then
                HideObject(queueBtn)
            else
                if cfg.queue and cfg.queue.hide == true then
                    HideObject(queueBtn)
                elseif queueBtn:IsShown() then
                    ResetQueueButton(queueBtn)
                    PlaceElementNoParent(queueBtn, mm, cfg.queue)
                    RaiseAboveMinimap(queueBtn, mm, 72)
                end
            end
        end
    end
end

function S:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local function Refresh()
        if InCombat() then return end
        ApplyClicks()
        ApplyStatefulElements()
    end

    if ns.Events then
        local E = ns.Events
        E:RegisterMany({
            "PLAYER_LOGIN",
            "PLAYER_ENTERING_WORLD",
            "PLAYER_REGEN_ENABLED",
            "LFG_UPDATE",
            "GROUP_ROSTER_UPDATE",
            "UPDATE_BATTLEFIELD_STATUS",
        }, function(event)
            if event == "LFG_UPDATE"
                or event == "GROUP_ROSTER_UPDATE"
                or event == "UPDATE_BATTLEFIELD_STATUS"
            then
                S.__queueReady = true
            end

            C_Timer.After(0, Refresh)
            C_Timer.After(0.10, Refresh)
            C_Timer.After(0.30, Refresh)
        end, { throttle = true })
    else
        local f = CreateFrame("Frame")
        self.__driver = f
        f:RegisterEvent("PLAYER_LOGIN")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
        f:RegisterEvent("LFG_UPDATE")
        f:RegisterEvent("GROUP_ROSTER_UPDATE")
        f:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
        f:SetScript("OnEvent", function(_, event)
            if event == "LFG_UPDATE"
                or event == "GROUP_ROSTER_UPDATE"
                or event == "UPDATE_BATTLEFIELD_STATUS"
            then
                S.__queueReady = true
            end

            C_Timer.After(0, Refresh)
            C_Timer.After(0.10, Refresh)
            C_Timer.After(0.30, Refresh)
        end)
    end

    C_Timer.After(0, Refresh)
    C_Timer.After(0.10, Refresh)
    C_Timer.After(0.30, Refresh)
end
