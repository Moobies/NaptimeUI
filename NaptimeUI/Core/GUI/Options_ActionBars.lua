local ADDON, ns = ...
ns = ns or {}

ns.GUI = ns.GUI or {}
ns.GUI.Options = ns.GUI.Options or {}
local O = ns.GUI.Options

local C = O.Colors

local LAYOUT_OPTIONS = {
    { label = "Horizontal", value = "H" },
    { label = "Vertical",   value = "V" },
    { label = "Grid",       value = "G" },
}

local VISIBILITY_OPTIONS = {
    { label = "Always Show", value = "show"      },
    { label = "Mouse Over",  value = "mouseover" },
    { label = "Hide",        value = "hide"      },
}

local BAR_DEFS = {
    { key = "bar1", label = "Action Bar 1", canDisable = false },
    { key = "bar2", label = "Action Bar 2", canDisable = true  },
    { key = "bar3", label = "Action Bar 3", canDisable = true  },
    { key = "bar4", label = "Action Bar 4", canDisable = true  },
    { key = "bar5", label = "Action Bar 5", canDisable = true  },
    { key = "bar6", label = "Action Bar 6", canDisable = true  },
    { key = "bar7", label = "Action Bar 7", canDisable = true  },
    { key = "bar8", label = "Action Bar 8", canDisable = true  },
}

local SECT_H   = 30
local SECT_PAD = 12
local BAR_H    = 258

local function GetBarCfg(barKey)
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" or type(cfg.actionbars) ~= "table" then
        return nil
    end
    return cfg.actionbars[barKey]
end

local function ApplyBarChange()
    local AB = ns.Modules and ns.Modules.ActionBars
    if AB and AB.Layout and AB.Layout.ApplyAll then
        AB.Layout:ApplyAll()
    end
end

local function GetBarValue(barKey, field, default)
    local bc = GetBarCfg(barKey)
    if not bc then
        return default
    end
    local v = bc[field]
    return v == nil and default or v
end

local function SetBarValue(barKey, field, value)
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then
        return
    end
    cfg.actionbars = cfg.actionbars or {}
    cfg.actionbars[barKey] = cfg.actionbars[barKey] or {}
    cfg.actionbars[barKey][field] = value
    ApplyBarChange()
end

local function CreateCycler(parent, options, currentValue, onChange)
    local W, H, AW = 280, 24, 24

    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(W, H)

    O.FillColor(f, {0.06, 0.06, 0.06, 1}, "BACKGROUND", 0)
    O.ApplyBorder(f, C.btnBorder, 1)

    local leftBtn = CreateFrame("Button", nil, f)
    leftBtn:SetSize(AW, H)
    leftBtn:SetPoint("LEFT", f, "LEFT", 0, 0)

    local lt = O.FS(leftBtn, 13, "|cffff8d07<|r", nil, true, "Primary")
    lt:SetAllPoints(leftBtn)
    lt:SetJustifyH("CENTER")

    local rightBtn = CreateFrame("Button", nil, f)
    rightBtn:SetSize(AW, H)
    rightBtn:SetPoint("RIGHT", f, "RIGHT", 0, 0)

    local rt = O.FS(rightBtn, 13, "|cffff8d07>|r", nil, true, "Primary")
    rt:SetAllPoints(rightBtn)
    rt:SetJustifyH("CENTER")

    local ld = O.Tex(f, "OVERLAY", 4)
    ld:SetWidth(1)
    ld:SetVertexColor(C.btnBorder[1], C.btnBorder[2], C.btnBorder[3], 1)
    ld:SetPoint("TOPLEFT", leftBtn, "TOPRIGHT", 0, 0)
    ld:SetPoint("BOTTOMLEFT", leftBtn, "BOTTOMRIGHT", 0, 0)

    local rd = O.Tex(f, "OVERLAY", 4)
    rd:SetWidth(1)
    rd:SetVertexColor(C.btnBorder[1], C.btnBorder[2], C.btnBorder[3], 1)
    rd:SetPoint("TOPLEFT", rightBtn, "TOPLEFT", 0, 0)
    rd:SetPoint("BOTTOMLEFT", rightBtn, "BOTTOMLEFT", 0, 0)

    local lbl = O.FS(f, 12, "", C.orange, true, "Primary")
    lbl:SetPoint("LEFT", leftBtn, "RIGHT", 6, 0)
    lbl:SetPoint("RIGHT", rightBtn, "LEFT", -6, 0)
    lbl:SetJustifyH("CENTER")

    local idx = 1
    for i, opt in ipairs(options) do
        if opt.value == currentValue then
            idx = i
            break
        end
    end

    local function Update()
        lbl:SetText(options[idx].label)
    end

    leftBtn:SetScript("OnClick", function()
        idx = idx - 1
        if idx < 1 then idx = #options end
        Update()
        if onChange then onChange(options[idx].value) end
    end)

    rightBtn:SetScript("OnClick", function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        Update()
        if onChange then onChange(options[idx].value) end
    end)

    Update()
    return f
end

local function CreateRowCheckbox(parent, label, checked, onChange)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(26)

    local lbl = O.FS(row, 12, label, C.white, true, "Primary")
    lbl:SetPoint("LEFT", row, "LEFT", 0, 0)

    local cb = CreateFrame("CheckButton", nil, row, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
    cb:SetChecked(checked)

    if onChange then
        cb:SetScript("OnClick", function(self)
            onChange(self:GetChecked())
        end)
    end

    row.checkbox = cb
    return row
end

local function CreateRowSlider(parent, label, minV, maxV, curV, onChange)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(26)

    local lbl = O.FS(row, 12, label, C.white, true, "Primary")
    lbl:SetPoint("LEFT", row, "LEFT", 0, 0)

    local slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
    slider:SetWidth(160)
    slider:SetPoint("LEFT", lbl, "RIGHT", 12, 0)
    slider:SetMinMaxValues(minV, maxV)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(curV)

    if slider.Low  then slider.Low:SetText("")  end
    if slider.High then slider.High:SetText("") end
    if slider.Text then slider.Text:SetText("") end

    local valLbl = O.FS(row, 12, tostring(curV), C.orange, true, "Primary")
    valLbl:SetPoint("LEFT", slider, "RIGHT", 8, 0)

    slider:SetScript("OnValueChanged", function(_, v)
        local iv = math.floor(v)
        valLbl:SetText(tostring(iv))
        if onChange then
            onChange(iv)
        end
    end)

    return row
end

local function CreateSection(parent, anchorFrame, anchorPoint, offsetY, label, contentH)
    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("TOPLEFT", anchorFrame, anchorPoint, 0, offsetY)
    section:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    section:SetHeight(SECT_H)

    local header = CreateFrame("Button", nil, section)
    header:SetPoint("TOPLEFT", section, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, 0)
    header:SetHeight(SECT_H)

    local hbg = O.FillColor(header, {0.10, 0.10, 0.10, 1}, "BACKGROUND", 0)

    local hlbl = O.FS(header, 12, label, C.white, true, "Primary")
    hlbl:SetPoint("LEFT", header, "LEFT", SECT_PAD, 0)

    local ind = O.FS(header, 14, "+", C.orange, true, "Primary")
    ind:SetPoint("RIGHT", header, "RIGHT", -SECT_PAD, 0)

    local sep = O.Tex(section, "ARTWORK", 2)
    sep:SetHeight(1)
    sep:SetVertexColor(0.18, 0.18, 0.18, 1)
    sep:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    sep:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)

    local content = CreateFrame("Frame", nil, section)
    content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", SECT_PAD, -SECT_PAD)
    content:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", -SECT_PAD, -SECT_PAD)
    content:SetHeight(contentH)
    content:Hide()

    section.collapsed = true

    local function Toggle()
        if section.collapsed then
            section.collapsed = false
            content:Show()
            ind:SetText("-")
            hbg:SetVertexColor(0.13, 0.13, 0.13, 1)
            section:SetHeight(SECT_H + SECT_PAD + contentH + SECT_PAD)
        else
            section.collapsed = true
            content:Hide()
            ind:SetText("+")
            hbg:SetVertexColor(0.10, 0.10, 0.10, 1)
            section:SetHeight(SECT_H)
        end

        if section.onToggle then
            section.onToggle()
        end
    end

    header:SetScript("OnClick", Toggle)
    header:SetScript("OnEnter", function()
        hbg:SetVertexColor(0.13, 0.13, 0.13, 1)
    end)
    header:SetScript("OnLeave", function()
        local v = section.collapsed and 0.10 or 0.13
        hbg:SetVertexColor(v, v, v, 1)
    end)

    section.header = header
    section.content = content
    return section
end

local function PopulateBar(cf, bar)
    local y = 0
    local L = 4

    local sh = O.FS(cf, 11, "Bar Settings", C.orange, true, "Primary")
    sh:SetPoint("TOPLEFT", cf, "TOPLEFT", L, y)
    y = y - 26

    local er = CreateRowCheckbox(
        cf,
        "Enable Bar",
        bar.canDisable and GetBarValue(bar.key, "enabled", false) or true,
        bar.canDisable and function(v) SetBarValue(bar.key, "enabled", v) end or nil
    )
    er:SetPoint("TOPLEFT", cf, "TOPLEFT", L, y)
    er:SetPoint("RIGHT", cf, "RIGHT", 0, 0)
    if not bar.canDisable then
        er.checkbox:Disable()
    end
    y = y - 28

    local ol = O.FS(cf, 12, "Bar Orientation", C.white, true, "Primary")
    ol:SetPoint("TOPLEFT", cf, "TOPLEFT", L, y)
    y = y - 24

    local cyc1 = CreateCycler(
        cf,
        LAYOUT_OPTIONS,
        GetBarValue(bar.key, "layout", "H"),
        function(v) SetBarValue(bar.key, "layout", v) end
    )
    cyc1:SetPoint("TOPLEFT", cf, "TOPLEFT", L, y)
    y = y - 30

    local hr = CreateRowCheckbox(
        cf,
        "Show Hotkey",
        GetBarValue(bar.key, "showHotkey", true),
        function(v) SetBarValue(bar.key, "showHotkey", v) end
    )
    hr:SetPoint("TOPLEFT", cf, "TOPLEFT", L, y)
    hr:SetPoint("RIGHT", cf, "RIGHT", 0, 0)
    y = y - 28

    local mr = CreateRowCheckbox(
        cf,
        "Show Macro",
        GetBarValue(bar.key, "showMacro", false),
        function(v) SetBarValue(bar.key, "showMacro", v) end
    )
    mr:SetPoint("TOPLEFT", cf, "TOPLEFT", L, y)
    mr:SetPoint("RIGHT", cf, "RIGHT", 0, 0)
    y = y - 28

    local vl = O.FS(cf, 12, "Bar Visibility", C.white, true, "Primary")
    vl:SetPoint("TOPLEFT", cf, "TOPLEFT", L, y)
    y = y - 24

    local cyc2 = CreateCycler(
        cf,
        VISIBILITY_OPTIONS,
        GetBarValue(bar.key, "visibility", "show"),
        function(v) SetBarValue(bar.key, "visibility", v) end
    )
    cyc2:SetPoint("TOPLEFT", cf, "TOPLEFT", L, y)
    y = y - 30

    local sr = CreateRowSlider(
        cf,
        "Button Count",
        1,
        12,
        GetBarValue(bar.key, "count", 12),
        function(v) SetBarValue(bar.key, "count", v) end
    )
    sr:SetPoint("TOPLEFT", cf, "TOPLEFT", L, y)
    sr:SetPoint("RIGHT", cf, "RIGHT", 0, 0)
end

function O.BuildActionBarsPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)
    page:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", page, "TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -28, 10)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(760)
    content:SetHeight(8 * (SECT_H + 2) + 200)
    scroll:SetScrollChild(content)

    local sections = {}

    for i, bar in ipairs(BAR_DEFS) do
        local af, ap, oy
        if i == 1 then
            af, ap, oy = content, "TOPLEFT", 0
        else
            af, ap, oy = sections[i - 1], "BOTTOMLEFT", -2
        end

        local s = CreateSection(content, af, ap, oy, bar.label, BAR_H)
        PopulateBar(s.content, bar)
        sections[i] = s
    end

    return page
end
