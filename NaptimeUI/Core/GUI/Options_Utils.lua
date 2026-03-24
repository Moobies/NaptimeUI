local ADDON, ns = ...
ns = ns or {}

ns.GUI = ns.GUI or {}
ns.GUI.Options = ns.GUI.Options or {}
local O = ns.GUI.Options

local WHITE = "Interface\\Buttons\\WHITE8X8"

O.Const = O.Const or {
    VERSION = "v1.0",
    WIN_W   = 1050,
    WIN_H   = 740,
    SIDE_W  = 200,
    TITLE_H = 50,
    FOOT_H  = 50,
}

O.Colors = O.Colors or {
    bg           = { 1.00, 1.00, 1.00, 1.00 },
    border       = { 0.00, 0.00, 0.00, 1.00 },
    divider      = { 1.00, 1.00, 1.00, 0.10 },
    itemBg       = { 0.12, 0.12, 0.12, 1.00 },
    itemSep      = { 1.00, 1.00, 1.00, 0.10 },
    itemHoverBg  = { 0.12, 0.12, 0.12, 1.00 },
    itemActiveBg = { 1.00, 0.55, 0.00, 1.00 },
    orange       = { 1.00, 0.55, 0.00, 1.00 },
    white        = { 1.00, 1.00, 1.00, 1.00 },
    grey         = { 0.75, 0.75, 0.75, 1.00 },
    black        = { 0.00, 0.00, 0.00, 1.00 },
    btnBg        = { 0.12, 0.12, 0.12, 1.00 },
    btnBorder    = { 0.00, 0.00, 0.00, 1.00 },
}

local C = O.Colors

function O.Tex(parent, layer, sublayer)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sublayer or 0)
    t:SetTexture(WHITE)
    return t
end

function O.FillColor(parent, color, layer, sublayer)
    local t = O.Tex(parent, layer, sublayer)
    t:SetAllPoints(parent)
    t:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    return t
end

function O.Border(frame, color, px)
    px = px or 1
    color = color or C.border

    frame.__nuiSimpleBorder = frame.__nuiSimpleBorder or {}

    local function GetEdge(key)
        local tex = frame.__nuiSimpleBorder[key]
        if not tex then
            tex = frame:CreateTexture(nil, "OVERLAY", nil, 7)
            tex:SetTexture(WHITE)
            frame.__nuiSimpleBorder[key] = tex
        end
        tex:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
        tex:Show()
        return tex
    end

    local top = GetEdge("top")
    top:ClearAllPoints()
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    top:SetHeight(px)

    local bottom = GetEdge("bottom")
    bottom:ClearAllPoints()
    bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(px)

    local left = GetEdge("left")
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    left:SetWidth(px)

    local right = GetEdge("right")
    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(px)
end

function O.ApplyBorder(frame, color, px)
    if ns.Border and ns.Border.Apply then
        ns.Border:Apply(frame, px or 1, color or C.border)
    else
        O.Border(frame, color or C.border, px or 1)
    end
end

function O.FS(parent, size, text, color, outline, fontKey)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    local fontPath = (ns.GetFont and ns:GetFont(fontKey or "Default")) or "Fonts\\FRIZQT__.TTF"
    fs:SetFont(fontPath, size or 12, outline ~= false and "OUTLINE" or "")
    fs:SetText(text or "")
    if color then
        fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    end
    return fs
end

function O.MakeButton(parent, w, h, label, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, h)

    local bg = O.FillColor(btn, C.btnBg, "BACKGROUND", 0)
    O.ApplyBorder(btn, C.btnBorder, 1)

    local lbl = O.FS(btn, 12, label, C.white, true, "Primary")
    lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)

    btn:SetScript("OnEnter", function()
        bg:SetVertexColor(C.orange[1], C.orange[2], C.orange[3], 1)
        lbl:SetTextColor(C.black[1], C.black[2], C.black[3], 1)
    end)

    btn:SetScript("OnLeave", function()
        bg:SetVertexColor(C.btnBg[1], C.btnBg[2], C.btnBg[3], 1)
        lbl:SetTextColor(C.white[1], C.white[2], C.white[3], 1)
    end)

    btn:SetScript("OnClick", onClick or function() end)
    return btn
end

function O.MakeSidebarItem(parent, label, onClick)
    local H = 38

    local item = CreateFrame("Button", nil, parent)
    item:SetHeight(H)
    item:SetPoint("LEFT", parent, "LEFT", 0, 0)
    item:SetPoint("RIGHT", parent, "RIGHT", 0, 0)

    local bg = O.FillColor(item, C.itemBg, "BACKGROUND", 0)

    local sep = O.Tex(item, "OVERLAY", 3)
    sep:SetHeight(1)
    sep:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", 0, 0)
    sep:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", 0, 0)
    sep:SetVertexColor(C.itemSep[1], C.itemSep[2], C.itemSep[3], 1)

    local bTop = O.Tex(item, "OVERLAY", 6)
    bTop:SetHeight(1)
    bTop:SetPoint("TOPLEFT", item, "TOPLEFT", 0, 0)
    bTop:SetPoint("TOPRIGHT", item, "TOPRIGHT", 0, 0)
    bTop:Hide()

    local bBot = O.Tex(item, "OVERLAY", 6)
    bBot:SetHeight(1)
    bBot:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", 0, 0)
    bBot:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", 0, 0)
    bBot:Hide()

    local bLeft = O.Tex(item, "OVERLAY", 6)
    bLeft:SetWidth(1)
    bLeft:SetPoint("TOPLEFT", item, "TOPLEFT", 0, 0)
    bLeft:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", 0, 0)
    bLeft:Hide()

    local bRight = O.Tex(item, "OVERLAY", 6)
    bRight:SetWidth(1)
    bRight:SetPoint("TOPRIGHT", item, "TOPRIGHT", 0, 0)
    bRight:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", 0, 0)
    bRight:Hide()

    local borders = { bTop, bBot, bLeft, bRight }

    local function SetBorderColor(r, g, b, a)
        for _, t in ipairs(borders) do
            t:SetVertexColor(r, g, b, a or 1)
            t:Show()
        end
    end

    local function HideBorder()
        for _, t in ipairs(borders) do
            t:Hide()
        end
    end

    local lbl = O.FS(item, 14, label, C.white, true, "Primary")
    lbl:SetPoint("LEFT", item, "LEFT", 14, 0)

    item.__active = false

    function item:SetActive(active)
        self.__active = active
        if active then
            bg:SetVertexColor(C.itemActiveBg[1], C.itemActiveBg[2], C.itemActiveBg[3], 1)
            lbl:SetTextColor(C.white[1], C.white[2], C.white[3], 1)
            SetBorderColor(C.black[1], C.black[2], C.black[3], 1)
        else
            bg:SetVertexColor(C.itemBg[1], C.itemBg[2], C.itemBg[3], 1)
            lbl:SetTextColor(C.white[1], C.white[2], C.white[3], 1)
            HideBorder()
        end
    end

    item:SetScript("OnEnter", function(self)
        if not self.__active then
            bg:SetVertexColor(C.itemBg[1], C.itemBg[2], C.itemBg[3], 1)
            lbl:SetTextColor(C.white[1], C.white[2], C.white[3], 1)
            SetBorderColor(C.orange[1], C.orange[2], C.orange[3], 1)
        end
    end)

    item:SetScript("OnLeave", function(self)
        if not self.__active then
            bg:SetVertexColor(C.itemBg[1], C.itemBg[2], C.itemBg[3], 1)
            lbl:SetTextColor(C.white[1], C.white[2], C.white[3], 1)
            HideBorder()
        end
    end)

    item:SetScript("OnClick", function(self)
        if onClick then
            onClick(self)
        end
    end)

    return item
end
