-- Core/Fade.lua
local ADDON, ns = ...
ns = ns or {}

ns.Fade = ns.Fade or {}
local F = ns.Fade

local function Clamp(v, lo, hi)
    v = tonumber(v) or 0
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function F:To(frame, targetAlpha, duration)
    if not frame then return end
    targetAlpha = Clamp(targetAlpha, 0, 1)
    duration = tonumber(duration) or 0.15

    local inCombat = InCombatLockdown and InCombatLockdown()
    local isProtected = (frame.IsProtected and frame:IsProtected()) or false
    local isForbidden = (frame.IsForbidden and frame:IsForbidden()) or false
    local combatUnsafe = inCombat and (isProtected or isForbidden)

    -- Combat-safe path for protected frames: alpha only, no UIFrameFade (it may call Show/Hide)
    if combatUnsafe then
        frame:SetAlpha(targetAlpha)
        return
    end

    if duration <= 0 then
        frame:SetAlpha(targetAlpha)
        return
    end

    if UIFrameFadeRemoveFrame and UIFrameFade then
        UIFrameFadeRemoveFrame(frame)
        UIFrameFade(frame, {
            mode = "IN",
            timeToFade = duration,
            startAlpha = frame:GetAlpha() or 1,
            endAlpha = targetAlpha,
        })
        return
    end

    -- minimal fallback tween
    frame.__nolFade = frame.__nolFade or {}
    local st = frame.__nolFade
    st.a0 = frame:GetAlpha() or 1
    st.a1 = targetAlpha
    st.t = 0
    st.d = duration

    if not frame.__nolFadeHooked then
        frame.__nolFadeHooked = true
        frame:HookScript("OnUpdate", function(self, elapsed)
            local s = self.__nolFade
            if not s or not s.d or s.d <= 0 then return end
            if s.t >= s.d then return end

            s.t = s.t + (elapsed or 0)
            local p = s.t / s.d
            if p >= 1 then
                self:SetAlpha(s.a1)
                s.t = s.d
                return
            end
            self:SetAlpha(s.a0 + (s.a1 - s.a0) * p)
        end)
    end
end

function F:BindMouseover(container, btn, cfg)
    if not (container and btn and cfg) then return end
    if btn.__nolFadeBound then return end
    btn.__nolFadeBound = true

    local outA = Clamp(cfg.fadeOutAlpha ~= nil and cfg.fadeOutAlpha or 0, 0, 1)
    local inA  = Clamp(cfg.fadeInAlpha  ~= nil and cfg.fadeInAlpha  or 1, 0, 1)
    local inT  = tonumber(cfg.fadeInTime)  or 0.12
    local outT = tonumber(cfg.fadeOutTime) or 0.18
    local outDelay = tonumber(cfg.fadeOutDelay) or 0

    btn:HookScript("OnEnter", function()
        if container.__nolFadeOutTimer then
            container.__nolFadeOutTimer:Cancel()
            container.__nolFadeOutTimer = nil
        end
        F:To(container, inA, inT)
    end)

    btn:HookScript("OnLeave", function()
        if outDelay > 0 and C_Timer and C_Timer.NewTimer then
            container.__nolFadeOutTimer = C_Timer.NewTimer(outDelay, function()
                F:To(container, outA, outT)
            end)
        else
            F:To(container, outA, outT)
        end
    end)
end

-- mode: "show" | "hide" | "mouseover"
function F:Apply(frame, cfg)
    if not frame then return end
    cfg = cfg or {}

    local inCombat = InCombatLockdown and InCombatLockdown()
    local isProtected = (frame.IsProtected and frame:IsProtected()) or false
    local isForbidden = (frame.IsForbidden and frame:IsForbidden()) or false
    local combatUnsafe = inCombat and (isProtected or isForbidden)

    local mode = cfg.visibility or cfg.vis or "show"

    if mode == "show" then
        frame:EnableMouse(false)
        frame:SetAlpha(1)
        if not combatUnsafe then frame:Show() end
        frame.__nolFadeMode = "show"
        return
    end

    if mode == "hide" then
        frame:EnableMouse(false)
        frame:SetAlpha(0)
        if not combatUnsafe then frame:Hide() end
        frame.__nolFadeMode = "hide"
        return
    end

    local outA = Clamp(cfg.fadeOutAlpha ~= nil and cfg.fadeOutAlpha or 0, 0, 1)
    if not combatUnsafe then frame:Show() end
    frame:SetAlpha(outA)
    frame:EnableMouse(false)
    frame.__nolFadeMode = "mouseover"
end
