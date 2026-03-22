-- Core/Options.lua
local ADDON, ns = ...
ns = ns or {}
ns.Options = ns.Options or {}
local O = ns.Options

local function GetDB()
    NOL_DB = NOL_DB or {}
    NOL_DB.modules = NOL_DB.modules or {}
    return NOL_DB.modules
end

local function IsModuleEnabled(key, default)
    local db = GetDB()
    if db[key] == nil then return default ~= false end
    return db[key] == true
end

local function SetModuleEnabled(key, value)
    local db = GetDB()
    db[key] = value
end

local function GetCDMDB()
    NOL_DB = NOL_DB or {}
    NOL_DB.cooldownManager = NOL_DB.cooldownManager or {}
    return NOL_DB.cooldownManager
end

-- -------------------------------------------------------
-- Shared widget helpers
-- -------------------------------------------------------

local function AddTitle(panel, text, subtext)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    title:SetText(text)

    if subtext then
        local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        sub:SetTextColor(0.6, 0.6, 0.6)
        sub:SetText(subtext)
    end

    local divider = panel:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\Buttons\\WHITE8X8")
    divider:SetVertexColor(0.3, 0.3, 0.3, 0.8)
    divider:SetPoint("TOPLEFT",  panel, "TOPLEFT",  16, -52)
    divider:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -52)
    divider:SetHeight(1)
end

local function AddReloadButton(panel)
    local notice = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    notice:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 16, 44)
    notice:SetText("|cffff4444Changes require a reload to take effect.|r")
    notice:Hide()

    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(120, 22)
    btn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 16, 16)
    btn:SetText("Reload UI")
    btn:SetScript("OnClick", function() ReloadUI() end)

    return notice
end

local function AddSectionHeader(panel, text, yOffset)
    local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, yOffset)
    header:SetText("|cffff8d07" .. text .. "|r")
    return header
end

local function AddCheckbox(panel, label, desc, yOffset, key, default, notice)
    local cb = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, yOffset)

    local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    lbl:SetText(label)

    if desc then
        local d = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        d:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 20, -2)
        d:SetTextColor(0.6, 0.6, 0.6)
        d:SetText(desc)
    end

    cb:SetChecked(IsModuleEnabled(key, default))
    cb:SetScript("OnClick", function(self)
        SetModuleEnabled(key, self:GetChecked())
        if notice then notice:Show() end
    end)

    return cb
end

local function AddLabel(panel, text, yOffset)
    local lbl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, yOffset)
    lbl:SetText(text)
    return lbl
end

local function AddDropdown(panel, yOffset, options, currentValue, onChange)
    local dd = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, yOffset)

    UIDropDownMenu_SetWidth(dd, 180)
    UIDropDownMenu_SetText(dd, currentValue.label)

    UIDropDownMenu_Initialize(dd, function(self, level)
        for _, opt in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = opt.label
            info.value   = opt.value
            info.checked = (opt.value == currentValue.value)
            info.func    = function()
                currentValue.value = opt.value
                currentValue.label = opt.label
                UIDropDownMenu_SetText(dd, opt.label)
                onChange(opt.value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    return dd
end

-- -------------------------------------------------------
-- Cooldown Manager sub-page data
-- -------------------------------------------------------

local ASPECT_RATIOS = {
    { label = "Square (1:1)",     value = "1x1",  w = 1,  h = 1 },
    { label = "Landscape (16:9)", value = "16x9", w = 16, h = 9 },
    { label = "Landscape (4:3)",  value = "4x3",  w = 4,  h = 3 },
    { label = "Ultrawide (21:9)", value = "21x9", w = 21, h = 9 },
}

local FONTS = {
    { label = "Primary",   value = "Primary"   },
    { label = "Secondary", value = "Secondary" },
    { label = "Default",   value = "Default"   },
}

local function GetCurrentAspect()
    local db = GetCDMDB()
    local val = db.aspectRatio or "16x9"
    for _, r in ipairs(ASPECT_RATIOS) do
        if r.value == val then
            return { value = r.value, label = r.label, w = r.w, h = r.h }
        end
    end
    return { value = "16x9", label = "Landscape (16:9)", w = 16, h = 9 }
end

local function GetCurrentFont()
    local db = GetCDMDB()
    local val = db.font or "Primary"
    for _, f in ipairs(FONTS) do
        if f.value == val then
            return { value = f.value, label = f.label }
        end
    end
    return { value = "Primary", label = "Primary" }
end

local function ApplyAspectRatio(aspectValue, notice)
    local db = GetCDMDB()
    db.aspectRatio = aspectValue

    local chosen
    for _, r in ipairs(ASPECT_RATIOS) do
        if r.value == aspectValue then
            chosen = r
            break
        end
    end
    if not chosen then return end

    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) == "table" and type(cfg.cooldownManager) == "table" then
        local cdm = cfg.cooldownManager
        local h = tonumber(cdm.wideIconHeight) or 27
        local w = math.floor(h * (chosen.w / chosen.h))

        cdm.wideIcons = (chosen.value ~= "1x1")

        cdm.viewers = cdm.viewers or {}
        for _, key in ipairs({ "essential", "utility", "buff" }) do
            cdm.viewers[key] = cdm.viewers[key] or {}
            cdm.viewers[key].iconWidth  = w
            cdm.viewers[key].iconHeight = h
        end
    end

    if notice then notice:Show() end
end

local function ApplyCDMFont(fontValue, notice)
    local db = GetCDMDB()
    db.font = fontValue

    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) == "table" and type(cfg.cooldownManager) == "table" then
        cfg.cooldownManager.font = fontValue
        if type(cfg.cooldownManager.power) == "table" then
            cfg.cooldownManager.power.font = fontValue
        end
    end

    if notice then notice:Show() end
end

-- -------------------------------------------------------
-- Cooldown Manager sub-page
-- -------------------------------------------------------

local function BuildCDMSubPage(parent)
    local panel = CreateFrame("Frame")
    panel.name = "Cooldown Manager"

    AddTitle(panel,
        "Cooldown Manager",
        "Configure cooldown manager appearance."
    )

    local notice = AddReloadButton(panel)

    AddLabel(panel, "Icon Aspect Ratio", -70)
    local currentAspect = GetCurrentAspect()
    AddDropdown(panel, -88, ASPECT_RATIOS, currentAspect, function(value)
        ApplyAspectRatio(value, notice)
    end)

    AddLabel(panel, "Font", -130)
    local currentFont = GetCurrentFont()
    AddDropdown(panel, -148, FONTS, currentFont, function(value)
        ApplyCDMFont(value, notice)
    end)

    local ok, err = pcall(function()
        local sub = Settings.RegisterCanvasLayoutSubcategory(parent, panel, "Cooldown Manager")
        Settings.RegisterAddOnCategory(sub)
        O.cdmPanel = panel
    end)

    if not ok then
        print("|cffff5555NaptimeUI|r CDM sub-page error: " .. tostring(err))
    end
end

-- -------------------------------------------------------
-- Main panel
-- -------------------------------------------------------

local function BuildMainPanel()
    local panel = CreateFrame("Frame")
    panel.name = "NaptimeUI"

    AddTitle(panel,
        "|cffff8d07Naptime|r|cffffffffUI|r",
        "Toggle modules on or off. Some changes require a reload."
    )

    local notice = AddReloadButton(panel)

    -- Action Bars
    AddSectionHeader(panel, "Action Bars", -70)
    AddCheckbox(panel, "Action Bars",      "Replaces Blizzard's default action bars.", -90,  "actionbars",      true, notice)

    -- Minimap
    AddSectionHeader(panel, "Minimap", -138)
    AddCheckbox(panel, "Minimap",          "Replaces Blizzard's default minimap.",     -158, "minimap",         true, notice)

    -- Combat
    AddSectionHeader(panel, "Combat", -206)
    AddCheckbox(panel, "Cooldown Manager", "Shows ability cooldowns as wide icons.",   -226, "cooldownManager", true, notice)

    -- Buffs
    AddSectionHeader(panel, "Buffs", -274)
    AddCheckbox(panel, "Auras",            "Replaces Blizzard's default auras.",       -294, "auras",           true, notice)

    -- Interface
    AddSectionHeader(panel, "Interface", -342)
    AddCheckbox(panel, "Tooltip",  "Applies a clean skin to all tooltips.",  -362, "tooltip", true, notice)
    AddCheckbox(panel, "Shadows",  "Adds a soft shadow to UI elements.",     -402, "shadow",  true, notice)

    local ok, err = pcall(function()
        local category = Settings.RegisterCanvasLayoutCategory(panel, "NaptimeUI")
        Settings.RegisterAddOnCategory(category)
        O.category = category
    end)

    if not ok then
        print("|cffff5555NaptimeUI|r Options error: " .. tostring(err))
        return nil
    end

    return O.category
end

-- -------------------------------------------------------
-- Enable
-- -------------------------------------------------------

function O:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local category = BuildMainPanel()

    if category then
        BuildCDMSubPage(category)
    end


    --- Slash Command
    SLASH_NAPTIMEUI1 = "/nui"
    SlashCmdList["NAPTIMEUI"] = function()
        if O.category then
            local ok, err = pcall(function()
                Settings.OpenToCategory(O.category:GetID())
            end)
            if not ok then
                print("|cffff5555NaptimeUI|r /nap error: " .. tostring(err))
            end
        else
            print("|cffff5555NaptimeUI|r Settings panel not registered!")
        end
    end
  end

-- -------------------------------------------------------
-- Global helper
-- -------------------------------------------------------

function ns:IsModuleEnabled(key)
    NOL_DB = NOL_DB or {}
    NOL_DB.modules = NOL_DB.modules or {}
    local val = NOL_DB.modules[key]
    if val == nil then return true end
    return val == true
end
