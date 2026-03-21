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

function O:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local panel = CreateFrame("Frame")
    panel.name = "NaptimeUI"

    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    title:SetText("|cffff8d07Naptime|r|cffffffffUI|r")

    local subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("|cffaaaaaaModule Settings|r")

    -- Divider
    local divider = panel:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\Buttons\\WHITE8X8")
    divider:SetVertexColor(0.3, 0.3, 0.3, 0.8)
    divider:SetPoint("TOPLEFT",  panel, "TOPLEFT",  16, -58)
    divider:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -58)
    divider:SetHeight(1)

    -- Reload notice
    local reloadNotice = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reloadNotice:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 16, 44)
    reloadNotice:SetText("|cffff4444Changes require a reload to take effect.  /reload|r")
    reloadNotice:Hide()

    local function ShowReloadNotice()
        reloadNotice:Show()
    end

    -- Reload button
    local reloadBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reloadBtn:SetSize(120, 22)
    reloadBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 16, 16)
    reloadBtn:SetText("Reload UI")
    reloadBtn:SetScript("OnClick", function()
        ReloadUI()
    end)

    -- Checkbox helper
    local function CreateCheckbox(parent, label, description, yOffset, key, default)
        local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, yOffset)

        local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        lbl:SetText(label)

        if description then
            local desc = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            desc:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 20, -2)
            desc:SetTextColor(0.7, 0.7, 0.7)
            desc:SetText(description)
        end

        cb:SetChecked(IsModuleEnabled(key, default))

        cb:SetScript("OnClick", function(self)
            SetModuleEnabled(key, self:GetChecked())
            ShowReloadNotice()
        end)

        return cb
    end

    -- -------------------------------------------------------
    -- Module checkboxes
    -- -------------------------------------------------------

    CreateCheckbox(
        panel,
        "Cooldown Manager",
        "Shows ability cooldowns as rectangular icons above the action bar.",
        -70,
        "cooldownManager",
        true
    )

    -- -------------------------------------------------------
    -- Register with Blizzard settings
    -- -------------------------------------------------------

    local category = Settings.RegisterCanvasLayoutCategory(panel, "NaptimeUI")
    Settings.RegisterAddOnCategory(category)
    O.category = category
end

function ns:IsModuleEnabled(key)
    NOL_DB = NOL_DB or {}
    NOL_DB.modules = NOL_DB.modules or {}
    local val = NOL_DB.modules[key]
    if val == nil then return true end
    return val == true
end
