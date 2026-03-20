local ADDON, ns = ...
ns = ns or {}

ns.Pixel = ns.Pixel or {}
local Pixel = ns.Pixel

-- Physical pixel scale cached: logical units per physical pixel at scale=1
local SCREEN_SCALE = 1

local function UpdateScreenScale()
    local _, physicalHeight = GetPhysicalScreenSize()
    if not physicalHeight or physicalHeight == 0 then
        -- safe fallback
        SCREEN_SCALE = 768 / 1080
    else
        SCREEN_SCALE = 768 / physicalHeight
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("DISPLAY_SIZE_CHANGED")
f:RegisterEvent("UI_SCALE_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", UpdateScreenScale)
UpdateScreenScale()

function Pixel:GetScale()
    return SCREEN_SCALE
end

-- Snap logical value to nearest physical pixel at given effective scale
function Pixel:Snap(value, scale)
    if not value then return 0 end
    local frameScale = tonumber(scale) or 1
    if frameScale < 0.01 then frameScale = 1 end
    local step = SCREEN_SCALE / frameScale
    return math.floor(value / step + 0.5) * step
end

-- Convert physical pixels -> logical units at given effective scale
function Pixel:Multiple(count, scale)
    local frameScale = tonumber(scale) or 1
    if frameScale < 0.01 then frameScale = 1 end
    return (tonumber(count) or 0) * SCREEN_SCALE / frameScale
end

function Pixel:SetSizePx(frame, wPx, hPx)
    if not frame then return end
    local s = frame.GetEffectiveScale and frame:GetEffectiveScale() or UIParent:GetEffectiveScale()
    frame:SetSize(self:Multiple(wPx, s), self:Multiple(hPx, s))
end

function Pixel:SetPointPx(frame, point, rel, relPoint, xPx, yPx)
    if not frame then return end
    rel = rel or UIParent
    relPoint = relPoint or point
    local s = frame.GetEffectiveScale and frame:GetEffectiveScale() or UIParent:GetEffectiveScale()
    local x = self:Multiple(xPx or 0, s)
    local y = self:Multiple(yPx or 0, s)
    frame:SetPoint(point, rel, relPoint, x, y)
end

-- Optional: snap texture to pixel grid (helps with 1px edges)
function Pixel:SnapTexture(tex)
    if not (tex and tex.GetParent and tex.SetTexCoord) then return end
    -- no-op placeholder: WoW textures don't have position snapping, but leaving hook for future
end

-- Enforce pixel-perfect sizing by snapping SetSize/SetWidth/SetHeight inputs
function Pixel:Enforce(frame)
    if not frame or frame.__nolEnforced then return end
    frame.__nolEnforced = true

    if not frame.__nolNativeSetWidth then
        frame.__nolNativeSetWidth = frame.SetWidth
        frame.SetWidth = function(self, width)
            local snapped = Pixel:Snap(width, self:GetEffectiveScale())
            self:__nolNativeSetWidth(snapped)
        end
    end
    if not frame.__nolNativeSetHeight then
        frame.__nolNativeSetHeight = frame.SetHeight
        frame.SetHeight = function(self, height)
            local snapped = Pixel:Snap(height, self:GetEffectiveScale())
            self:__nolNativeSetHeight(snapped)
        end
    end
    if not frame.__nolNativeSetSize then
        frame.__nolNativeSetSize = frame.SetSize
        frame.SetSize = function(self, width, height)
            local s = self:GetEffectiveScale()
            self:__nolNativeSetSize(Pixel:Snap(width, s), Pixel:Snap(height, s))
        end
    end

    local w, h = frame:GetSize()
    if w and h then frame:SetSize(w, h) end
end
