-- Core/KillBlizz.lua (safer)
local ADDON, ns = ...
ns = ns or {}
ns.KillBlizz = ns.KillBlizz or {}
local K = ns.KillBlizz

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function NoMouse(f)
    if not f then return end
    if f.EnableMouse then pcall(f.EnableMouse, f, false) end
    if f.EnableMouseWheel then pcall(f.EnableMouseWheel, f, false) end
end

local function SoftHideFrame(f)
    if not f then return end
    NoMouse(f)
    if f.SetAlpha then pcall(f.SetAlpha, f, 0) end

    -- Don’t Hide() big frames; it can be protected/taint-sensitive.
    if f.HookScript and not f.__nolSoftHideHooked then
        f:HookScript("OnShow", function(self)
            NoMouse(self)
            if self.SetAlpha then pcall(self.SetAlpha, self, 0) end
        end)
        f.__nolSoftHideHooked = true
    end
end

local function SoftHideTexture(t)
    if not t then return end
    if t.SetAlpha then pcall(t.SetAlpha, t, 0) end
    if t.Hide then pcall(t.Hide, t) end
    if t.SetTexture then pcall(t.SetTexture, t, nil) end
    if t.SetAtlas then pcall(t.SetAtlas, t, nil) end
end

local function HideEditModeSelections()
    if not EditModeManagerFrame then return end

    for _, f in ipairs({ EditModeManagerFrame:GetChildren() }) do
        if f and f.GetName and f:GetName() then
            local name = f:GetName()
            if name:find("Selection") or name:find("MouseOverHighlight") then
                if f.SetAlpha then f:SetAlpha(0) end
                if f.EnableMouse then f:EnableMouse(false) end
            end
        end
    end
end

-- -------------------------------------------------------
-- EDIT MODE: remove the blue movers for systems we replace
-- -------------------------------------------------------
local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return end
    pcall(fn, ...)
end

local function DisableEditModeForReplacedSystems()
    if not EditModeManagerFrame then return end

    local unregister = EditModeManagerFrame.UnregisterSystem
    if type(unregister) ~= "function" then return end

    -- Try a bunch of common system keys (varies by build); SafeCall prevents errors.
    -- Action bars / multibars
    SafeCall(unregister, EditModeManagerFrame, "ActionBar")
    SafeCall(unregister, EditModeManagerFrame, "MainActionBar")
    SafeCall(unregister, EditModeManagerFrame, "MultiBarBottomLeft")
    SafeCall(unregister, EditModeManagerFrame, "MultiBarBottomRight")
    SafeCall(unregister, EditModeManagerFrame, "MultiBarRight")
    SafeCall(unregister, EditModeManagerFrame, "MultiBarLeft")
    SafeCall(unregister, EditModeManagerFrame, "StanceBar")
    SafeCall(unregister, EditModeManagerFrame, "PetActionBar")
    SafeCall(unregister, EditModeManagerFrame, "ExtraActionBar")

    -- Auras
    SafeCall(unregister, EditModeManagerFrame, "BuffsAndDebuffs")
    SafeCall(unregister, EditModeManagerFrame, "AuraFrame")
    SafeCall(unregister, EditModeManagerFrame, "BuffFrame")
    SafeCall(unregister, EditModeManagerFrame, "DebuffFrame")

    -- Minimap
    SafeCall(unregister, EditModeManagerFrame, "Minimap")
    SafeCall(unregister, EditModeManagerFrame, "MinimapCluster")

    -- Cooldown manager / viewers (newer UI)
    SafeCall(unregister, EditModeManagerFrame, "CooldownManager")
    SafeCall(unregister, EditModeManagerFrame, "CooldownViewer")
end

local function HideHostsWhileInEditMode()
    if not EditModeManagerFrame or EditModeManagerFrame.__nolKillBlizzHooked then return end
    EditModeManagerFrame.__nolKillBlizzHooked = true

    local function HideHosts()
        -- If you replaced these with your own containers,
        -- hiding the host frames makes the blue movers irrelevant.
        if _G.MainMenuBar then _G.MainMenuBar:SetAlpha(0) end
        if _G.MultiBarBottomLeft then _G.MultiBarBottomLeft:SetAlpha(0) end
        if _G.MultiBarBottomRight then _G.MultiBarBottomRight:SetAlpha(0) end
        if _G.MultiBarRight then _G.MultiBarRight:SetAlpha(0) end
        if _G.MultiBarLeft then _G.MultiBarLeft:SetAlpha(0) end

        if _G.BuffFrame then _G.BuffFrame:SetAlpha(0) end
        if _G.DebuffFrame then _G.DebuffFrame:SetAlpha(0) end

        if _G.MinimapCluster then _G.MinimapCluster:SetAlpha(0) end
    end

    if EditModeManagerFrame.EnterEditMode then
        hooksecurefunc(EditModeManagerFrame, "EnterEditMode", HideHosts)
    end
    if EditModeManagerFrame.UpdateSystems then
        hooksecurefunc(EditModeManagerFrame, "UpdateSystems", HideHosts)
    end
end



local function TryDisableBarArt()
    if InCombat() then return end

    -- These names vary between versions; /fstack the thing stealing clicks and add it here.
    local candidates = {
        "MainActionBar",
        "MainMenuBar",
        "MainMenuBarArtFrame",
        "MainMenuBarArtFrameBackground",
        "StatusTrackingBarManager",
    }

    for _, name in ipairs(candidates) do
        SoftHideFrame(_G[name])
    end

    -- If MainActionBar exists, also try common art fields safely.
    local bar = _G.MainActionBar
    if bar then
        NoMouse(bar)
        SoftHideFrame(bar.BorderArt)
        SoftHideFrame(bar.EndCaps)
        SoftHideFrame(bar.ActionBarPageNumber)
        SoftHideFrame(bar.Center)
        SoftHideFrame(bar.LeftEndCap)
        SoftHideFrame(bar.RightEndCap)

        SoftHideTexture(bar.BottomEdge)
        SoftHideTexture(bar.TopEdge)
        SoftHideTexture(bar.LeftEdge)
        SoftHideTexture(bar.RightEdge)
    end
end

local function Burst()
    TryDisableBarArt()

    -- Edit Mode blue movers: disable systems + hide host frames during edit mode
    DisableEditModeForReplacedSystems()
    HideHostsWhileInEditMode()

    HideEditModeSelections()

C_Timer.After(0.10, HideEditModeSelections)
C_Timer.After(0.30, HideEditModeSelections)

    if C_Timer and C_Timer.After then
        C_Timer.After(0.00, TryDisableBarArt)
        C_Timer.After(0.05, TryDisableBarArt)
        C_Timer.After(0.20, TryDisableBarArt)
        C_Timer.After(0.60, TryDisableBarArt)
        C_Timer.After(1.20, TryDisableBarArt)

        -- Also re-run EditMode cleanup after things finish creating
        C_Timer.After(0.20, DisableEditModeForReplacedSystems)
        C_Timer.After(0.20, HideHostsWhileInEditMode)
        C_Timer.After(1.00, DisableEditModeForReplacedSystems)
    end
end

function K:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local f = CreateFrame("Frame")
    self.__driver = f

    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
    f:RegisterEvent("UI_SCALE_CHANGED")
    f:RegisterEvent("DISPLAY_SIZE_CHANGED")
    f:RegisterEvent("ACTIONBAR_PAGE_CHANGED")

    f:SetScript("OnEvent", function(_, event)
        if InCombat() then
            f:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        end
        Burst()
    end)

    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    Burst()
end

function ns:InitKillBlizz()
    if ns.KillBlizz and ns.KillBlizz.Enable then
        ns.KillBlizz:Enable()
    end
end
