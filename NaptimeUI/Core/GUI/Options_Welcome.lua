local ADDON, ns = ...
ns = ns or {}

ns.GUI = ns.GUI or {}
ns.GUI.Options = ns.GUI.Options or {}
local O = ns.GUI.Options

local C = O.Colors
local VERSION = O.Const.VERSION

function O.BuildWelcomePage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)
    page:Hide()

    local logo = page:CreateTexture(nil, "ARTWORK")
    logo:SetSize(360, 360)
    logo:SetPoint("CENTER", page, "CENTER", 0, 30)

    if ns.Media and ns.Media.textures and ns.Media.textures.Nui then
        logo:SetTexture(ns.Media.textures.Nui)
    end

    local ver = O.FS(page, 13, VERSION, C.orange, true, "Primary")
    ver:SetPoint("TOP", logo, "BOTTOM", 0, -6)

    local div = O.Tex(page, "ARTWORK", 1)
    div:SetHeight(1)
    div:SetVertexColor(C.orange[1], C.orange[2], C.orange[3], 0.3)
    div:SetPoint("TOPLEFT", page, "CENTER", -140, -40)
    div:SetPoint("TOPRIGHT", page, "CENTER", 140, -40)

    local msg = O.FS(page, 13, "Welcome! Use the sidebar to configure your UI.", C.grey, true, "Primary")
    msg:SetPoint("TOP", div, "BOTTOM", 0, -16)

    return page
end
