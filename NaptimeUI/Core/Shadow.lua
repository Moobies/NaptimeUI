-- Core/Shadow.lua
local ADDON, ns = ...
ns = ns or {}

ns.Shadow = ns.Shadow or {}
local Shadow = ns.Shadow

-- -------------------------------------------------------
-- Helpers
-- -------------------------------------------------------

local function GetTexture()
    return ns.Media and ns.Media.textures and ns.Media.textures.Shadow
end

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return {} end
    return type(cfg.shadow) == "table" and cfg.shadow or {}
end

local function IsEnabled()
    local scfg = GetCfg()
    return scfg.enabled ~= false
end

local function NormalizeAlpha(v, default)
    v = tonumber(v)
    if not v then return default or 0.60 end
    if v > 1 then v = v / 100 end
    return math.max(0, math.min(1, v))
end

local function NormalizeSize(v, default)
    v = tonumber(v)
    if not v or v <= 0 then return default or 4 end
    return v
end

-- -------------------------------------------------------
-- Core
-- -------------------------------------------------------

function Shadow:Apply(frame, opts)
    if not frame then return end
    if not IsEnabled() then
        self:Hide(frame)
        return
    end

    local edgeFile = GetTexture()
    if not edgeFile or edgeFile == "" then return end

    opts = type(opts) == "table" and opts or {}
    local scfg = GetCfg()

    local alpha   = NormalizeAlpha(opts.alpha  or scfg.alpha,  0.60)
    local size    = NormalizeSize( opts.size   or scfg.size,   4)
    local offset  = NormalizeSize( opts.offset or scfg.offset, size)
    local bgAlpha = tonumber(opts.bgAlpha) or 0
    local r       = tonumber(opts.r) or 0
    local g       = tonumber(opts.g) or 0
    local b       = tonumber(opts.b) or 0

    if not frame.__nolShadowFrame then
        local sf = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
        sf:EnableMouse(false)
        frame.__nolShadowFrame = sf
    end

    local sf = frame.__nolShadowFrame

    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT",     frame, "TOPLEFT",     -offset,  offset)
    sf:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",  offset, -offset)

    if frame.GetFrameStrata then
        sf:SetFrameStrata(frame:GetFrameStrata())
    end
    if frame.GetFrameLevel then
        sf:SetFrameLevel(math.max(0, (frame:GetFrameLevel() or 1) - 1))
    end

    sf:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = edgeFile,
        tile     = false,
        edgeSize = size,
        insets   = { left = size, right = size, top = size, bottom = size },
    })

    sf:SetBackdropColor(0, 0, 0, bgAlpha)
    sf:SetBackdropBorderColor(r, g, b, alpha)
    sf:Show()
end

function Shadow:Update(frame, opts)
    self:Apply(frame, opts)
end

function Shadow:Hide(frame)
    if frame and frame.__nolShadowFrame then
        frame.__nolShadowFrame:Hide()
    end
end
