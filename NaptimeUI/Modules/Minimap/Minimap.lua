-- Modules/Minimap.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.Minimap = ns.Modules.Minimap or {}
local M = ns.Modules.Minimap

local Pixel  = ns.Pixel
local Border = ns.Border

local WHITE = "Interface\\Buttons\\WHITE8X8"

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function GetRootCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    return (type(cfg) == "table") and cfg or nil
end

local function GetCfg()
    local cfg = GetRootCfg()
    if not cfg then return nil end
    return (type(cfg.minimap) == "table") and cfg.minimap or nil
end

local function EnsureContainer(name)
    local f = _G[name]
    if f then return f end

    f = CreateFrame("Frame", name, UIParent)
    f:SetClampedToScreen(true)
    f:EnableMouse(false)
    _G[name] = f

    if Pixel and Pixel.Enforce then
        Pixel:Enforce(f)
    end

    return f
end

local function EnsureBG(frame)
    if not frame or frame.__nolMMBG then return end
    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetTexture(WHITE)
    bg:SetAllPoints(frame)
    frame.__nolMMBG = bg
end

local function ApplyShadow(frame, isMinimap)
    if not frame or not ns.Shadow then return end

    local rootCfg = GetRootCfg()
    local scfg = rootCfg and rootCfg.shadow or nil
    if type(scfg) == "table" and scfg.enabled == false then
        if ns.Shadow.Hide then
            ns.Shadow:Hide(frame)
        end
        return
    end

    local inset = (scfg and scfg.inset) or 24
    local alpha = (scfg and scfg.alpha) or 0.60

    -- minimap beta: use much smaller spread for the bar-shaped shadow
    if isMinimap then
        inset = 8
    end

    if ns.Shadow.Apply then
        ns.Shadow:Apply(frame, {
            alpha = alpha,
            inset = inset,
        })
    end
end

local function GetFontPath(fontKey)
    if ns.GetFont then
        local path = ns:GetFont(fontKey)
        if path then return path end
    end
    return "Fonts\\FRIZQT__.TTF"
end

local function ApplyFontString(fs, fontKey, size, flags, rgba)
    if not fs or not fs.SetFont then return end
    fs:SetFont(GetFontPath(fontKey), size or 12, flags or "")
    if rgba and fs.SetTextColor then
        fs:SetTextColor(rgba[1] or 1, rgba[2] or 1, rgba[3] or 1, rgba[4] or 1)
    end
    if fs.SetDrawLayer then
        pcall(fs.SetDrawLayer, fs, "OVERLAY")
    end
end

local function ApplyFontStringNoColor(fs, fontKey, size, flags)
    if not fs or not fs.SetFont then return end
    fs:SetFont(GetFontPath(fontKey), size or 12, flags or "")
    if fs.SetDrawLayer then
        pcall(fs.SetDrawLayer, fs, "OVERLAY")
    end
end

local function FindFirstFontString(frame)
    if not frame or not frame.GetRegions then return nil end
    for _, r in ipairs({ frame:GetRegions() }) do
        if r and r.GetObjectType and r:GetObjectType() == "FontString" then
            return r
        end
    end
    return nil
end

local function HideObject(obj)
    if not obj then return end
    if obj.SetTexture then pcall(obj.SetTexture, obj, nil) end
    if obj.SetAtlas then pcall(obj.SetAtlas, obj, nil) end
    if obj.SetAlpha then pcall(obj.SetAlpha, obj, 0) end
    if obj.Hide then pcall(obj.Hide, obj) end
    if obj.SetShown then pcall(obj.SetShown, obj, false) end
end

local function Kill(obj)
    if not obj then return end
    if obj.__nolKilled then
        HideObject(obj)
        return
    end
    obj.__nolKilled = true

    HideObject(obj)

    if obj.HookScript then
        pcall(obj.HookScript, obj, "OnShow", function(self)
            HideObject(self)
        end)
    end
    if obj.Show then
        pcall(hooksecurefunc, obj, "Show", function(self)
            HideObject(self)
        end)
    end
end

local function Restore(obj)
    if not obj then return end
    obj.__nolKilled = nil
    if obj.SetAlpha then pcall(obj.SetAlpha, obj, 1) end
    if obj.SetShown then pcall(obj.SetShown, obj, true) end
    if obj.Show then pcall(obj.Show, obj) end
end

local function RaiseAboveMinimap(elem, mm, extraLevel)
    if not elem or not mm then return end
    extraLevel = extraLevel or 50

    if elem.SetFrameStrata then
        pcall(elem.SetFrameStrata, elem, "MEDIUM")
    end
    if elem.SetFrameLevel and mm.GetFrameLevel then
        local lvl = (mm:GetFrameLevel() or 0) + extraLevel
        pcall(elem.SetFrameLevel, elem, lvl)
    end

    if elem.GetObjectType and elem:GetObjectType() == "FontString" then
        if elem.SetDrawLayer then
            pcall(elem.SetDrawLayer, elem, "OVERLAY")
        end
    end

    if elem.GetRegions then
        for _, r in ipairs({ elem:GetRegions() }) do
            if r and r.GetObjectType and r:GetObjectType() == "FontString" then
                if r.SetDrawLayer then
                    pcall(r.SetDrawLayer, r, "OVERLAY")
                end
            end
        end
    end
end

local function PlaceElement(elem, parent, cfgElem)
    if not elem or not parent then return end
    if cfgElem and cfgElem.hide == true then
        Kill(elem)
        return
    end

    Restore(elem)

    if not cfgElem then return end
    if not (elem.ClearAllPoints and elem.SetPoint) then return end

    if elem.SetParent then
        pcall(elem.SetParent, elem, parent)
    end

    local p  = cfgElem.point or "TOPRIGHT"
    local rp = cfgElem.relPoint or p
    local x  = tonumber(cfgElem.x) or 0
    local y  = tonumber(cfgElem.y) or 0

    elem:ClearAllPoints()
    elem:SetPoint(p, parent, rp, x, y)

    if elem.SetAlpha then pcall(elem.SetAlpha, elem, 1) end
    if elem.Show then pcall(elem.Show, elem) end
    RaiseAboveMinimap(elem, parent, 60)
end

local function GetInstanceDifficultyFrame()
    return _G.MiniMapInstanceDifficulty
        or (_G.MinimapCluster and _G.MinimapCluster.InstanceDifficulty)
        or _G.MiniMapChallengeMode
end

local function GetGuildDifficultyFrame()
    return _G.GuildInstanceDifficulty
        or (_G.MinimapCluster and _G.MinimapCluster.GuildInstanceDifficulty)
end

local function GetTrackingButton()
    return _G.MiniMapTrackingButton
        or _G.MiniMapTracking
        or (_G.MinimapCluster and _G.MinimapCluster.Tracking and _G.MinimapCluster.Tracking.Button)
end

local function KillRoundArt()
    Kill(_G.MinimapBorder)
    Kill(_G.MinimapBorderTop)
    Kill(_G.MinimapNorthTag)
    Kill(_G.MinimapCompassTexture)

    Kill(_G.Minimap.ZoomIn)
    Kill(_G.Minimap.ZoomOut)

    Kill(_G.MiniMapTracking)
    Kill(_G.MiniMapTrackingButton)
    if _G.MinimapCluster and _G.MinimapCluster.Tracking then
        Kill(_G.MinimapCluster.Tracking.Background)
    end

    Kill(_G.GameTimeFrame)
    Kill(_G.AddonCompartmentFrame)
    Kill(_G.AddonCompartmentFrame.Text)

    if _G.MinimapCluster then
        Kill(_G.MinimapCluster.BorderTop)
    end

    if _G.Minimap and _G.Minimap.GetRegions then
        for _, r in ipairs({ _G.Minimap:GetRegions() }) do
            if r and r.GetObjectType and r:GetObjectType() == "Texture" then
                local tex = r.GetTexture and r:GetTexture()
                if type(tex) == "string" then
                    local t = tex:lower()
                    if t:find("minimap") and (t:find("border") or t:find("ring") or t:find("compass") or t:find("north") or t:find("mask")) then
                        Kill(r)
                    end
                    if t:find("ui%-minimap") or (t:find("hud") and t:find("minimap")) then
                        Kill(r)
                    end
                end
            end
        end
    end
end

local function ApplyAll()
    if InCombat() then return end

    local rootCfg = GetRootCfg()
    local mmCfg = GetCfg()
    if not rootCfg or not mmCfg then return end

    local sizePx = tonumber(mmCfg.sizePx) or 180

    local c = EnsureContainer("NOL_Minimap")
    c:ClearAllPoints()
    c:SetFrameStrata("LOW")
    c:SetFrameLevel(5)

    if Pixel and Pixel.SetPointPx then
        Pixel:SetPointPx(
            c,
            mmCfg.point or "TOPRIGHT",
            UIParent,
            mmCfg.relPoint or (mmCfg.point or "TOPRIGHT"),
            mmCfg.x or -20,
            mmCfg.y or -20
        )
    else
        c:SetPoint(mmCfg.point or "TOPRIGHT", UIParent, mmCfg.relPoint or (mmCfg.point or "TOPRIGHT"), mmCfg.x or -20, mmCfg.y or -20)
    end

    if Pixel and Pixel.SetSizePx then
        Pixel:SetSizePx(c, sizePx, sizePx)
    else
        c:SetSize(sizePx, sizePx)
    end

    EnsureBG(c)
    local bg = mmCfg.bgRGBA or rootCfg.bgRGBA or { 0.08, 0.08, 0.08, 0.65 }
    if c.__nolMMBG then
        c.__nolMMBG:SetVertexColor(bg[1] or 0, bg[2] or 0, bg[3] or 0, bg[4] or 1)
        c.__nolMMBG:Show()
    end

    ApplyShadow(c, true)

    local bpx = mmCfg.borderPx or rootCfg.borderPx or 1
    local brgba = mmCfg.borderRGBA or rootCfg.borderRGBA or {0,0,0,1}
    if Border and Border.Apply then Border:Apply(c, bpx, brgba) end
    if Border and Border.Update then Border:Update(c, bpx, brgba) end

    if not _G.Minimap then return end
    local mm = _G.Minimap

    mm:SetParent(c)
    mm:ClearAllPoints()
    mm:SetPoint("CENTER", c, "CENTER", 0, 0)
    mm:SetFrameStrata("LOW")
    mm:SetFrameLevel((c:GetFrameLevel() or 0) + 1)

    if Pixel and Pixel.SetSizePx then
        Pixel:SetSizePx(mm, sizePx, sizePx)
    else
        mm:SetSize(sizePx, sizePx)
    end

    if mm.SetMaskTexture then
        mm:SetMaskTexture(WHITE)
    end

    if type(_G.GetMinimapShape) == "function" and type(_G.SetMinimapShape) == "function" then
        pcall(_G.SetMinimapShape, "SQUARE")
    end

    KillRoundArt()

    PlaceElement(GetInstanceDifficultyFrame(), mm, mmCfg.instanceDifficulty)
    PlaceElement(GetGuildDifficultyFrame(), mm, mmCfg.guildDifficulty)
    PlaceElement(GetTrackingButton(), mm, mmCfg.tracking)
    PlaceElement(_G.TimeManagerClockButton, mm, mmCfg.clock)

    local zoneBtn = _G.MinimapZoneTextButton or _G.MinimapZoneText
    PlaceElement(zoneBtn, mm, mmCfg.zoneText)

    if _G.MinimapZoneText then
        RaiseAboveMinimap(_G.MinimapZoneText, mm, 80)
    end

    local fcfg = mmCfg.font or {}
    local fontKey   = fcfg.name or "Primary"
    local clockSize = tonumber(fcfg.clockSize) or 12
    local zoneSize  = tonumber(fcfg.zoneSize) or 12
    local flags     = fcfg.flags or "OUTLINE"
    local rgba      = fcfg.rgba or {1,1,1,1}

    if _G.TimeManagerClockButton then
        local t = _G.TimeManagerClockButton.Text or FindFirstFontString(_G.TimeManagerClockButton)
        ApplyFontString(t, fontKey, clockSize, flags, rgba)
    end

    if _G.MinimapZoneText then
        ApplyFontStringNoColor(_G.MinimapZoneText, fontKey, zoneSize, flags)
        if _G.MinimapZoneText.SetJustifyH then
            _G.MinimapZoneText:SetJustifyH("CENTER")
        end
    elseif _G.MinimapZoneTextButton then
        local zt = FindFirstFontString(_G.MinimapZoneTextButton)
        ApplyFontStringNoColor(zt, fontKey, zoneSize, flags)
        if zt and zt.SetJustifyH then
            zt:SetJustifyH("CENTER")
        end
    end

    if _G.MinimapZoneTextButton then
        _G.MinimapZoneTextButton:SetWidth(0)
    end

    c:Show()
end

function M:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local f = CreateFrame("Frame")
    self.__driver = f

    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UI_SCALE_CHANGED")
    f:RegisterEvent("DISPLAY_SIZE_CHANGED")
    f:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("ZONE_CHANGED")
    f:RegisterEvent("ZONE_CHANGED_INDOORS")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if InCombat() then return end
            C_Timer.After(0, ApplyAll)
            return
        end
        if InCombat() then return end
        C_Timer.After(0, ApplyAll)
    end)

    if not InCombat() then
        C_Timer.After(0, ApplyAll)
    end
end
