-- Core/Shadow.lua
local ADDON, ns = ...
ns = ns or {}

ns.Shadow = ns.Shadow or {}
local Shadow = ns.Shadow

local function GetTexture()
    return ns.Media and ns.Media.textures and ns.Media.textures.Shadow
end

local function NormalizeAlpha(alpha)
    alpha = tonumber(alpha)
    if not alpha then return 0.60 end
    if alpha > 1 then
        alpha = alpha / 100
    end
    if alpha < 0 then alpha = 0 end
    if alpha > 1 then alpha = 1 end
    return alpha
end

local function NormalizeSize(v, default)
    v = tonumber(v)
    if not v or v <= 0 then return default end
    return v
end

function Shadow:Apply(frame, opts)
    if not frame then return end

    local edgeFile = GetTexture()
    if not edgeFile or edgeFile == "" then return end

    local alpha    = NormalizeAlpha(type(opts) == "table" and opts.alpha or 0.60)
    local size     = NormalizeSize(type(opts) == "table" and opts.size, 4)
    local offset   = NormalizeSize(type(opts) == "table" and opts.offset, size)
    local bgAlpha  = tonumber(type(opts) == "table" and opts.bgAlpha) or 0
    local r        = tonumber(type(opts) == "table" and opts.r) or 0
    local g        = tonumber(type(opts) == "table" and opts.g) or 0
    local b        = tonumber(type(opts) == "table" and opts.b) or 0

    if not frame.__nolShadowFrame then
        local sf = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
        sf:EnableMouse(false)
        frame.__nolShadowFrame = sf
    end

    local sf = frame.__nolShadowFrame
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset, offset)
    sf:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset, -offset)

    if sf.SetFrameStrata and frame.GetFrameStrata then
        sf:SetFrameStrata(frame:GetFrameStrata())
    end
    if sf.SetFrameLevel and frame.GetFrameLevel then
        sf:SetFrameLevel(math.max(0, (frame:GetFrameLevel() or 1) - 1))
    end

    sf:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = edgeFile,
        tile = false,
        edgeSize = size,
        insets = {
            left = size,
            right = size,
            top = size,
            bottom = size,
        },
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
