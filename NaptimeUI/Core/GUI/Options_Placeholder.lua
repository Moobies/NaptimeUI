local ADDON, ns = ...
ns = ns or {}

ns.GUI = ns.GUI or {}
ns.GUI.Options = ns.GUI.Options or {}
local O = ns.GUI.Options

local C = O.Colors

function O.BuildPlaceholderPage(parent, title)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)
    page:Hide()

    local lbl = O.FS(page, 16, title .. "\n|cff555555Coming soon.|r", C.grey, true, "Primary")
    lbl:SetPoint("CENTER", page, "CENTER", 0, 0)
    lbl:SetJustifyH("CENTER")

    return page
end
