-- Modules/VehicleExit.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.VehicleExit = ns.Modules.VehicleExit or {}
local V = ns.Modules.VehicleExit

local Pixel  = ns.Pixel
local Border = ns.Border

local WHITE = "Interface\\Buttons\\WHITE8X8"

local function GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return nil end
    if type(cfg.actionbars) ~= "table" then return nil end
    return cfg.actionbars
end

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function GetButton()
    return _G.MainMenuBarVehicleLeaveButton
        or _G.VehicleMenuBarLeaveButton
        or _G.OverrideActionBarLeaveFrameLeaveButton
        or _G.OverrideActionBarLeaveFrame
end

local function CanShowVehicleExit()
    if UnitOnTaxi and UnitOnTaxi("player") then
        return false
    end

    if CanExitVehicle and CanExitVehicle() then
        return true
    end

    if UnitHasVehicleUI and UnitHasVehicleUI("player") then
        return true
    end

    if UnitInVehicle and UnitInVehicle("player") then
        return true
    end

    return false
end

local function ForceShow(obj)
    if not obj then return end
    if obj.SetAlpha then pcall(obj.SetAlpha, obj, 1) end
    if obj.Show then pcall(obj.Show, obj) end
end

local function UnhideObject(obj)
    if not obj then return end

    obj.__nolKeepHidden = nil
    obj.__nolKilled = nil

    if obj.SetAlpha then pcall(obj.SetAlpha, obj, 1) end
    if obj.SetShown then pcall(obj.SetShown, obj, true) end
    if obj.Show then pcall(obj.Show, obj) end
end

local function ApplyIconZoom(icon, zoom)
    if not (icon and icon.SetTexCoord) then return end
    local z = tonumber(zoom) or 0.10
    if z < 0 then z = 0 end
    if z > 0.35 then z = 0.35 end
    icon:SetTexCoord(z, 1 - z, z, 1 - z)
end

local function SetSizePx(frame, w, h)
    if not frame then return end
    if Pixel and Pixel.SetSizePx then
        Pixel:SetSizePx(frame, w, h)
    else
        frame:SetSize(w, h)
    end
end

local function SetPointPx(frame, point, rel, relPoint, x, y)
    if not frame then return end
    frame:ClearAllPoints()
    if Pixel and Pixel.SetPointPx then
        Pixel:SetPointPx(frame, point, rel, relPoint, x, y)
    else
        frame:SetPoint(point, rel, relPoint, x or 0, y or 0)
    end
end

local function EnsureSkinFrame(btn)
    if btn.__nolVehicleExitSkin then
        return btn.__nolVehicleExitSkin
    end

    local sf = CreateFrame("Frame", nil, btn)
    sf:SetAllPoints(btn)
    sf:SetFrameLevel((btn:GetFrameLevel() or 1) + 1)
    sf:EnableMouse(false)

    if Pixel and Pixel.Enforce then
        Pixel:Enforce(sf)
    end

    local bg = sf:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetTexture(WHITE)
    bg:SetAllPoints(sf)
    sf.__bg = bg

    btn.__nolVehicleExitSkin = sf
    return sf
end

local function HideObj(obj)
    if not obj then return end
    if obj.Hide then pcall(obj.Hide, obj) end
    if obj.SetAlpha then pcall(obj.SetAlpha, obj, 0) end
end

local function KillObj(obj)
    if not obj or obj.__nolVehicleExitKilled then return end
    obj.__nolVehicleExitKilled = true

    HideObj(obj)

    if obj.HookScript then
        pcall(obj.HookScript, obj, "OnShow", function(self) HideObj(self) end)
    end
    if obj.Show then
        pcall(hooksecurefunc, obj, "Show", function(self) HideObj(self) end)
    end
end

local function StripButtonArt(btn)
    if not btn then return end

    local keys = {
        "NormalTexture", "normalTexture",
        "PushedTexture", "pushedTexture",
        "HighlightTexture", "highlightTexture",
        "CheckedTexture", "checkedTexture",
        "Border", "border",
        "Background", "background",
        "Flash", "flash",
        "Shadow", "shadow",
    }

    for _, k in ipairs(keys) do
        local obj = btn[k]
        if obj then KillObj(obj) end
    end

    if btn.GetNormalTexture then
        local t = btn:GetNormalTexture()
        if t then KillObj(t) end
        pcall(btn.SetNormalTexture, btn, nil)
    end
    if btn.GetPushedTexture then
        local t = btn:GetPushedTexture()
        if t then KillObj(t) end
        pcall(btn.SetPushedTexture, btn, nil)
    end
    if btn.GetHighlightTexture then
        local t = btn:GetHighlightTexture()
        if t then KillObj(t) end
        pcall(btn.SetHighlightTexture, btn, nil)
    end
    if btn.GetCheckedTexture then
        local t = btn:GetCheckedTexture()
        if t then KillObj(t) end
        pcall(btn.SetCheckedTexture, btn, nil)
    end
end

local function GetButtonIcon(btn)
    return btn.icon
        or btn.Icon
        or btn.IconTexture
        or (btn.GetName and _G[btn:GetName() .. "Icon"])
end

local function StyleButton(btn)
    if not btn then return end

    local ab = GetCfg()
    if not ab then return end
    local vcfg = type(ab.vehicleExit) == "table" and ab.vehicleExit or nil
    if not vcfg then return end

    if Pixel and Pixel.Enforce and not btn.__nolVehicleExitPixelEnforced then
        btn.__nolVehicleExitPixelEnforced = true
        Pixel:Enforce(btn)
    end

    StripButtonArt(btn)

    local size = tonumber(vcfg.sizePx) or 36
    SetSizePx(btn, size, size)

    local sf = EnsureSkinFrame(btn)

    local bgc = vcfg.bgRGBA or {0.08, 0.08, 0.08, 0.75}
    sf.__bg:SetVertexColor(bgc[1] or 0.08, bgc[2] or 0.08, bgc[3] or 0.08, bgc[4] or 0.75)
    sf.__bg:Show()

    local borderPx = tonumber(vcfg.borderPx) or 1
    local borderRGBA = vcfg.borderRGBA or {0, 0, 0, 1}

    if Border and Border.Apply then
        if not sf.__nolBorderApplied then
            sf.__nolBorderApplied = true
            Border:Apply(sf, borderPx, borderRGBA)
        elseif Border.Update then
            Border:Update(sf, borderPx, borderRGBA)
        end
    end

    local icon = GetButtonIcon(btn)
    if icon then
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", sf, "TOPLEFT", 0, 0)
        icon:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", 0, 0)
        ApplyIconZoom(icon, tonumber(vcfg.iconZoom) or 0.10)
        if icon.SetVertexColor then icon:SetVertexColor(1, 1, 1, 1) end
        if icon.SetAlpha then icon:SetAlpha(1) end
        icon:Show()
    end

    local hotkey = btn.HotKey or (btn.GetName and _G[btn:GetName() .. "HotKey"])
    if hotkey then
        hotkey:SetText("")
        hotkey:Hide()
    end
end

local function PositionButton(btn)
    if not btn then return end

    local ab = GetCfg()
    if not ab or type(ab.vehicleExit) ~= "table" then return end
    local vcfg = ab.vehicleExit

    SetPointPx(
        btn,
        vcfg.point or "BOTTOM",
        UIParent,
        vcfg.relPoint or "BOTTOM",
        tonumber(vcfg.x) or 0,
        tonumber(vcfg.y) or 120
    )
end

local function ApplyState()
    local btn = GetButton()
    if not btn then return end

    UnhideObject(btn)

    if InCombat() then
        V.__needsUpdate = true
        return
    end

    PositionButton(btn)
    StyleButton(btn)

    if CanShowVehicleExit() then
        ForceShow(btn)
    else
        btn:Hide()
    end
end

function V:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local function Handle()
        ApplyState()
    end

    if ns.Events then
        local E = ns.Events
        E:RegisterMany({
            "PLAYER_LOGIN",
            "PLAYER_ENTERING_WORLD",
            "UNIT_ENTERED_VEHICLE",
            "UNIT_EXITED_VEHICLE",
            "UPDATE_BONUS_ACTIONBAR",
            "UPDATE_OVERRIDE_ACTIONBAR",
            "VEHICLE_UPDATE",
            "PLAYER_CONTROL_GAINED",
            "PLAYER_CONTROL_LOST",
        }, function(_, unit)
            if unit and unit ~= "player" then return end
            Handle()
        end, { throttle = true })

        E:Register("PLAYER_REGEN_ENABLED", function()
            if V.__needsUpdate then
                V.__needsUpdate = false
                Handle()
            end
        end)
    else
        local f = CreateFrame("Frame")
        self.__driver = f
        f:RegisterEvent("PLAYER_LOGIN")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:RegisterEvent("UNIT_ENTERED_VEHICLE")
        f:RegisterEvent("UNIT_EXITED_VEHICLE")
        f:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
        f:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
        f:RegisterEvent("VEHICLE_UPDATE")
        f:RegisterEvent("PLAYER_CONTROL_GAINED")
        f:RegisterEvent("PLAYER_CONTROL_LOST")
        f:RegisterEvent("PLAYER_REGEN_ENABLED")

        f:SetScript("OnEvent", function(_, event, unit)
            if event == "PLAYER_REGEN_ENABLED" then
                if V.__needsUpdate then
                    V.__needsUpdate = false
                    Handle()
                end
                return
            end

            if unit and unit ~= "player" then return end
            Handle()
        end)
    end

    C_Timer.After(0, ApplyState)
end

function V:Init()
    self:Enable()
end

C_Timer.After(0, function()
    if V and V.Init then
        V:Init()
    end
end)
