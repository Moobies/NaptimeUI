-- Core/SkinBase.lua
-- Handles stripping Blizzard's default UI art and action button textures
local ADDON, ns = ...
ns = ns or {}

-- ================================================================
-- ns.ButtonArt — strips default art from action buttons
-- ================================================================

ns.ButtonArt = ns.ButtonArt or {}
local A = ns.ButtonArt

local function KillTexture(tex)
    if not tex then return end
    if tex.SetTexture then pcall(tex.SetTexture, tex, nil) end
    if tex.SetAtlas   then pcall(tex.SetAtlas,   tex, nil) end
    if tex.SetAlpha   then pcall(tex.SetAlpha,   tex, 0)   end
    if tex.Hide       then pcall(tex.Hide,        tex)      end
end

local function HookKeepHidden(region)
    if not region or region.__nolKeepHidden then return end
    region.__nolKeepHidden = true

    if region.HookScript then
        pcall(region.HookScript, region, "OnShow", function(self)
            KillTexture(self)
        end)
    end
end

local function KillAndHook(tex)
    KillTexture(tex)
    HookKeepHidden(tex)
end

local function KillByNameIfMatches(btn, region)
    if not region or not region.GetName then return end
    local n = region:GetName()
    if not n then return end

    if n:find("Border") or
       n:find("Shadow") or
       n:find("Slot") or
       n:find("Floating") or
       n:find("Divider") or
       n:find("Frame") and n:find("Art") then
        KillAndHook(region)
    end
end

function A:StripActionButton(btn)
    if not btn or btn.__nolArtStripped then return end
    btn.__nolArtStripped = true

    if btn.SetShowButtonArt   then pcall(btn.SetShowButtonArt,   btn, false) end
    btn.showButtonArt = false

    if btn.SetNormalTexture   then pcall(btn.SetNormalTexture,   btn, nil) end
    if btn.SetPushedTexture   then pcall(btn.SetPushedTexture,   btn, nil) end
    if btn.SetCheckedTexture  then pcall(btn.SetCheckedTexture,  btn, nil) end
    if btn.SetDisabledTexture then pcall(btn.SetDisabledTexture, btn, nil) end
    if btn.SetHighlightTexture then pcall(btn.SetHighlightTexture, btn, nil) end

    local killList = {
        btn.Border,            btn.BorderShadow,
        btn.SlotArt,           btn.SlotBackground,
        btn.IconBorder,        btn.FloatingBG,
        btn.FlyoutBorder,      btn.FlyoutBorderShadow,
        btn.RightDivider,      btn.LeftDivider,
        btn.NewActionTexture,  btn.SpellHighlightTexture,
        btn.Flash,             btn.AutoCastable,
        btn.AutoCastOverlay,
    }
    for _, r in ipairs(killList) do
        if r then KillAndHook(r) end
    end

    if btn.GetNormalTexture   then KillAndHook(btn:GetNormalTexture())   end
    if btn.GetCheckedTexture  then KillAndHook(btn:GetCheckedTexture())  end
    if btn.GetDisabledTexture then KillAndHook(btn:GetDisabledTexture()) end
    if btn.GetHighlightTexture then KillAndHook(btn:GetHighlightTexture()) end

    if btn.IconMask and btn.IconMask.Hide then
        pcall(btn.IconMask.Hide, btn.IconMask)
    end

    if btn.GetRegions then
        for i = 1, select("#", btn:GetRegions()) do
            local r = select(i, btn:GetRegions())
            if r and r.GetObjectType and r:GetObjectType() == "Texture" then
                KillByNameIfMatches(btn, r)
            end
        end
    end

    if not btn.__nolHookedUpdate then
        btn.__nolHookedUpdate = true

        if btn.HookScript then
            pcall(btn.HookScript, btn, "OnShow", function(self)
                A:StripActionButton(self)
            end)
        end

        if btn.UpdateButtonArt then
            hooksecurefunc(btn, "UpdateButtonArt", function(self)
                A:StripActionButton(self)
            end)
        end
    end
end

function A:Strip(btn)
    return self:StripActionButton(btn)
end

-- ================================================================
-- ns.KillBlizz — hides Blizzard's default bar art and UI chrome
-- ================================================================

ns.KillBlizz = ns.KillBlizz or {}
local K = ns.KillBlizz

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function NoMouse(f)
    if not f then return end
    if f.EnableMouse      then pcall(f.EnableMouse,      f, false) end
    if f.EnableMouseWheel then pcall(f.EnableMouseWheel, f, false) end
end

local function SoftHideFrame(f)
    if not f then return end
    NoMouse(f)
    if f.SetAlpha then pcall(f.SetAlpha, f, 0) end

    if f.HookScript and not f.__nolSoftHideHooked then
        f.__nolSoftHideHooked = true
        f:HookScript("OnShow", function(self)
            NoMouse(self)
            if self.SetAlpha then pcall(self.SetAlpha, self, 0) end
        end)
    end
end

local function SoftHideTexture(t)
    if not t then return end
    if t.SetAlpha   then pcall(t.SetAlpha,   t, 0)   end
    if t.Hide       then pcall(t.Hide,        t)      end
    if t.SetTexture then pcall(t.SetTexture,  t, nil) end
    if t.SetAtlas   then pcall(t.SetAtlas,    t, nil) end
end

local function HideEditModeSelections()
    if not EditModeManagerFrame then return end

    for _, f in ipairs({ EditModeManagerFrame:GetChildren() }) do
        if f and f.GetName and f:GetName() then
            local name = f:GetName()
            if name:find("Selection") or name:find("MouseOverHighlight") then
                if f.SetAlpha    then f:SetAlpha(0)         end
                if f.EnableMouse then f:EnableMouse(false)  end
            end
        end
    end
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return end
    pcall(fn, ...)
end

local function DisableEditModeForReplacedSystems()
    if not EditModeManagerFrame then return end

    local unregister = EditModeManagerFrame.UnregisterSystem
    if type(unregister) ~= "function" then return end

    local systems = {
        "ActionBar", "MainActionBar",
        "MultiBarBottomLeft", "MultiBarBottomRight",
        "MultiBarRight", "MultiBarLeft",
        "StanceBar", "PetActionBar", "ExtraActionBar",
        "BuffsAndDebuffs", "AuraFrame", "BuffFrame", "DebuffFrame",
        "Minimap", "MinimapCluster",
        "CooldownManager", "CooldownViewer",
    }

    for _, key in ipairs(systems) do
        SafeCall(unregister, EditModeManagerFrame, key)
    end
end

local function HideHostsWhileInEditMode()
    if not EditModeManagerFrame or EditModeManagerFrame.__nolKillBlizzHooked then return end
    EditModeManagerFrame.__nolKillBlizzHooked = true

    local function HideHosts()
        if _G.MainMenuBar       then _G.MainMenuBar:SetAlpha(0)       end
        if _G.MultiBarBottomLeft  then _G.MultiBarBottomLeft:SetAlpha(0)  end
        if _G.MultiBarBottomRight then _G.MultiBarBottomRight:SetAlpha(0) end
        if _G.MultiBarRight     then _G.MultiBarRight:SetAlpha(0)     end
        if _G.MultiBarLeft      then _G.MultiBarLeft:SetAlpha(0)      end
        if _G.BuffFrame         then _G.BuffFrame:SetAlpha(0)         end
        if _G.DebuffFrame       then _G.DebuffFrame:SetAlpha(0)       end
        if _G.MinimapCluster    then _G.MinimapCluster:SetAlpha(0)    end
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
    DisableEditModeForReplacedSystems()
    HideHostsWhileInEditMode()
    HideEditModeSelections()

    C_Timer.After(0.00, TryDisableBarArt)
    C_Timer.After(0.05, TryDisableBarArt)
    C_Timer.After(0.10, HideEditModeSelections)
    C_Timer.After(0.20, TryDisableBarArt)
    C_Timer.After(0.20, DisableEditModeForReplacedSystems)
    C_Timer.After(0.20, HideHostsWhileInEditMode)
    C_Timer.After(0.30, HideEditModeSelections)
    C_Timer.After(0.60, TryDisableBarArt)
    C_Timer.After(1.00, DisableEditModeForReplacedSystems)
    C_Timer.After(1.20, TryDisableBarArt)
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
    f:RegisterEvent("PLAYER_REGEN_ENABLED")

    f:SetScript("OnEvent", function(_, event)
        if InCombat() then
            f:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        end
        Burst()
    end)

    Burst()
end

function ns:InitKillBlizz()
    if ns.KillBlizz and ns.KillBlizz.Enable then
        ns.KillBlizz:Enable()
    end
end
