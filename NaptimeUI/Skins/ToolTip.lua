-- Skins/Tooltip.lua
local ADDON, ns = ...
ns = ns or {}

ns.Skins = ns.Skins or {}
ns.Skins.Tooltip = ns.Skins.Tooltip or {}
local T = ns.Skins.Tooltip

local Border = ns.Border
local Pixel  = ns.Pixel

local WHITE = "Interface\\Buttons\\WHITE8X8"

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    return (type(cfg) == "table") and cfg or nil
end

-- Safe hook: only hook scripts the frame actually supports
local function SafeHook(tt, script, fn)
    if not (tt and tt.HookScript and tt.HasScript) then return end
    if tt:HasScript(script) then
        pcall(tt.HookScript, tt, script, fn)
    end
end

local function KillRegion(r)
    if not r then return end
    if r.SetTexture then pcall(r.SetTexture, r, nil) end
    if r.SetAtlas then pcall(r.SetAtlas, r, nil) end
    if r.SetColorTexture then pcall(r.SetColorTexture, r, 0,0,0,0) end
    if r.SetAlpha then pcall(r.SetAlpha, r, 0) end
    if r.Hide then pcall(r.Hide, r) end
end

local function StripNineSlice(tt)
    if not tt then return end

    -- DF+ tooltips
    if tt.NineSlice then
        tt.NineSlice:SetAlpha(0)
        tt.NineSlice:Hide()
    end

    -- common overlays on GameTooltip
    KillRegion(tt.TopOverlay)
    KillRegion(tt.BottomOverlay)
end

local function EnsureBG(frame)
    if not frame then return end
    if frame.__nolTipBG then return end

    -- Use ARTWORK so it's above Blizzard's NineSlice BACKGROUND, but behind text
    local bg = frame:CreateTexture(nil, "ARTWORK", nil, -8)
    bg:SetTexture(WHITE)
    bg:SetAllPoints(frame)
    frame.__nolTipBG = bg
end

local function ApplyTooltipFrameSkin(tt)
    if not tt then return end

    if Pixel and Pixel.Enforce then
        Pixel:Enforce(tt)
    end

    -- Hide Blizzard art
    StripNineSlice(tt)

    -- Remove Backdrop (some tooltips still use it)
    if tt.SetBackdrop then pcall(tt.SetBackdrop, tt, nil) end
    if tt.SetBackdropColor then pcall(tt.SetBackdropColor, tt, 0,0,0,0) end
    if tt.SetBackdropBorderColor then pcall(tt.SetBackdropBorderColor, tt, 0,0,0,0) end

    -- Our custom bg
    EnsureBG(tt)
    local cfg = GetCfg() or {}
    local c = cfg.tipRGBA or { 0.05, 0.05, 0.05, 0.90 }

    if tt.__nolTipBG then
        -- if something else cleared it somehow, restore texture
        if tt.__nolTipBG.SetTexture then tt.__nolTipBG:SetTexture(WHITE) end
        tt.__nolTipBG:SetVertexColor(c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1)
        tt.__nolTipBG:Show()
    end

    -- Border
    if Border and Border.Apply then
        Border:Apply(tt, (cfg.tipBorderPx or cfg.borderPx or 1), (cfg.tipBorderRGBA or cfg.borderRGBA or {0,0,0,1}))
    end
    if Border and Border.Update then
        Border:Update(tt, (cfg.tipBorderPx or cfg.borderPx or 1), (cfg.tipBorderRGBA or cfg.borderRGBA or {0,0,0,1}))
    end
end

local function ApplyStatusBarSkin(tt)
    if not tt then return end

    local sb = tt.StatusBar or _G[tt:GetName() and (tt:GetName() .. "StatusBar") or ""]
    if not sb then return end

    if sb.SetStatusBarTexture then
        sb:SetStatusBarTexture(WHITE)
    end

    -- keep Blizzard coloring (reaction/class) – don't override color
    sb:SetHeight(8)

    if Pixel and Pixel.Enforce then
        Pixel:Enforce(sb)
    end

    if Border and Border.Apply then
        Border:Apply(sb, 1, {0,0,0,1})
    end
    if Border and Border.Update then
        Border:Update(sb, 1, {0,0,0,1})
    end
end

local function SkinTooltip(tt)
    if not tt then return end

    ApplyTooltipFrameSkin(tt)
    ApplyStatusBarSkin(tt)

    if tt.__nolTipSkinned then return end
    tt.__nolTipSkinned = true

    SafeHook(tt, "OnShow", function(self)
        ApplyTooltipFrameSkin(self)
        ApplyStatusBarSkin(self)
    end)

    SafeHook(tt, "OnTooltipSetUnit", function(self)
        ApplyTooltipFrameSkin(self)
        ApplyStatusBarSkin(self)
    end)

    SafeHook(tt, "OnTooltipSetItem", function(self)
        ApplyTooltipFrameSkin(self)
        ApplyStatusBarSkin(self)
    end)
end

function T:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local tooltips = {
        _G.GameTooltip,
        _G.ItemRefTooltip,
        _G.ShoppingTooltip1,
        _G.ShoppingTooltip2,
        _G.ShoppingTooltip3,
        _G.WorldMapTooltip,
        _G.EmbeddedItemTooltip,
    }

    for _, tt in ipairs(tooltips) do
        if tt then SkinTooltip(tt) end
    end

    -- Some tooltips are created later; re-run once on enter world
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function()
        for _, tt in ipairs(tooltips) do
            if tt then SkinTooltip(tt) end
        end
    end)
end
