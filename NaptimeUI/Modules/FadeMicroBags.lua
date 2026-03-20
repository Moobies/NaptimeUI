-- Modules/FadeMicroBags.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.FadeMicroBags = ns.Modules.FadeMicroBags or {}
local M = ns.Modules.FadeMicroBags

local Fade = ns.Fade

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

-- Default fade settings (you can override in Config if you want later)
local DEFAULT_CFG = {
    visibility   = "mouseover",
    fadeOutAlpha = 0,
    fadeInAlpha  = 1,
    fadeInTime   = 0.12,
    fadeOutTime  = 0.18,
    fadeOutDelay = 0.10,
}

local function ApplyFadeToFrame(frame, cfg)
    if not (frame and Fade and Fade.Apply) then return end
    Fade:Apply(frame, cfg)
end

local function BindButtons(frame, buttons, cfg)
    if not (frame and Fade and Fade.BindMouseover) then return end
    for _, b in ipairs(buttons) do
        if b then
            Fade:BindMouseover(frame, b, cfg)
        end
    end
end

local function SetupMicro(cfg)
    local bar = _G.MicroMenu
    if not bar then return end

    ApplyFadeToFrame(bar, cfg)

    local buttons = {
        CharacterMicroButton,
        SpellbookMicroButton,
        TalentMicroButton,
        AchievementMicroButton,
        QuestLogMicroButton,
        GuildMicroButton,
        LFDMicroButton,
        CollectionsMicroButton,
        EJMicroButton,
        StoreMicroButton,
        MainMenuMicroButton,
    }

    BindButtons(bar, buttons, cfg)
end

local function FindBagsRoot()
    -- Many builds: backpack is parented to a bags container
    if _G.MainMenuBarBackpackButton and _G.MainMenuBarBackpackButton.GetParent then
        local p = _G.MainMenuBarBackpackButton:GetParent()
        if p and p ~= UIParent then
            return p
        end
    end

    -- Some builds have explicit containers; try common ones
    return _G.BagsBar or _G.BagBar or _G.MainMenuBarBackpackButton
end

local function SetupBags(cfg)
    -- If you don't want bags faded at all, just return here.
    local root = FindBagsRoot()
    if not root then return end

    ApplyFadeToFrame(root, cfg)

    local bagButtons = {
        MainMenuBarBackpackButton,
        CharacterBag0Slot,
        CharacterBag1Slot,
        CharacterBag2Slot,
        CharacterBag3Slot,
    }

    BindButtons(root, bagButtons, cfg)
end

local function ApplyAll()
    if InCombat() then return end
    if not Fade then return end

    -- If you later want per-feature config:
    -- local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    -- local microCfg = (cfg and cfg.microFade) or DEFAULT_CFG
    -- local bagCfg   = (cfg and cfg.bagsFade) or DEFAULT_CFG

    local microCfg = DEFAULT_CFG
    local bagCfg   = DEFAULT_CFG

    SetupMicro(microCfg)
    SetupBags(bagCfg)
end

function M:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local f = CreateFrame("Frame")
    self.__driver = f

    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UI_SCALE_CHANGED")
    f:RegisterEvent("DISPLAY_SIZE_CHANGED")
    f:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")

    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if InCombat() then return end
            C_Timer.After(0, ApplyAll)
            return
        end
        if InCombat() then return end
        C_Timer.After(0, ApplyAll)
    end)

    if not InCombat() then
        C_Timer.After(0, ApplyAll)
    end
end
