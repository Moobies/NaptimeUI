local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.CooldownManager = ns.Modules.CooldownManager or {}

local CM = ns.Modules.CooldownManager
CM.Power = CM.Power or {}

local P = CM.Power
P.Rogue = P.Rogue or {}

local R = P.Rogue
local WHITE = P.WHITE or "Interface\\Buttons\\WHITE8X8"

function R:GetComboPoints()
    local comboType = (Enum and Enum.PowerType and Enum.PowerType.ComboPoints) or 4
    return UnitPower("player", comboType) or 0, UnitPowerMax("player", comboType) or 0
end

function R:ShouldShowFrame(cfg)
    if type(cfg) ~= "table" then return true end
    if cfg.showComboCombatOnly then
        return P:InCombat()
    end
    return true
end

function R:ShouldShowComboPoints(powerType)
    local ENERGY = (Enum and Enum.PowerType and Enum.PowerType.Energy) or 3
    return powerType == ENERGY
end

function R:EnsureFrame()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", ADDON .. "CooldownManagerComboBarFrame", UIParent)
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

    self.frame = f
    return f
end

function R:ApplyStyle()
    local cfg = P:GetCfg()
    local d = P.DEFAULT_CFG
    local f = self:EnsureFrame()

    local comboCfg = cfg.combo or d.combo
    local width = tonumber(comboCfg.width) or d.combo.width
    local height = tonumber(comboCfg.height) or d.combo.height

    f:ClearAllPoints()
    f:SetSize(width, height)
    f:SetPoint(
        (comboCfg.point and comboCfg.point[1]) or d.combo.point[1],
        UIParent,
        (comboCfg.point and comboCfg.point[2]) or d.combo.point[2],
        tonumber(comboCfg.x) or d.combo.x,
        tonumber(comboCfg.y) or d.combo.y
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

    local bgc = comboCfg.bgRGBA or d.combo.bgRGBA
    f.BG:SetVertexColor(bgc[1] or 0, bgc[2] or 0, bgc[3] or 0, bgc[4] or 1)

    P:SetBorderColor(f, cfg.borderRGBA or d.borderRGBA)
end

function R:LayoutSegments(maxPoints)
    local cfg = P:GetCfg()
    local d = P.DEFAULT_CFG
    local f = self:EnsureFrame()
    local comboCfg = cfg.combo or d.combo

    local width = tonumber(comboCfg.width) or d.combo.width
    local spacing = tonumber(comboCfg.spacing) or d.combo.spacing
    local fillRGBA = comboCfg.fillRGBA or d.combo.fillRGBA
    local extraFillRGBA = comboCfg.extraFillRGBA or d.combo.extraFillRGBA
    local dividerRGBA = comboCfg.dividerRGBA or d.combo.dividerRGBA

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

        local c = fillRGBA
        if i > 4 then
            c = extraFillRGBA
        end

        seg:SetVertexColor(
            c[1] or 1,
            c[2] or 1,
            c[3] or 1,
            c[4] or 1
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

function R:UpdateSegments(curPoints, maxPoints)
    local f = self:EnsureFrame()
    if not f.__fills then return end

    for i = 1, maxPoints do
        local seg = f.__fills[i]
        if seg then
            seg:SetShown(i <= (curPoints or 0))
        end
    end
end

function R:Update()
    local cfg = P:GetCfg()
    local d = P.DEFAULT_CFG
    local f = self:EnsureFrame()
    self:ApplyStyle()

    if not P:IsRogue() then
        f:Hide()
        return
    end

    if cfg.enabled == false or not self:ShouldShowFrame(cfg) then
        f:Hide()
        return
    end

    local powerType = UnitPowerType("player")
    local comboCfg = cfg.combo or d.combo

    if comboCfg.enabled == false or not self:ShouldShowComboPoints(powerType) then
        f:Hide()
        return
    end

    local cpCur, cpMax = self:GetComboPoints()
    if not cpMax or cpMax <= 0 then
        f:Hide()
        return
    end

    self:LayoutSegments(cpMax)
    self:UpdateSegments(cpCur, cpMax)

    if cfg.showComboText ~= false then
        local tc = cfg.textRGBA or d.textRGBA
        f.Text:SetText(tostring(cpCur or 0))
        f.Text:SetTextColor(tc[1] or 1, tc[2] or 1, tc[3] or 1, tc[4] or 1)
        f.Text:Show()
    else
        f.Text:SetText("")
        f.Text:Hide()
    end

    f:Show()
end

function R:Enable()
    self:EnsureFrame()
    self:ApplyStyle()
end

function R:Disable()
    if self.frame then
        self.frame:Hide()
    end
end
