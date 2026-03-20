local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.CooldownManager = ns.Modules.CooldownManager or {}

local CM = ns.Modules.CooldownManager
CM.Power = CM.Power or {}

local P = CM.Power
P.Monk = P.Monk or {}

local M = P.Monk
local WHITE = P.WHITE or "Interface\\Buttons\\WHITE8X8"

-- Monk spec order:
-- 1 = Brewmaster
-- 2 = Mistweaver
-- 3 = Windwalker
local BREWMASTER_SPEC_INDEX = 1
local WINDWALKER_SPEC_INDEX = 3

local function IsBrewmaster()
    return P:IsMonk() and P:GetSpecIndex() == BREWMASTER_SPEC_INDEX
end

local function IsWindwalker()
    return P:IsMonk() and P:GetSpecIndex() == WINDWALKER_SPEC_INDEX
end

local function GetChi()
    local chiType = (Enum and Enum.PowerType and Enum.PowerType.Chi) or 12
    return UnitPower("player", chiType) or 0, UnitPowerMax("player", chiType) or 0
end

local function GetStaggerAmount()
    if type(UnitStagger) == "function" then
        return UnitStagger("player") or 0
    end
    return 0
end

local function ShouldShowChiFrame(cfg)
    local monkCfg = cfg and cfg.monk
    if type(monkCfg) ~= "table" then return true end
    if monkCfg.showChiCombatOnly then
        return P:InCombat()
    end
    return true
end

local function ShouldShowStaggerFrame(cfg)
    local monkCfg = cfg and cfg.monk
    if type(monkCfg) ~= "table" then return true end
    if monkCfg.showStaggerCombatOnly then
        return P:InCombat()
    end
    return true
end

function M:EnsureChiFrame()
    if self.chiFrame then return self.chiFrame end

    local f = CreateFrame("Frame", ADDON .. "CooldownManagerMonkChiBarFrame", UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(20)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetAllPoints(f)
    f.BG = bg

    local textHolder = CreateFrame("Frame", nil, f)
    textHolder:SetAllPoints(f)
    textHolder:SetFrameStrata(f:GetFrameStrata())
    textHolder:SetFrameLevel((f:GetFrameLevel() or 20) + 10)
    f.TextHolder = textHolder

    local text = textHolder:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", f, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetDrawLayer("OVERLAY", 7)
    f.Text = text

    P:EnsureBorder(f)

    f.__fills = {}
    f.__dividers = {}

    self.chiFrame = f
    return f
end

function M:EnsureStaggerFrame()
    if self.staggerFrame then return self.staggerFrame end

    local f = CreateFrame("Frame", ADDON .. "CooldownManagerMonkStaggerBarFrame", UIParent)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(20)

    local bar = CreateFrame("StatusBar", nil, f)
    bar:SetStatusBarTexture(WHITE)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    bar:SetAllPoints(f)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetAllPoints(bar)
    bar.BG = bg

    local textHolder = CreateFrame("Frame", nil, f)
    textHolder:SetAllPoints(f)
    textHolder:SetFrameStrata(f:GetFrameStrata())
    textHolder:SetFrameLevel((f:GetFrameLevel() or 20) + 10)
    f.TextHolder = textHolder

    local text = textHolder:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", f, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetDrawLayer("OVERLAY", 7)
    f.Text = text

    f.Bar = bar

    P:EnsureBorder(f)

    self.staggerFrame = f
    return f
end

function M:ApplyChiStyle()
    local cfg = P:GetCfg()
    local d = P.DEFAULT_CFG
    local f = self:EnsureChiFrame()

    local monkCfg = cfg.monk or d.monk
    local chiCfg = monkCfg.chi or d.monk.chi

    local width = tonumber(chiCfg.width) or d.monk.chi.width
    local height = tonumber(chiCfg.height) or d.monk.chi.height

    f:ClearAllPoints()
    f:SetSize(width, height)
    f:SetPoint(
        (chiCfg.point and chiCfg.point[1]) or d.monk.chi.point[1],
        UIParent,
        (chiCfg.point and chiCfg.point[2]) or d.monk.chi.point[2],
        tonumber(chiCfg.x) or d.monk.chi.x,
        tonumber(chiCfg.y) or d.monk.chi.y
    )

    P:SafeSetFont(
        f.Text,
        cfg.font or d.font,
        cfg.subSize or d.subSize,
        cfg.subFlags or d.subFlags
    )

    if f.Text.SetShadowOffset then
        f.Text:SetShadowOffset(0, 0)
    end

    local bgc = chiCfg.bgRGBA or d.monk.chi.bgRGBA
    f.BG:SetVertexColor(bgc[1] or 0, bgc[2] or 0, bgc[3] or 0, bgc[4] or 1)

    P:SetBorderColor(f, cfg.borderRGBA or d.borderRGBA)
end

function M:ApplyStaggerStyle()
    local cfg = P:GetCfg()
    local d = P.DEFAULT_CFG
    local f = self:EnsureStaggerFrame()

    local monkCfg = cfg.monk or d.monk
    local staggerCfg = monkCfg.stagger or d.monk.stagger

    local width = tonumber(staggerCfg.width) or d.monk.stagger.width
    local height = tonumber(staggerCfg.height) or d.monk.stagger.height

    f:ClearAllPoints()
    f:SetSize(width, height)
    f:SetPoint(
        (staggerCfg.point and staggerCfg.point[1]) or d.monk.stagger.point[1],
        UIParent,
        (staggerCfg.point and staggerCfg.point[2]) or d.monk.stagger.point[2],
        tonumber(staggerCfg.x) or d.monk.stagger.x,
        tonumber(staggerCfg.y) or d.monk.stagger.y
    )

    P:SafeSetFont(
        f.Text,
        cfg.font or d.font,
        cfg.subSize or d.subSize,
        cfg.subFlags or d.subFlags
    )

    if f.Text.SetShadowOffset then
        f.Text:SetShadowOffset(0, 0)
    end

    local bgc = staggerCfg.bgRGBA or d.monk.stagger.bgRGBA
    f.Bar.BG:SetVertexColor(bgc[1] or 0, bgc[2] or 0, bgc[3] or 0, bgc[4] or 1)

    P:SetBorderColor(f, cfg.borderRGBA or d.borderRGBA)
end

function M:LayoutChiSegments(maxPoints)
    local cfg = P:GetCfg()
    local d = P.DEFAULT_CFG
    local f = self:EnsureChiFrame()

    local monkCfg = cfg.monk or d.monk
    local chiCfg = monkCfg.chi or d.monk.chi

    local width = tonumber(chiCfg.width) or d.monk.chi.width
    local spacing = tonumber(chiCfg.spacing) or d.monk.chi.spacing
    local fillRGBA = chiCfg.fillRGBA or d.monk.chi.fillRGBA
    local dividerRGBA = chiCfg.dividerRGBA or d.monk.chi.dividerRGBA

    if not maxPoints or maxPoints <= 0 then
        for i = 1, #f.__fills do
            f.__fills[i]:Hide()
        end
        for i = 1, #f.__dividers do
            f.__dividers[i]:Hide()
        end
        return
    end

    local inset = P:PixelPerfect(1)
    local innerWidth = width - (inset * 2)
    local totalSpacing = spacing * (maxPoints - 1)
    local segmentWidth = (innerWidth - totalSpacing) / maxPoints
    local dividerWidth = math.max(1, P:PixelPerfect(1))

    for i = 1, maxPoints do
        local seg = f.__fills[i]
        if not seg then
            seg = f:CreateTexture(nil, "ARTWORK")
            f.__fills[i] = seg
        end

        local left = inset + ((i - 1) * (segmentWidth + spacing))
        local right = left + segmentWidth

        seg:ClearAllPoints()
        seg:SetPoint("TOPLEFT", f, "TOPLEFT", P:PixelPerfect(left), -inset)
        seg:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", P:PixelPerfect(right), inset)
        seg:SetTexture(WHITE)
        seg:SetVertexColor(
            fillRGBA[1] or 1,
            fillRGBA[2] or 1,
            fillRGBA[3] or 1,
            fillRGBA[4] or 1
        )
        seg:Show()
    end

    for i = maxPoints + 1, #f.__fills do
        f.__fills[i]:Hide()
    end

    local dividerCount = maxPoints - 1
    for i = 1, dividerCount do
        local div = f.__dividers[i]
        if not div then
            div = f:CreateTexture(nil, "OVERLAY")
            f.__dividers[i] = div
        end

        local x = inset + ((segmentWidth + spacing) * i) - (spacing * 0.5)

        div:ClearAllPoints()
        div:SetPoint("TOP", f, "TOPLEFT", P:PixelPerfect(x), -inset)
        div:SetPoint("BOTTOM", f, "BOTTOMLEFT", P:PixelPerfect(x), inset)
        div:SetWidth(dividerWidth)
        div:SetColorTexture(
            dividerRGBA[1] or 0,
            dividerRGBA[2] or 0,
            dividerRGBA[3] or 0,
            dividerRGBA[4] or 1
        )
        div:Show()
    end

    for i = dividerCount + 1, #f.__dividers do
        f.__dividers[i]:Hide()
    end
end

function M:UpdateChiSegments(curPoints, maxPoints)
    local f = self:EnsureChiFrame()
    if not f.__fills then return end

    for i = 1, maxPoints do
        local seg = f.__fills[i]
        if seg then
            seg:SetShown(i <= (curPoints or 0))
        end
    end
end

function M:GetStaggerColorAndPercent(amount, maxHealth)
    local cfg = P:GetCfg()
    local d = P.DEFAULT_CFG
    local monkCfg = cfg.monk or d.monk
    local staggerCfg = monkCfg.stagger or d.monk.stagger

    if not amount or amount <= 0 or not maxHealth or maxHealth <= 0 then
        local c = staggerCfg.lightRGBA or d.monk.stagger.lightRGBA
        return c, 0
    end

    local pct = amount / maxHealth

    if pct >= 0.06 then
        return staggerCfg.heavyRGBA or d.monk.stagger.heavyRGBA, pct
    elseif pct >= 0.03 then
        return staggerCfg.moderateRGBA or d.monk.stagger.moderateRGBA, pct
    else
        return staggerCfg.lightRGBA or d.monk.stagger.lightRGBA, pct
    end
end

function M:UpdateChi()
    local cfg = P:GetCfg()
    local d = P.DEFAULT_CFG
    local chiFrame = self:EnsureChiFrame()
    local staggerFrame = self:EnsureStaggerFrame()

    staggerFrame:Hide()
    self:ApplyChiStyle()

    if not IsWindwalker() then
        chiFrame:Hide()
        return
    end

    local monkCfg = cfg.monk or d.monk
    local chiCfg = monkCfg.chi or d.monk.chi

    if cfg.enabled == false or monkCfg.enabled == false or chiCfg.enabled == false or not ShouldShowChiFrame(cfg) then
        chiFrame:Hide()
        return
    end

    local cur, max = GetChi()
    if not max or max <= 0 then
        chiFrame:Hide()
        return
    end

    self:LayoutChiSegments(max)
    self:UpdateChiSegments(cur, max)

    if cfg.showComboText ~= false then
        local tc = cfg.textRGBA or d.textRGBA
        chiFrame.Text:SetText(tostring(cur or 0))
        chiFrame.Text:SetTextColor(tc[1] or 1, tc[2] or 1, tc[3] or 1, tc[4] or 1)
        chiFrame.Text:Show()
    else
        chiFrame.Text:SetText("")
        chiFrame.Text:Hide()
    end

    chiFrame:Show()
end

function M:UpdateStagger()
    local cfg = P:GetCfg()
    local d = P.DEFAULT_CFG
    local chiFrame = self:EnsureChiFrame()
    local staggerFrame = self:EnsureStaggerFrame()

    chiFrame:Hide()
    self:ApplyStaggerStyle()

    if not IsBrewmaster() then
        staggerFrame:Hide()
        return
    end

    local monkCfg = cfg.monk or d.monk
    local staggerCfg = monkCfg.stagger or d.monk.stagger

    if cfg.enabled == false or monkCfg.enabled == false or staggerCfg.enabled == false or not ShouldShowStaggerFrame(cfg) then
        staggerFrame:Hide()
        return
    end

    local amount = GetStaggerAmount()
    local maxHealth = UnitHealthMax("player") or 0

    if not amount or amount <= 0 or not maxHealth or maxHealth <= 0 then
        staggerFrame:Hide()
        return
    end

    local color, pct = self:GetStaggerColorAndPercent(amount, maxHealth)
    local shownPct = math.max(0, math.min(pct * 100, 100))

    staggerFrame.Bar:SetMinMaxValues(0, 100)
    staggerFrame.Bar:SetValue(shownPct)
    staggerFrame.Bar:SetStatusBarColor(
        color[1] or 1,
        color[2] or 1,
        color[3] or 1,
        color[4] or 1
    )

    if cfg.showComboText ~= false then
        local tc = cfg.textRGBA or d.textRGBA
        staggerFrame.Text:SetText(BreakUpLargeNumbers(math.floor(amount)))
        staggerFrame.Text:SetTextColor(tc[1] or 1, tc[2] or 1, tc[3] or 1, tc[4] or 1)
        staggerFrame.Text:Show()
    else
        staggerFrame.Text:SetText("")
        staggerFrame.Text:Hide()
    end

    staggerFrame:Show()
end

function M:Update()
    if not P:IsMonk() then
        if self.chiFrame then self.chiFrame:Hide() end
        if self.staggerFrame then self.staggerFrame:Hide() end
        return
    end

    if IsWindwalker() then
        self:UpdateChi()
        return
    end

    if IsBrewmaster() then
        self:UpdateStagger()
        return
    end

    if self.chiFrame then self.chiFrame:Hide() end
    if self.staggerFrame then self.staggerFrame:Hide() end
end

function M:Enable()
    self:EnsureChiFrame()
    self:EnsureStaggerFrame()
    self:ApplyChiStyle()
    self:ApplyStaggerStyle()
end

function M:Disable()
    if self.chiFrame then
        self.chiFrame:Hide()
    end
    if self.staggerFrame then
        self.staggerFrame:Hide()
    end
end
