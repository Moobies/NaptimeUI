-- Core/ButtonArt.lua
local ADDON, ns = ...
ns = ns or {}
ns.ButtonArt = ns.ButtonArt or {}
local A = ns.ButtonArt

local function KillTexture(tex)
    if not tex then return end
    if tex.SetTexture then pcall(tex.SetTexture, tex, nil) end
    if tex.SetAtlas then pcall(tex.SetAtlas, tex, nil) end
    if tex.SetAlpha then pcall(tex.SetAlpha, tex, 0) end
    if tex.Hide then pcall(tex.Hide, tex) end
end

local function HookKeepHidden(region)
    if not region or region.__nolKeepHidden then return end
    region.__nolKeepHidden = true

    -- If Blizzard tries to show it later, kill it again.
    if region.HookScript then
        pcall(region.HookScript, region, "OnShow", function(self)
            KillTexture(self)
        end)
    end
end

local function KillAndHook(tex)
    KillTexture(tex)
    HookKeepHidden(tex)
end

local function KillByNameIfMatches(btn, region)
    if not region or not region.GetName then return end
    local n = region:GetName()
    if not n then return end

    -- These cover most 11.x/12.x ActionButtonTemplate region names
    -- (Border / Slot / Shadow / Divider / FloatingBG / etc.)
    if n:find("Border") or
       n:find("Shadow") or
       n:find("Slot") or
       n:find("Floating") or
       n:find("Divider") or
       n:find("Frame") and n:find("Art") then
        KillAndHook(region)
    end
end

function A:StripActionButton(btn)
    if not btn or btn.__nolArtStripped then return end
    btn.__nolArtStripped = true

    -- Disable “show button art” if supported (11/12 templates)
    if btn.SetShowButtonArt then pcall(btn.SetShowButtonArt, btn, false) end
    btn.showButtonArt = false

    -- IMPORTANT: clear the built-in texture SLOTS (these come back otherwise)
    if btn.SetNormalTexture then pcall(btn.SetNormalTexture, btn, nil) end
    if btn.SetPushedTexture then pcall(btn.SetPushedTexture, btn, nil) end
    if btn.SetCheckedTexture then pcall(btn.SetCheckedTexture, btn, nil) end
    if btn.SetDisabledTexture then pcall(btn.SetDisabledTexture, btn, nil) end
    if btn.SetHighlightTexture then pcall(btn.SetHighlightTexture, btn, nil) end

    -- Kill common named fields (what you had, plus a few more)
    local killList = {
        btn.Border, btn.BorderShadow,
        btn.SlotArt, btn.SlotBackground, btn.IconBorder, btn.FloatingBG,
        btn.FlyoutBorder, btn.FlyoutBorderShadow,
        btn.RightDivider, btn.LeftDivider,
        btn.NewActionTexture, btn.SpellHighlightTexture, btn.Flash,
        btn.AutoCastable, btn.AutoCastOverlay,
    }
    for _, r in ipairs(killList) do
        if r then KillAndHook(r) end
    end

    -- Kill textures returned from getters too
    if btn.GetNormalTexture then KillAndHook(btn:GetNormalTexture()) end
    if btn.GetCheckedTexture then KillAndHook(btn:GetCheckedTexture()) end
    if btn.GetDisabledTexture then KillAndHook(btn:GetDisabledTexture()) end
    if btn.GetHighlightTexture then KillAndHook(btn:GetHighlightTexture()) end

    -- Mask (if you want square icons)
    if btn.IconMask and btn.IconMask.Hide then pcall(btn.IconMask.Hide, btn.IconMask) end

    -- NEW: brute-force scan all regions by name (catches ActionButton1Border etc.)
    if btn.GetRegions then
        for i = 1, select("#", btn:GetRegions()) do
            local r = select(i, btn:GetRegions())
            if r and r.GetObjectType and r:GetObjectType() == "Texture" then
                KillByNameIfMatches(btn, r)
            end
        end
    end

    -- If the template has an UpdateButtonArt method, Blizzard may reapply stuff.
    -- Re-strip after updates.
    if not btn.__nolHookedUpdate then
        btn.__nolHookedUpdate = true

        if btn.HookScript then
            pcall(btn.HookScript, btn, "OnShow", function(self)
                A:StripActionButton(self)
            end)
        end

        if btn.UpdateButtonArt then
            hooksecurefunc(btn, "UpdateButtonArt", function(self)
                A:StripActionButton(self)
            end)
        end
    end
end

function A:Strip(btn)
    return self:StripActionButton(btn)
end
