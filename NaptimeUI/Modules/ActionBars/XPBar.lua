-- Modules/ActionBars/XPBar.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.XPBar = ns.Modules.XPBar or {}
local X = ns.Modules.XPBar

local Pixel  = ns.Pixel
local Border = ns.Border

local WHITE = "Interface\\Buttons\\WHITE8X8"

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return nil end
    if type(cfg.actionbars) ~= "table" then return nil end
    if type(cfg.actionbars.xpbar) ~= "table" then return nil end
    return cfg.actionbars.xpbar
end

local function AtMaxLevel()
    local lvl = UnitLevel("player") or 1
    local max = (GetMaxPlayerLevel and GetMaxPlayerLevel()) or 80
    return lvl >= max
end

local function EnsureBar()
    if X.frame then return X.frame end

    local f = CreateFrame("Frame", "NOL_XPBar", UIParent)
    f:SetClampedToScreen(true)
    f:EnableMouse(false)

    -- Ensure pixel-perfect frame settings if your Pixel module supports it
    if Pixel and Pixel.Enforce then
        Pixel:Enforce(f)
    end

    -- background (matches your style)
    local bg = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetTexture(WHITE)
    bg:SetAllPoints(f)
    f.bg = bg

    -- rested behind xp
    local rested = CreateFrame("StatusBar", nil, f)
    rested:SetStatusBarTexture(WHITE)
    rested:SetAllPoints(f)
    rested:SetFrameLevel(f:GetFrameLevel() + 1)
    f.rested = rested

    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetStatusBarTexture(WHITE)
    bar:SetAllPoints(f)
    bar:SetFrameLevel(f:GetFrameLevel() + 2)
    f.bar = bar

    -- Use YOUR Border module only
    if Border and Border.Apply then
        Border:Apply(f, 1, {0,0,0,1})
    end

    X.frame = f
    return f
end

local function ApplyLayout()
    local cfg = GetCfg()
    if not cfg then return end
    local f = EnsureBar()

    local w = tonumber(cfg.widthPx or cfg.width) or 140
    local h = tonumber(cfg.heightPx or cfg.height) or 6
    local x = tonumber(cfg.x) or 0
    local y = tonumber(cfg.y) or -8

    local anchorTo = _G.Minimap or UIParent
    local point = cfg.point or "TOP"
    local relPoint = cfg.relPoint or "BOTTOM"

    f:ClearAllPoints()
    if Pixel and Pixel.SetPointPx then
        Pixel:SetPointPx(f, point, anchorTo, relPoint, x, y)
    else
        f:SetPoint(point, anchorTo, relPoint, x, y)
    end

    if Pixel and Pixel.SetSizePx then
        Pixel:SetSizePx(f, w, h)
    else
        f:SetSize(w, h)
    end

    -- colors
    local bg = cfg.bgRGBA or {0,0,0,0.35}
    f.bg:SetVertexColor(bg[1] or 0, bg[2] or 0, bg[3] or 0, bg[4] or 0.35)

    local xp = cfg.xpRGBA or {0.6, 0.0, 1.0, 1}
    f.bar:SetStatusBarColor(xp[1] or 0.6, xp[2] or 0.0, xp[3] or 1.0, xp[4] or 1)

    local rxp = cfg.restedRGBA or {0.2, 0.6, 1.0, 0.5}
    f.rested:SetStatusBarColor(rxp[1] or 0.2, rxp[2] or 0.6, rxp[3] or 1.0, rxp[4] or 0.5)

    if Border and Border.Update then
        Border:Update(f, tonumber(cfg.borderPx) or 1, cfg.borderRGBA or {0,0,0,1})
    end
end

local function UpdateXP()
    local cfg = GetCfg()
    if not cfg then return end
    local f = EnsureBar()

    -- Re-apply layout if config changed (size/pos/anchor)
    local w = tonumber(cfg.widthPx or cfg.width) or 220
    local h = tonumber(cfg.heightPx or cfg.height) or 10
    local x = tonumber(cfg.x) or 0
    local y = tonumber(cfg.y) or -8
    local point = cfg.point or "TOP"
    local relPoint = cfg.relPoint or "BOTTOM"

    if f.__nolXP_w ~= w or f.__nolXP_h ~= h or f.__nolXP_x ~= x or f.__nolXP_y ~= y
        or f.__nolXP_point ~= point or f.__nolXP_relPoint ~= relPoint
    then
        f.__nolXP_w, f.__nolXP_h, f.__nolXP_x, f.__nolXP_y = w, h, x, y
        f.__nolXP_point, f.__nolXP_relPoint = point, relPoint
        ApplyLayout()
    end

    if cfg.enabled == false then
        f:Hide()
        return
    end

    if AtMaxLevel() then
        f:Hide()
        return
    end

    local xp = UnitXP("player") or 0
    local max = UnitXPMax("player") or 1
    if max <= 0 then max = 1 end

    f.bar:SetMinMaxValues(0, max)
    f.bar:SetValue(xp)

    local rest = GetXPExhaustion and GetXPExhaustion() or 0
    if rest and rest > 0 then
        local v = xp + rest
        if v > max then v = max end
        f.rested:SetMinMaxValues(0, max)
        f.rested:SetValue(v)
        f.rested:Show()
    else
        f.rested:Hide()
    end

    f:Show()
end

function X:Enable()
    if self.__enabled then return end
    self.__enabled = true

    EnsureBar()
    ApplyLayout()
    UpdateXP()

    local f = CreateFrame("Frame")
    self.__driver = f

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_LEVEL_UP")
    f:RegisterEvent("PLAYER_XP_UPDATE")
    f:RegisterEvent("UPDATE_EXHAUSTION")
    f:RegisterEvent("ENABLE_XP_GAIN")
    f:RegisterEvent("DISABLE_XP_GAIN")
    f:RegisterEvent("UI_SCALE_CHANGED")
    f:RegisterEvent("DISPLAY_SIZE_CHANGED")

    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD"
            or event == "UI_SCALE_CHANGED"
            or event == "DISPLAY_SIZE_CHANGED"
        then
            ApplyLayout()
        end
        UpdateXP()
    end)
  end
