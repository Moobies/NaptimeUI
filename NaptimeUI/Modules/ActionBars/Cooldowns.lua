-- Modules/ActionBars/Cooldowns.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.ActionBars = ns.Modules.ActionBars or {}
local AB = ns.Modules.ActionBars
AB.Cooldowns = AB.Cooldowns or {}
local C = AB.Cooldowns

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return nil end
    if type(cfg.actionbars) ~= "table" then return nil end
    return cfg.actionbars
end

local function IsFontPath(v)
    return type(v) == "string" and (
        v:find("\\") or v:lower():match("%.ttf$") or v:lower():match("%.otf$")
    )
end

local function ResolveFont(fontKeyOrPath)
    if IsFontPath(fontKeyOrPath) then return fontKeyOrPath end
    return (ns.GetFont and ns:GetFont(fontKeyOrPath)) or "Fonts\\FRIZQT__.TTF"
end

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

local function ApplyFS(fs, ab)
    if not (fs and fs.SetFont) then return end

    local font = ResolveFont(ab.cooldownFont or "Primary")
    local size = tonumber(ab.cooldownSize) or 14
    local flags = ab.cooldownFlags or "OUTLINE"

    local ok = pcall(fs.SetFont, fs, font, size, flags)
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

function C:ApplyButton(btn)
    local ab = GetCfg()
    if not ab then return end
    local cd = btn and (btn.cooldown or btn.Cooldown)
    if not cd then return end

    local fs = FindCooldownCountFS(cd)
    if fs then ApplyFS(fs, ab) end

    -- Keep reapplying if Blizzard resets it
    if not cd.__nolCooldownFontHooked then
        cd.__nolCooldownFontHooked = true
        if cd.SetCooldown then
            hooksecurefunc(cd, "SetCooldown", function()
                local fss = FindCooldownCountFS(cd)
                if fss then ApplyFS(fss, GetCfg()) end
            end)
        end
    end
end

local function RefreshAllCooldownFonts()
    local layout = AB.Layout
    if layout and layout.AllButtons then
        for btn in pairs(layout.AllButtons) do
            C:ApplyButton(btn)
        end
    end
end

function C:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    f:SetScript("OnEvent", function()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, RefreshAllCooldownFonts)
        else
            RefreshAllCooldownFonts()
        end
    end)
end
