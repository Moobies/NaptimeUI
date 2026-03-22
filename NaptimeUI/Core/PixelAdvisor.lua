-- Core/PixelAdvisor.lua
local ADDON, ns = ...
ns = ns or {}

ns.PixelAdvisor = ns.PixelAdvisor or {}
local PA = ns.PixelAdvisor

-- -------------------------------------------------------
-- Helpers
-- -------------------------------------------------------

local function GetDB()
    NOL_DB = NOL_DB or {}
    NOL_DB.pixelAdvisor = NOL_DB.pixelAdvisor or {}
    return NOL_DB.pixelAdvisor
end

local function GetOptimalScale()
    local _, physicalHeight = GetPhysicalScreenSize()
    if not physicalHeight or physicalHeight == 0 then return nil, nil end
    local optimal = 768 / physicalHeight
    -- Round to 2 decimal places to match WoW's slider precision
    optimal = math.floor(optimal * 100 + 0.5) / 100
    return optimal, physicalHeight
end

local function GetCurrentScale()
    return math.floor((UIParent:GetScale()) * 100 + 0.5) / 100
end

local function IsScaleOptimal(optimal)
    if not optimal then return true end
    return math.abs(GetCurrentScale() - optimal) <= 0.01
end

-- -------------------------------------------------------
-- StaticPopup definition
-- -------------------------------------------------------

StaticPopupDialogs["NAPTIMEUI_PIXEL_ADVISOR"] = {
    text = "",
    button1 = "Apply & Reload",
    button2 = "Dismiss",
    OnAccept = function()
        local optimal = StaticPopupDialogs["NAPTIMEUI_PIXEL_ADVISOR"].__optimal
        if optimal then
            SetCVar("uiScale", optimal)
            SetCVar("useUiScale", 1)
            UIParent:SetScale(optimal)
            ReloadUI()
        end
    end,
    OnCancel = function()
        -- Dismissed — don't show again for this resolution
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- -------------------------------------------------------
-- Check and show
-- -------------------------------------------------------

local function CheckAndSuggest()
    local optimal, physicalHeight = GetOptimalScale()
    if not optimal or not physicalHeight then return end

    local db = GetDB()

    -- If we've already shown this for the current resolution, skip
    if db.lastSeenHeight == physicalHeight then return end

    -- Scale is already optimal — just record the resolution and move on
    if IsScaleOptimal(optimal) then
        db.lastSeenHeight = physicalHeight
        return
    end

    -- Show the popup
    local current = GetCurrentScale()
    local dialog = StaticPopupDialogs["NAPTIMEUI_PIXEL_ADVISOR"]
    dialog.__optimal = optimal
    dialog.text = string.format(
        "|cffff8d07NaptimeUI|r — Your UI scale (|cffffffff%.2f|r) isn't pixel-perfect for your resolution.\n\nRecommended scale for %dp: |cffffffff%.2f|r\n\nApply and reload for the sharpest UI?",
        current,
        physicalHeight,
        optimal
    )

    StaticPopup_Show("NAPTIMEUI_PIXEL_ADVISOR")

    -- Record that we've shown for this resolution
    db.lastSeenHeight = physicalHeight
end

-- -------------------------------------------------------
-- Enable
-- -------------------------------------------------------

function PA:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local f = CreateFrame("Frame")
    self.__driver = f

    -- Wait for PLAYER_ENTERING_WORLD so GetPhysicalScreenSize is reliable
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("DISPLAY_SIZE_CHANGED")

    f:SetScript("OnEvent", function(_, event)
        -- Small delay to let WoW finish initialising screen state
        C_Timer.After(2, CheckAndSuggest)
    end)
end
