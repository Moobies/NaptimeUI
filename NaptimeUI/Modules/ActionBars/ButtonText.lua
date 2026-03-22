-- Modules/ActionBars/ButtonText.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.ActionBars = ns.Modules.ActionBars or {}
local AB = ns.Modules.ActionBars
AB.ButtonText = AB.ButtonText or {}
local BT = AB.ButtonText

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return nil end
    if type(cfg.actionbars) ~= "table" then return nil end
    return cfg.actionbars
end

-- -------------------------------------------------------
-- Hotkeys
-- -------------------------------------------------------

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

    text = text:gsub("MButton", "M")
    text = text:gsub("Mouse%-Button", "M")
    text = text:gsub("Mouse%-", "M")
    text = text:gsub("Mouse", "M")
    text = text:gsub("BUTTON", "B")

    text = text:gsub("SHIFT%-", "S")
    text = text:gsub("CTRL%-",  "C")
    text = text:gsub("ALT%-",   "A")

    text = text:gsub("s%-", "S")
    text = text:gsub("c%-", "C")
    text = text:gsub("a%-", "A")

    text = text:gsub("%-", "")

    return text
end

function BT:UpdateHotkey(btn)
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

-- -------------------------------------------------------
-- Cooldown fonts
-- -------------------------------------------------------

local function FindCooldownCountFS(cd)
    if not cd then return nil end

    for _, k in ipairs({ "Text", "text", "timer", "Timer", "CountdownText" }) do
        local fs = cd[k]
        if fs and fs.GetObjectType and fs:GetObjectType() == "FontString" then
            return fs
        end
    end

    if cd.GetRegions then
        for _, r in ipairs({ cd:GetRegions() }) do
            if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                return r
            end
        end
    end
end

local function ApplyCooldownFS(fs, ab)
    if not (fs and fs.SetFont) then return end

    local fontPath = ns.GetFont and ns:GetFont(ab.cooldownFont or "Primary") or "Fonts\\FRIZQT__.TTF"
    local size = tonumber(ab.cooldownSize) or 14
    local flags = ab.cooldownFlags or "OUTLINE"

    local ok = pcall(fs.SetFont, fs, fontPath, size, flags)
    if not ok then
        pcall(fs.SetFont, fs, "Fonts\\FRIZQT__.TTF", size, flags)
    end

    local c = ab.cooldownRGBA or {1,1,1,1}
    if fs.SetTextColor then
        fs:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
    end

    if ab.cooldownShadow == false and fs.SetShadowOffset then
        fs:SetShadowOffset(0, 0)
    end
end

function BT:ApplyCooldown(btn)
    local ab = GetCfg()
    if not ab then return end
    local cd = btn and (btn.cooldown or btn.Cooldown)
    if not cd then return end

    local fs = FindCooldownCountFS(cd)
    if fs then ApplyCooldownFS(fs, ab) end

    if not cd.__nolCooldownFontHooked then
        cd.__nolCooldownFontHooked = true
        if cd.SetCooldown then
            hooksecurefunc(cd, "SetCooldown", function()
                local fss = FindCooldownCountFS(cd)
                if fss then ApplyCooldownFS(fss, GetCfg()) end
            end)
        end
    end
end

-- -------------------------------------------------------
-- Refresh all
-- -------------------------------------------------------

local function RefreshAll()
    local layout = AB.Layout
    if not (layout and layout.AllButtons) then return end

    for btn in pairs(layout.AllButtons) do
        BT:UpdateHotkey(btn)
        BT:ApplyCooldown(btn)
    end
end

-- -------------------------------------------------------
-- Enable
-- -------------------------------------------------------

function BT:Enable()
    if self.__enabled then return end
    self.__enabled = true

    if type(ActionButton_UpdateHotkeys) == "function" then
        hooksecurefunc("ActionButton_UpdateHotkeys", function()
            RefreshAll()
        end)
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UPDATE_BINDINGS")
    f:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    f:SetScript("OnEvent", function()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, RefreshAll)
        else
            RefreshAll()
        end
    end)
end
