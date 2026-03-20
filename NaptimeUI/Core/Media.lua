local ADDON, ns = ...

ns.Media = ns.Media or {}

local ROOT = ("Interface\\AddOns\\%s\\Core\\"):format(ADDON)

ns.Media.fonts = {
    Primary   = ROOT .. "Media\\NapFredoka.ttf",
    Secondary = ROOT .. "Media\\NapPixel.ttf",
    Default   = "Fonts\\FRIZQT__.TTF",
}

ns.Media.textures = {
    White = "Interface\\Buttons\\WHITE8X8",
    Shadow = ROOT .. "Media\\NapShadow.tga",
}

ns.Media.icons = {
    Mail = ROOT .. "Media\\mail.tga",
}

function ns:GetFont(key)
    return (ns.Media.fonts and ns.Media.fonts[key]) or ns.Media.fonts.Default
end
