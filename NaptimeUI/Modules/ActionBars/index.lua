-- Modules/ActionBars/index.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.ActionBars = ns.Modules.ActionBars or {}
local AB = ns.Modules.ActionBars

function AB:Enable()
    if self.__enabled then return end
    self.__enabled = true

    if AB.ButtonText and AB.ButtonText.Enable then AB.ButtonText:Enable() end
    if AB.Layout and AB.Layout.Enable then AB.Layout:Enable() end
    if AB.Fade and AB.Fade.Enable then AB.Fade:Enable() end
end
