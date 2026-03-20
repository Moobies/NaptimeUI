-- Modules/ActionBars/Hotkeys.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.ActionBars = ns.Modules.ActionBars or {}
local AB = ns.Modules.ActionBars
AB.Hotkeys = AB.Hotkeys or {}
local H = AB.Hotkeys

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return nil end
    if type(cfg.actionbars) ~= "table" then return nil end
    return cfg.actionbars
end

local function GetHotkeyFS(btn)
    if not btn then return nil end
    return btn.HotKey
        or btn.HotKeyText
        or btn.hotkey
        or (btn.GetName and _G[btn:GetName() .. "HotKey"])
end

local function ShortenHotkey(text)
    if not text or text == "" then return text end

    text = text:gsub("%s+", "")

    -- Mouse formats
    text = text:gsub("MButton", "M")            -- MButton4 / MButton-4
    text = text:gsub("Mouse%-Button", "M")
    text = text:gsub("Mouse%-", "M")
    text = text:gsub("Mouse", "M")

    text = text:gsub("BUTTON", "B")

    -- long modifiers
    text = text:gsub("SHIFT%-", "S")
    text = text:gsub("CTRL%-",  "C")
    text = text:gsub("ALT%-",   "A")

    -- short modifiers (your 's-R' case)
    text = text:gsub("s%-", "S")
    text = text:gsub("c%-", "C")
    text = text:gsub("a%-", "A")

    -- remove remaining separators
    text = text:gsub("%-", "")

    return text
end

function H:UpdateButton(btn)
    local ab = GetCfg()
    if not ab or ab.showHotkey == false then return end

    local hk = GetHotkeyFS(btn)
    if not hk or not hk.GetText or not hk.SetText then return end
    local t = hk:GetText()
    if not t or t == "" then return end
    local short = ShortenHotkey(t)
    if short ~= t then
        hk:SetText(short)
    end
end

local function RefreshAllHotkeys()
    local layout = AB.Layout
    if layout and layout.AllButtons then
        for btn in pairs(layout.AllButtons) do
            H:UpdateButton(btn)
        end
    else
        -- fallback: brute scan
        local prefixes = {
            "ActionButton",
            "MultiBarBottomLeftButton",
            "MultiBarBottomRightButton",
            "MultiBarRightButton",
            "MultiBarLeftButton",
            "MultiBar5Button",
            "MultiBar6Button",
            "MultiBar7Button",
            "PetActionButton",
            "StanceButton",
        }
        for _, prefix in ipairs(prefixes) do
            local max = 12
            if prefix == "PetActionButton" then max = _G.NUM_PET_ACTION_SLOTS or 10 end
            if prefix == "StanceButton" then max = _G.NUM_STANCE_SLOTS or 10 end
            for i = 1, max do
                local btn = _G[prefix .. i]
                if btn then H:UpdateButton(btn) end
            end
        end
    end
end

function H:Enable()
    if self.__enabled then return end
    self.__enabled = true

    if type(ActionButton_UpdateHotkeys) == "function" then
        hooksecurefunc("ActionButton_UpdateHotkeys", function()
            RefreshAllHotkeys()
        end)
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("UPDATE_BINDINGS")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, RefreshAllHotkeys)
        else
            RefreshAllHotkeys()
        end
    end)
end
