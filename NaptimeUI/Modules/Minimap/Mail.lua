-- Modules/Minimap/Mail.lua
local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.MinimapMail = ns.Modules.MinimapMail or {}
local M = ns.Modules.MinimapMail

local function GetRootCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    return (type(cfg) == "table") and cfg or nil
end

local function GetCfg()
    local cfg = GetRootCfg()
    if not cfg then return nil end
    return (type(cfg.minimap) == "table") and cfg.minimap or nil
end

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function GetMinimap()
    return _G.Minimap
end

local function HideAndDisable(obj)
    if not obj then return end
    if obj.EnableMouse then pcall(obj.EnableMouse, obj, false) end
    if obj.SetMouseClickEnabled then pcall(obj.SetMouseClickEnabled, obj, false) end
    if obj.SetAlpha then pcall(obj.SetAlpha, obj, 0) end
    if obj.Hide then pcall(obj.Hide, obj) end
    if obj.SetShown then pcall(obj.SetShown, obj, false) end
end

local function GetBlizzardMailBits()
    local mailFrame =
        (_G.MinimapCluster and _G.MinimapCluster.IndicatorFrame and _G.MinimapCluster.IndicatorFrame.MailFrame)
        or _G.MiniMapMailFrame
        or _G.MinimapMailFrame

    local mailIcon =
        _G.MiniMapMailIcon
        or _G.MinimapMailIcon
        or (mailFrame and (mailFrame.MailIcon or mailFrame.Icon))

    local reminderFlipbook = mailFrame and mailFrame.MailReminderFlipbook or nil
    local newMailFlipbook  = mailFrame and mailFrame.NewMailFlipbook or nil

    return mailFrame, mailIcon, reminderFlipbook, newMailFlipbook
end

local function HideBlizzardMail()
    local mailFrame, mailIcon, reminderFlipbook, newMailFlipbook = GetBlizzardMailBits()
    HideAndDisable(mailFrame)
    HideAndDisable(mailIcon)
    HideAndDisable(reminderFlipbook)
    HideAndDisable(newMailFlipbook)
end

local function HasPendingMail()
    if HasNewMail and HasNewMail() then
        return true
    end

    local mailFrame = select(1, GetBlizzardMailBits())
    if mailFrame and mailFrame.IsShown and mailFrame:IsShown() then
        return true
    end

    return false
end

local function GetMailAnchorParent()
    return _G.NOL_Minimap or UIParent
end

local function GetMailButton()
    local btn = _G.NOL_MinimapMailButton
    if btn then return btn end

    local parent = GetMailAnchorParent()
    btn = CreateFrame("Frame", "NOL_MinimapMailButton", parent)
    btn:SetFrameStrata("TOOLTIP")
    btn:SetFrameLevel(200)
    btn:EnableMouse(false)
    btn:SetClampedToScreen(true)

    local tex = btn:CreateTexture(nil, "ARTWORK", nil, 2)
    tex:SetAllPoints(btn)
    btn.Icon = tex

    return btn
end

local function ApplyMail()
    if InCombat() then return end

    local mm = GetMinimap()
    local cfg = GetCfg()
    if not mm or not cfg then return end

    HideBlizzardMail()

    local btn = GetMailButton()
    if not btn then return end

    local mcfg = cfg.mail or {}
    local size = tonumber(mcfg.sizePx) or 18
    local p  = mcfg.point or "TOPRIGHT"
    local rp = mcfg.relPoint or p
    local x  = tonumber(mcfg.x) or 0
    local y  = tonumber(mcfg.y) or 0

    local iconPath = ns.Media and ns.Media.icons and ns.Media.icons.Mail
    if btn.Icon and iconPath then
        btn.Icon:SetTexture(iconPath)
        btn.Icon:SetTexCoord(0, 1, 0, 1)
        btn.Icon:SetAlpha(1)
        btn.Icon:Show()
    end

    btn:SetParent(GetMailAnchorParent())
    btn:ClearAllPoints()
    btn:SetPoint(p, mm, rp, x, y)
    btn:SetSize(size, size)
    btn:SetHitRectInsets(0, 0, 0, 0)
    btn:SetFrameStrata("TOOLTIP")
    btn:SetFrameLevel(((_G.NOL_Minimap and _G.NOL_Minimap:GetFrameLevel()) or 5) + 200)

    if HasPendingMail() then
        btn:Show()
    else
        btn:Hide()
    end
end

function M:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local function Refresh()
        if InCombat() then return end
        ApplyMail()
    end

    if ns.Events then
        local E = ns.Events
        E:RegisterMany({
            "PLAYER_LOGIN",
            "PLAYER_ENTERING_WORLD",
            "PLAYER_REGEN_ENABLED",
            "UPDATE_PENDING_MAIL",
            "MAIL_INBOX_UPDATE",
        }, function()
            C_Timer.After(0, Refresh)
            C_Timer.After(0.10, Refresh)
            C_Timer.After(0.30, Refresh)
        end, { throttle = true })
    else
        local f = CreateFrame("Frame")
        self.__driver = f
        f:RegisterEvent("PLAYER_LOGIN")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
        f:RegisterEvent("UPDATE_PENDING_MAIL")
        f:RegisterEvent("MAIL_INBOX_UPDATE")
        f:SetScript("OnEvent", function()
            C_Timer.After(0, Refresh)
            C_Timer.After(0.10, Refresh)
            C_Timer.After(0.30, Refresh)
        end)
    end

    C_Timer.After(0, Refresh)
    C_Timer.After(0.10, Refresh)
    C_Timer.After(0.30, Refresh)
end
