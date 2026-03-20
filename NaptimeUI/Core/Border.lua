local ADDON, ns = ...
ns = ns or {}

ns.Border = ns.Border or {}
local Border = ns.Border
local Pixel = ns.Pixel

local WHITE = "Interface\\Buttons\\WHITE8X8"

local function EnsureTex(frame, key, layer, sub)
    local t = frame[key]
    if t then return t end
    t = frame:CreateTexture(nil, layer or "OVERLAY", nil, sub or 0)
    t:SetTexture(WHITE)
    frame[key] = t
    return t
end

-- Apply an Orbit-style 4-edge border made of solid 1px textures (no Backdrop)
-- thicknessPx is PHYSICAL pixels
function Border:Apply(frame, thicknessPx, rgba)
    if not frame then return end
    if frame.__nolBorder then
        -- update only
        self:Update(frame, thicknessPx, rgba)
        return frame.__nolBorder
    end

    local b = CreateFrame("Frame", nil, frame)
    b:SetAllPoints(frame)
    b:SetFrameLevel((frame:GetFrameLevel() or 0) + 10) -- over icon/bg
    b:EnableMouse(false)

    b.Top    = EnsureTex(b, "Top", "OVERLAY", 1)
    b.Bottom = EnsureTex(b, "Bottom", "OVERLAY", 1)
    b.Left   = EnsureTex(b, "Left", "OVERLAY", 1)
    b.Right  = EnsureTex(b, "Right", "OVERLAY", 1)

    frame.__nolBorder = b
    self:Update(frame, thicknessPx, rgba)
    return b
end

function Border:Update(frame, thicknessPx, rgba)
    local b = frame and frame.__nolBorder
    if not b then return end

    local s = frame.GetEffectiveScale and frame:GetEffectiveScale() or UIParent:GetEffectiveScale()
    local t = Pixel and Pixel.Multiple and Pixel:Multiple(thicknessPx or 1, s) or (thicknessPx or 1)

    -- Safety: never 0
    if not t or t <= 0 then t = 1 end

    local r,g,bl,a = 0,0,0,1
    if rgba then r,g,bl,a = rgba[1] or 0, rgba[2] or 0, rgba[3] or 0, rgba[4] or 1 end

    for _, tex in pairs({b.Top,b.Bottom,b.Left,b.Right}) do
        tex:SetVertexColor(r,g,bl,a)
        tex:Show()
    end

    b.Top:ClearAllPoints()
    b.Top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    b.Top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    b.Top:SetHeight(t)

    b.Bottom:ClearAllPoints()
    b.Bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    b.Bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    b.Bottom:SetHeight(t)

    b.Left:ClearAllPoints()
    b.Left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    b.Left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    b.Left:SetWidth(t)

    b.Right:ClearAllPoints()
    b.Right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    b.Right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    b.Right:SetWidth(t)
end
