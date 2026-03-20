local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.CooldownManager = ns.Modules.CooldownManager or {}

local CM = ns.Modules.CooldownManager
CM.Power = CM.Power or {}

local P = CM.Power
local WHITE = "Interface\\Buttons\\WHITE8X8"

P.WHITE = WHITE

P.DEFAULT_CFG = {
    enabled = true,

    font = "Primary",
    mainSize = 16,
    mainFlags = "OUTLINE",
    subSize = 12,
    subFlags = "OUTLINE",

    showText = true,
    showComboText = true,

    showPowerCombatOnly = false,
    showComboCombatOnly = false,

    borderRGBA = {0, 0, 0, 1},
    textRGBA = {1, 1, 1, 1},

    bar = {
        width = 220,
        height = 10,
        point = {"CENTER", "CENTER"},
        x = 0,
        y = -140,
        bgRGBA = {0.08, 0.08, 0.08, 0.85},
    },

    combo = {
        enabled = true,
        width = 220,
        height = 8,
        point = {"CENTER", "CENTER"},
        x = 0,
        y = -156,
        bgRGBA = {0.08, 0.08, 0.08, 0.85},
        fillRGBA = {1.00, 0.84, 0.00, 1.00},
        extraFillRGBA = {0.20, 1.00, 0.20, 1.00},
        dividerRGBA = {0, 0, 0, 1},
        spacing = 0,
    },

    monk = {
        enabled = true,
        showChiCombatOnly = false,
        showStaggerCombatOnly = false,

        chi = {
            enabled = true,
            width = 204,
            height = 8,
            point = {"CENTER", "CENTER"},
            x = 0,
            y = -220,
            bgRGBA = {0.08, 0.08, 0.08, 0.85},
            fillRGBA = {0.55, 0.90, 1.00, 1.00},
            dividerRGBA = {0, 0, 0, 1},
            spacing = 0,
        },

        stagger = {
            enabled = true,
            width = 204,
            height = 8,
            point = {"CENTER", "CENTER"},
            x = 0,
            y = -220,
            bgRGBA = {0.08, 0.08, 0.08, 0.85},
            lightRGBA = {0.20, 1.00, 0.20, 1.00},
            moderateRGBA = {1.00, 0.80, 0.10, 1.00},
            heavyRGBA = {1.00, 0.20, 0.20, 1.00},
        },
    },
}

function P:InCombat()
    return InCombatLockdown and InCombatLockdown()
end

function P:GetCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then
        cfg = {}
        ns.Config = cfg
    end

    if type(cfg.cooldownManager) ~= "table" then
        cfg.cooldownManager = {}
    end

    if type(cfg.cooldownManager.power) ~= "table" then
        cfg.cooldownManager.power = {}
    end

    local p = cfg.cooldownManager.power
    if type(p.bar) ~= "table" then p.bar = {} end
    if type(p.combo) ~= "table" then p.combo = {} end
    if type(p.monk) ~= "table" then p.monk = {} end
    if type(p.monk.chi) ~= "table" then p.monk.chi = {} end
    if type(p.monk.stagger) ~= "table" then p.monk.stagger = {} end

    return p
end

function P:ResolveFont(fontKey)
    if type(fontKey) ~= "string" or fontKey == "" then
        return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    end

    if ns.GetFont then
        local ok, path = pcall(ns.GetFont, ns, fontKey)
        if ok and type(path) == "string" and path ~= "" then
            return path
        end
    end

    return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

function P:SafeSetFont(fs, fontKey, size, flags)
    if not (fs and fs.SetFont) then return end
    pcall(fs.SetFont, fs, self:ResolveFont(fontKey), tonumber(size) or 16, flags or "")
end

function P:PixelPerfect(value)
    value = tonumber(value) or 0

    if ns.Pixel then
        if type(ns.Pixel) == "table" then
            if type(ns.Pixel.Size) == "function" then
                local ok, out = pcall(ns.Pixel.Size, ns.Pixel, value)
                if ok and type(out) == "number" then
                    return out
                end
            end

            if type(ns.Pixel.Get) == "function" then
                local ok, out = pcall(ns.Pixel.Get, ns.Pixel, value)
                if ok and type(out) == "number" then
                    return out
                end
            end
        elseif type(ns.Pixel) == "function" then
            local ok, out = pcall(ns.Pixel, value)
            if ok and type(out) == "number" then
                return out
            end
        end
    end

    local _, screenHeight = GetPhysicalScreenSize()
    local uiScale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    local pixelSize = 768 / screenHeight / uiScale
    return pixelSize * math.floor(value / pixelSize + 0.5333)
end

function P:GetPowerColor(powerType)
    if PowerBarColor and PowerBarColor[powerType] then
        local c = PowerBarColor[powerType]
        return c.r or 1, c.g or 1, c.b or 1
    end

    if powerType == 0 then return 0.00, 0.55, 1.00 end
    if powerType == 1 then return 1.00, 0.00, 0.00 end
    if powerType == 3 then return 1.00, 1.00, 0.00 end
    if powerType == 8 then return 0.80, 0.30, 0.85 end
    return 1, 1, 1
end

function P:GetMainPower()
    local powerType, powerToken = UnitPowerType("player")
    local cur = UnitPower("player", powerType)
    local max = UnitPowerMax("player", powerType)
    return powerType or 0, powerToken, cur or 0, max or 0
end

function P:ShouldShowPowerFrame(cfg)
    if type(cfg) ~= "table" then return true end
    if cfg.showPowerCombatOnly then
        return self:InCombat()
    end
    return true
end

function P:IsRogue()
    local _, class = UnitClass("player")
    return class == "ROGUE"
end

function P:IsDruid()
    local _, class = UnitClass("player")
    return class == "DRUID"
end

function P:IsMonk()
    local _, class = UnitClass("player")
    return class == "MONK"
end

function P:GetSpecIndex()
    if type(GetSpecialization) == "function" then
        return GetSpecialization()
    end
    return nil
end

function P:EnsureBorder(frame)
    if frame.__powerBorder then return end

    local border = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
    border:SetAllPoints(frame)
    border:SetFrameLevel((frame:GetFrameLevel() or 0) + 5)

    if border.SetBackdrop then
        border:SetBackdrop({
            bgFile = WHITE,
            edgeFile = WHITE,
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
    end

    frame.__powerBorder = border
end

function P:SetBorderColor(frame, rgba)
    if frame and frame.__powerBorder and frame.__powerBorder.SetBackdropBorderColor then
        frame.__powerBorder:SetBackdropColor(0, 0, 0, 0)
        frame.__powerBorder:SetBackdropBorderColor(
            rgba and rgba[1] or 0,
            rgba and rgba[2] or 0,
            rgba and rgba[3] or 0,
            rgba and rgba[4] or 1
        )
    end
end

function P:EnsurePowerFrame()
    if self.powerFrame then return self.powerFrame end

    local f = CreateFrame("Frame", ADDON .. "CooldownManagerPowerBarFrame", UIParent)
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

    f.Bar = bar
    f.Text = text

    self:EnsureBorder(f)

    self.powerFrame = f
    return f
end

function P:ApplyPowerStyle()
    local cfg = self:GetCfg()
    local d = self.DEFAULT_CFG
    local f = self:EnsurePowerFrame()

    local barCfg = cfg.bar or d.bar
    local width = tonumber(barCfg.width) or d.bar.width
    local height = tonumber(barCfg.height) or d.bar.height

    f:ClearAllPoints()
    f:SetSize(width, height)
    f:SetPoint(
        (barCfg.point and barCfg.point[1]) or d.bar.point[1],
        UIParent,
        (barCfg.point and barCfg.point[2]) or d.bar.point[2],
        tonumber(barCfg.x) or d.bar.x,
        tonumber(barCfg.y) or d.bar.y
    )

    self:SafeSetFont(
        f.Text,
        cfg.font or d.font,
        cfg.mainSize or d.mainSize,
        cfg.mainFlags or d.mainFlags
    )

    if f.Text.SetShadowOffset then
        f.Text:SetShadowOffset(0, 0)
    end

    local bgc = barCfg.bgRGBA or d.bar.bgRGBA
    f.Bar.BG:SetVertexColor(bgc[1] or 0, bgc[2] or 0, bgc[3] or 0, bgc[4] or 1)

    self:SetBorderColor(f, cfg.borderRGBA or d.borderRGBA)
end

function P:UpdatePowerBar()
    local cfg = self:GetCfg()
    local d = self.DEFAULT_CFG
    local f = self:EnsurePowerFrame()
    self:ApplyPowerStyle()

    if cfg.enabled == false or not self:ShouldShowPowerFrame(cfg) then
        f:Hide()
        return
    end

    local powerType, _, cur, max = self:GetMainPower()
    if not max or max <= 0 then
        f:Hide()
        return
    end

    local r, g, b = self:GetPowerColor(powerType)
    f.Bar:SetMinMaxValues(0, max)
    f.Bar:SetValue(cur)
    f.Bar:SetStatusBarColor(r, g, b, 1)

    if cfg.showText ~= false then
        local tc = cfg.textRGBA or d.textRGBA
        f.Text:SetText(tostring(cur))
        f.Text:SetTextColor(tc[1] or 1, tc[2] or 1, tc[3] or 1, tc[4] or 1)
        f.Text:Show()
    else
        f.Text:SetText("")
        f.Text:Hide()
    end

    f:Show()
end

function P:UpdateClassResources()
    if self.Rogue and self.Rogue.Update then
        self.Rogue:Update()
    end

    if self.Druid and self.Druid.Update then
        self.Druid:Update()
    end

    if self.Monk and self.Monk.Update then
        self.Monk:Update()
    end
end

function P:UpdateAll()
    self:UpdatePowerBar()
    self:UpdateClassResources()
end

function P:Enable()
    if self.__enabled then return end
    self.__enabled = true

    self:EnsurePowerFrame()
    self:ApplyPowerStyle()

    if self.Rogue and self.Rogue.Enable then
        self.Rogue:Enable()
    end

    if self.Druid and self.Druid.Enable then
        self.Druid:Enable()
    end

    if self.Monk and self.Monk.Enable then
        self.Monk:Enable()
    end

    local ev = CreateFrame("Frame")
    self.eventFrame = ev

    ev:RegisterEvent("PLAYER_ENTERING_WORLD")
    ev:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    ev:RegisterEvent("UNIT_DISPLAYPOWER")
    ev:RegisterEvent("UNIT_POWER_UPDATE")
    ev:RegisterEvent("UNIT_MAXPOWER")
    ev:RegisterEvent("PLAYER_TARGET_CHANGED")
    ev:RegisterEvent("PLAYER_REGEN_DISABLED")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")
    ev:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    ev:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    ev:RegisterEvent("UNIT_AURA")

    ev:SetScript("OnEvent", function(_, _, unit)
        if unit and unit ~= "player" then return end
        self:UpdateAll()
    end)

    C_Timer.After(0, function()
        if self and self.__enabled then
            self:UpdateAll()
        end
    end)
end

function P:Disable()
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        self.eventFrame:SetScript("OnEvent", nil)
    end

    if self.powerFrame then
        self.powerFrame:Hide()
    end

    if self.Rogue and self.Rogue.Disable then
        self.Rogue:Disable()
    end

    if self.Druid and self.Druid.Disable then
        self.Druid:Disable()
    end

    if self.Monk and self.Monk.Disable then
        self.Monk:Disable()
    end

    self.__enabled = nil
end
