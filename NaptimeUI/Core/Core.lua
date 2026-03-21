local ADDON, ns = ...
ns = ns or {}

local function SafeCall(name, fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        print("|cffff5555NOL error in "..name..":|r", err)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()

    -- Options panel
    if ns.Options and ns.Options.Enable then
      SafeCall("Options", ns.Options.Enable, ns.Options)
    end

    -- Kill Blizzard bar art + mouse blocking (click-through)
    if ns.KillBlizz and ns.KillBlizz.Enable then
        SafeCall("KillBlizz", ns.KillBlizz.Enable, ns.KillBlizz)
    end

    -- Actionbar States
    if ns.Modules and ns.Modules.ActionBarStates and ns.Modules.ActionBarStates.Enable then
        ns.Modules.ActionBarStates:Enable()
    end

    -- ActionBars
    if ns.Modules and ns.Modules.ActionBars and ns.Modules.ActionBars.Enable then
        SafeCall("ActionBars", ns.Modules.ActionBars.Enable, ns.Modules.ActionBars)
    end

    -- Auras
    if ns.Modules and ns.Modules.Auras and ns.Modules.Auras.Enable then
        SafeCall("Auras", ns.Modules.Auras.Enable, ns.Modules.Auras)
    end

    -- Init Fade
    if ns.Modules and ns.Modules.FadeMicroBags and ns.Modules.FadeMicroBags.Enable then
    SafeCall("FadeMicroBags", ns.Modules.FadeMicroBags.Enable, ns.Modules.FadeMicroBags)
    end

    -- init Skins
    if ns.Skins and ns.Skins.Tooltip and ns.Skins.Tooltip.Enable then
    SafeCall("Tooltip", ns.Skins.Tooltip.Enable, ns.Skins.Tooltip)
    end

    -- init minimap
  if ns.Modules and ns.Modules.Minimap and ns.Modules.Minimap.Enable then
      SafeCall("Minimap", ns.Modules.Minimap.Enable, ns.Modules.Minimap)
  end

  -- init minimap states
  if ns.Modules and ns.Modules.MinimapStates and ns.Modules.MinimapStates.Enable then
      SafeCall("MinimapStates", ns.Modules.MinimapStates.Enable, ns.Modules.MinimapStates)
  end

    -- init XP bar
    if ns.Modules and ns.Modules.XPBar and ns.Modules.XPBar.Enable then
    SafeCall("XPBar", ns.Modules.XPBar.Enable, ns.Modules.XPBar)
    end

    -- Cooldown Manager
    if ns:IsModuleEnabled("cooldownManager") then
        if ns.Modules and ns.Modules.CooldownManager and ns.Modules.CooldownManager.Enable then
            SafeCall("CooldownManager", ns.Modules.CooldownManager.Enable, ns.Modules.CooldownManager)
        end
    end

    -- Vehicle Exit
    if ns.Modules and ns.Modules.VehicleExit and ns.Modules.VehicleExit.Enable then
    ns.Modules.VehicleExit:Enable()
    end

    -- Flyout Menu
    if ns.Modules and ns.Modules.SpellFlyoutSkin and ns.Modules.SpellFlyoutSkin.Enable then
    ns.Modules.SpellFlyoutSkin:Enable()
    end

    -- Minmap Mail Icon
    if ns.Modules and ns.Modules.MinimapMail and ns.Modules.MinimapMail.Enable then
    SafeCall("MinimapMail", ns.Modules.MinimapMail.Enable, ns.Modules.MinimapMail)
    end

    -- Chat Style
    if ns.Modules and ns.Modules.ChatStyle and ns.Modules.ChatStyle.Enable then
    SafeCall("ChatStyle", ns.Modules.ChatStyle.Enable, ns.Modules.ChatStyle)
    end




  end)

print("|cff88ff88NaptimeUI|r loaded.")
