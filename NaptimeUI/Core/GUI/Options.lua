local ADDON, ns = ...
ns = ns or {}

ns.GUI = ns.GUI or {}
ns.GUI.Options = ns.GUI.Options or {}
local O = ns.GUI.Options

ns.Options = O

local function BuildWindow()
    if O.window then
        return O.window
    end

    local win = CreateFrame("Frame", "NaptimeUI_OptionsWindow", UIParent)
    win:SetSize(740, 500)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetFrameLevel(100)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:SetClampedToScreen(true)
    win:Hide()

    -- -------------------------------------------------------
    -- Base background
    -- -------------------------------------------------------
    if O.FillColor then
        O.FillColor(win, { 0.039, 0.039, 0.039, 1 }, "BACKGROUND", -1)
    else
        local bg = win:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(0.039, 0.039, 0.039, 1)
    end

    -- -------------------------------------------------------
    -- Base border
    -- -------------------------------------------------------
    if O.ApplyBorder then
        O.ApplyBorder(win, { 0, 0, 0, 1 }, 1)
    else
        local function MakeEdge()
            local t = win:CreateTexture(nil, "OVERLAY")
            t:SetTexture("Interface\\Buttons\\WHITE8X8")
            t:SetVertexColor(0.176, 0.176, 0.176, 1)
            return t
        end

        local top = MakeEdge()
        top:SetPoint("TOPLEFT")
        top:SetPoint("TOPRIGHT")
        top:SetHeight(1)

        local bottom = MakeEdge()
        bottom:SetPoint("BOTTOMLEFT")
        bottom:SetPoint("BOTTOMRIGHT")
        bottom:SetHeight(1)

        local left = MakeEdge()
        left:SetPoint("TOPLEFT")
        left:SetPoint("BOTTOMLEFT")
        left:SetWidth(1)

        local right = MakeEdge()
        right:SetPoint("TOPRIGHT")
        right:SetPoint("BOTTOMRIGHT")
        right:SetWidth(1)
    end

    -- -------------------------------------------------------
    -- Guide lines
    -- -------------------------------------------------------
    local TOP_LINE_Y = 60
    local BOTTOM_LINE_Y = 60
    local VLINE_X = 181
    local TOP_INSET = 60
    local BOTTOM_INSET = 60

    local topLine = win:CreateTexture(nil, "ARTWORK")
    topLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    topLine:SetVertexColor(0.176, 0.176, 0.176, 1)
    topLine:SetHeight(1)
    topLine:SetPoint("TOPLEFT", win, "TOPLEFT", 0, -TOP_LINE_Y)
    topLine:SetPoint("TOPRIGHT", win, "TOPRIGHT", 0, -TOP_LINE_Y)

    local bottomLine = win:CreateTexture(nil, "ARTWORK")
    bottomLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    bottomLine:SetVertexColor(0.176, 0.176, 0.176, 1)
    bottomLine:SetHeight(1)
    bottomLine:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 0, BOTTOM_LINE_Y)
    bottomLine:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", 0, BOTTOM_LINE_Y)

    local vLine = win:CreateTexture(nil, "ARTWORK")
    vLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    vLine:SetVertexColor(0.176, 0.176, 0.176, 1)
    vLine:SetWidth(1)
    vLine:SetPoint("TOPLEFT", win, "TOPLEFT", VLINE_X, -TOP_INSET)
    vLine:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", VLINE_X, BOTTOM_INSET)

    -- -------------------------------------------------------
    -- Title text
    -- -------------------------------------------------------
    local TITLE_SIZE = 32
    local TITLE_X = 20
    local TITLE_Y = 16

    local UI_SIZE = 24
    local UI_OFFSET_X = 6
    local UI_OFFSET_Y = 0

    local VER_SIZE = 12
    local VER_OFFSET_X = 6
    local VER_OFFSET_Y = -2

    local titleNaptime = win:CreateFontString(nil, "OVERLAY")
    titleNaptime:SetFont((ns.GetFont and ns:GetFont("NapLarge")) or "Fonts\\FRIZQT__.TTF", TITLE_SIZE, "OUTLINE")
    titleNaptime:SetPoint("TOPLEFT", win, "TOPLEFT", TITLE_X, -TITLE_Y)
    titleNaptime:SetText("Naptime")
    titleNaptime:SetTextColor(0.949, 0.282, 0.000, 1)

    local titleUI = win:CreateFontString(nil, "OVERLAY")
    titleUI:SetFont((ns.GetFont and ns:GetFont("NapLarge")) or "Fonts\\FRIZQT__.TTF", UI_SIZE, "OUTLINE")
    titleUI:SetPoint("LEFT", titleNaptime, "RIGHT", UI_OFFSET_X, UI_OFFSET_Y)
    titleUI:SetText("UI")
    titleUI:SetTextColor(1, 1, 1, 1)

    local versionText = win:CreateFontString(nil, "OVERLAY")
    versionText:SetFont((ns.GetFont and ns:GetFont("NapLarge")) or "Fonts\\FRIZQT__.TTF", VER_SIZE, "OUTLINE")
    versionText:SetPoint("LEFT", titleUI, "RIGHT", VER_OFFSET_X, VER_OFFSET_Y)
    versionText:SetText("V1.0")
    versionText:SetTextColor(1, 1, 1, 0.5)

    -- -------------------------------------------------------
    -- Sidebar button helper
    -- -------------------------------------------------------
    local function CreateSidebarButton(parent, text)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(180, 35)

        -- state colors
        local NORMAL_RGBA  = { 23/255, 23/255, 23/255, 1 } -- #171717
        local HOVER_RGBA   = { 0.176, 0.176, 0.176, 1 }       -- test blue
        local SELECT_RGBA  = { 1.00, 0.55, 0.00, 1 }       -- orange

        btn.isSelected = false

            btn.bg = btn:CreateTexture(nil, "BACKGROUND")
            btn.bg:SetAllPoints()
            btn.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            btn.bg:SetVertexColor(unpack(NORMAL_RGBA))


            btn.label = btn:CreateFontString(nil, "OVERLAY")
            btn.label:SetFont((ns.GetFont and ns:GetFont("NapSmall")) or "Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
            btn.label:SetPoint("LEFT", btn, "LEFT", 14, 0)
            btn.label:SetText(text)
            btn.label:SetTextColor(1, 1, 1, 1)

            local function SetNormal()
                btn.bg:SetVertexColor(unpack(NORMAL_RGBA))
            end

            local function SetHover()
                btn.bg:SetVertexColor(unpack(HOVER_RGBA))
            end

            local function SetSelected()
                btn.bg:SetVertexColor(unpack(SELECT_RGBA))
            end

            btn:SetScript("OnEnter", function(self)
                if not self.isSelected then
                    SetHover()
                end
            end)

            btn:SetScript("OnLeave", function(self)
                if not self.isSelected then
                    SetNormal()
                end
            end)

            btn:SetScript("OnClick", function(self)
                self.isSelected = true
                SetSelected()
            end)

            SetNormal()

            return btn
        end

    -- -------------------------------------------------------
    -- Page host
    -- -------------------------------------------------------
    local pageHost = CreateFrame("Frame", nil, win)
    pageHost:SetPoint("TOPLEFT", win, "TOPLEFT", 230, -55)
    pageHost:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -10, 60)

    local welcomePage = CreateFrame("Frame", nil, pageHost)
    welcomePage:SetAllPoints()
    welcomePage:Show()

    local welcomeText = welcomePage:CreateFontString(nil, "OVERLAY")
    welcomeText:SetFont((ns.GetFont and ns:GetFont("NapSmall")) or "Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    welcomeText:SetPoint("CENTER", welcomePage, "CENTER", 0, 0)
    welcomeText:SetText("Welcome Page")
    welcomeText:SetTextColor(1, 1, 1, 1)

    -- -------------------------------------------------------
    -- Sidebar buttons
    -- -------------------------------------------------------
    local welcomeBtn = CreateSidebarButton(win, "Welcome")
    welcomeBtn:SetPoint("TOPLEFT", win, "TOPLEFT", 1, -61)

    local genBtn = CreateSidebarButton(win, "General")
    genBtn:SetPoint("TOPLEFT", welcomeBtn, "BOTTOMLEFT", 0, 0)

    local actionBtn = CreateSidebarButton(win, "Action Bars")
    actionBtn:SetPoint("TOPLEFT", genBtn, "BOTTOMLEFT", 0, 0)

    local auraBtn = CreateSidebarButton(win, "Auras")
    auraBtn:SetPoint("TOPLEFT", actionBtn, "BOTTOMLEFT", 0, 0)

    local castBtn = CreateSidebarButton(win, "Cast Bars")
    castBtn:SetPoint("TOPLEFT", auraBtn, "BOTTOMLEFT", 0, 0)

    local powerBtn = CreateSidebarButton(win, "Resource Bars")
    powerBtn:SetPoint("TOPLEFT", castBtn, "BOTTOMLEFT", 0, 0)

    local cdmBtn = CreateSidebarButton(win, "CD Manager")
    cdmBtn:SetPoint("TOPLEFT", powerBtn, "BOTTOMLEFT", 0, 0)

    local miniBtn = CreateSidebarButton(win, "Minimap")
    miniBtn:SetPoint("TOPLEFT", cdmBtn, "BOTTOMLEFT", 0, 0)

    -- -------------------------------------------------------
    -- Close button
    -- -------------------------------------------------------
    local closeBtn = CreateFrame("Button", nil, win)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -8, -8)

    local closeText
    if O.FS then
        closeText = O.FS(closeBtn, 14, "x", {1, 1, 1, 1}, true, "Primary")
    else
        closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        closeText:SetText("x")
        closeText:SetTextColor(1, 1, 1, 1)
    end
    closeText:SetAllPoints()

    closeBtn:SetScript("OnClick", function()
        win:Hide()
    end)

    -- -------------------------------------------------------
    -- Dragging
    -- -------------------------------------------------------
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    win:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    O.window = win
    return win
end

function O:Enable()
    if self.__enabled then
        return
    end
    self.__enabled = true

    SLASH_NAPTIMEUI1 = "/nui"
    SLASH_NAPTIMEUI2 = "/napui"
    SlashCmdList["NAPTIMEUI"] = function()
        local win = BuildWindow()
        if win:IsShown() then
            win:Hide()
        else
            win:Show()
        end
    end
end
