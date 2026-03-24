local ADDON, ns = ...
ns = ns or {}

ns.GUI = ns.GUI or {}
ns.GUI.Options = ns.GUI.Options or {}
local O = ns.GUI.Options

local C = O.Colors

-- -------------------------------------------------------
-- Config helpers
-- -------------------------------------------------------

local function GetRootCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then
        ns.Config = ns.Config or {}
        cfg = ns.Config
    end
    return cfg
end

local function GetMinimapCfg()
    local cfg = GetRootCfg()

    cfg.minimap = cfg.minimap or {
        enabled = true,

        sizePx = 200,

        x = -20,
        y = -20,

        showZoneText = true,
        showClock = true,
        showMail = true,
        showTracking = true,
        showInstanceDifficulty = true,
        showGuildDifficulty = true,
    }

    return cfg.minimap
end

local function GetValue(key, default)
    local mm = GetMinimapCfg()
    local v = mm[key]
    if v == nil then
        return default
    end
    return v
end

local function SetValue(key, value)
    local mm = GetMinimapCfg()
    mm[key] = value

    local M = ns.Modules and ns.Modules.Minimap
    if M then
        if type(M.ApplyAll) == "function" then
            M:ApplyAll()
        elseif type(M.Refresh) == "function" then
            M:Refresh()
        elseif type(M.Update) == "function" then
            M:Update()
        elseif type(M.ApplyLayout) == "function" then
            M:ApplyLayout()
        end
    end
end

-- -------------------------------------------------------
-- Small widgets
-- -------------------------------------------------------

local function CreateSectionLabel(parent, text)
    local fs = O.FS(parent, 12, text, C.orange, true, "Primary")
    return fs
end

local function CreateRowCheckbox(parent, label, checked, onChange)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(28)

    local lbl = O.FS(row, 12, label, C.white, true, "Primary")
    lbl:SetPoint("LEFT", row, "LEFT", 0, 0)

    local cb = CreateFrame("CheckButton", nil, row, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    cb:SetChecked(checked)

    if onChange then
        cb:SetScript("OnClick", function(self)
            onChange(self:GetChecked() and true or false)
        end)
    end

    row.checkbox = cb
    row.label = lbl
    return row
end

local function CreateRowSlider(parent, label, minV, maxV, curV, onChange)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(42)

    local lbl = O.FS(row, 12, label, C.white, true, "Primary")
    lbl:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)

    local valueFS = O.FS(row, 12, tostring(curV), C.orange, true, "Primary")
    valueFS:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)

    local slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
    slider:SetWidth(240)
    slider:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -8)
    slider:SetMinMaxValues(minV, maxV)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(curV)

    if slider.Low then slider.Low:SetText(tostring(minV)) end
    if slider.High then slider.High:SetText(tostring(maxV)) end
    if slider.Text then slider.Text:SetText("") end

    slider:SetScript("OnValueChanged", function(self, v)
        local iv = math.floor(v + 0.5)
        valueFS:SetText(tostring(iv))
        if onChange then
            onChange(iv)
        end
    end)

    row.slider = slider
    row.valueFS = valueFS
    row.label = lbl
    return row
end

-- -------------------------------------------------------
-- Page
-- -------------------------------------------------------

function O.BuildMinimapPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)
    page:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", page, "TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -28, 10)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(760, 900)
    scroll:SetScrollChild(content)

    local y = -8
    local left = 12

    -- Core
    local coreLabel = CreateSectionLabel(content, "Core")
    coreLabel:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    y = y - 28

    local enableRow = CreateRowCheckbox(
        content,
        "Enable Minimap",
        GetValue("enabled", true),
        function(v) SetValue("enabled", v) end
    )
    enableRow:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    enableRow:SetPoint("RIGHT", content, "RIGHT", -30, 0)
    y = y - 34

    local sizeRow = CreateRowSlider(
        content,
        "Minimap Size",
        120,
        320,
        GetValue("sizePx", 200),
        function(v) SetValue("sizePx", v) end
    )
    sizeRow:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    y = y - 62

    -- Position
    local posLabel = CreateSectionLabel(content, "Position")
    posLabel:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    y = y - 28

    local xRow = CreateRowSlider(
        content,
        "X Position",
        -800,
        800,
        GetValue("x", -20),
        function(v) SetValue("x", v) end
    )
    xRow:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    y = y - 62

    local yRow = CreateRowSlider(
        content,
        "Y Position",
        -800,
        800,
        GetValue("y", -20),
        function(v) SetValue("y", v) end
    )
    yRow:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    y = y - 62

    -- Elements
    local elemLabel = CreateSectionLabel(content, "Elements")
    elemLabel:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    y = y - 28

    local zoneRow = CreateRowCheckbox(
        content,
        "Show Zone Text",
        GetValue("showZoneText", true),
        function(v) SetValue("showZoneText", v) end
    )
    zoneRow:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    zoneRow:SetPoint("RIGHT", content, "RIGHT", -30, 0)
    y = y - 34

    local clockRow = CreateRowCheckbox(
        content,
        "Show Clock",
        GetValue("showClock", true),
        function(v) SetValue("showClock", v) end
    )
    clockRow:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    clockRow:SetPoint("RIGHT", content, "RIGHT", -30, 0)
    y = y - 34

    local mailRow = CreateRowCheckbox(
        content,
        "Show Mail Icon",
        GetValue("showMail", true),
        function(v) SetValue("showMail", v) end
    )
    mailRow:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    mailRow:SetPoint("RIGHT", content, "RIGHT", -30, 0)
    y = y - 34

    local trackingRow = CreateRowCheckbox(
        content,
        "Show Tracking Button",
        GetValue("showTracking", true),
        function(v) SetValue("showTracking", v) end
    )
    trackingRow:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    trackingRow:SetPoint("RIGHT", content, "RIGHT", -30, 0)
    y = y - 34

    local instRow = CreateRowCheckbox(
        content,
        "Show Instance Difficulty",
        GetValue("showInstanceDifficulty", true),
        function(v) SetValue("showInstanceDifficulty", v) end
    )
    instRow:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    instRow:SetPoint("RIGHT", content, "RIGHT", -30, 0)
    y = y - 34

    local guildRow = CreateRowCheckbox(
        content,
        "Show Guild Difficulty",
        GetValue("showGuildDifficulty", true),
        function(v) SetValue("showGuildDifficulty", v) end
    )
    guildRow:SetPoint("TOPLEFT", content, "TOPLEFT", left, y)
    guildRow:SetPoint("RIGHT", content, "RIGHT", -30, 0)
    y = y - 34

    content:SetHeight(math.abs(y) + 40)

    return page
end
