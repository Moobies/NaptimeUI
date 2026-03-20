local ADDON, ns = ...
ns = ns or {}

ns.Modules = ns.Modules or {}
ns.Modules.ChatStyle = ns.Modules.ChatStyle or {}
local C = ns.Modules.ChatStyle

local function GetChatCfg()
    local cfg = (ns.GetConfig and ns:GetConfig()) or ns.Config
    if type(cfg) ~= "table" then return nil end
    if type(cfg.chat) ~= "table" then return nil end
    return cfg.chat
end

local function IsFontPath(v)
    return type(v) == "string" and (
        v:find("\\") or v:lower():match("%.ttf$") or v:lower():match("%.otf$")
    )
end

local function ResolveFont(fontKeyOrPath)
    if IsFontPath(fontKeyOrPath) then
        return fontKeyOrPath
    end
    return (ns.GetFont and ns:GetFont(fontKeyOrPath or "Default")) or "Fonts\\FRIZQT__.TTF"
end

local function ApplyChatFont()
    local cfg = GetChatCfg()
    if type(cfg) ~= "table" then return end

    local font  = ResolveFont(cfg.font or "Default")
    local size  = tonumber(cfg.size) or 12
    local flags = cfg.flags or "OUTLINE"

    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        if cf and cf.SetFont then
            local ok = pcall(cf.SetFont, cf, font, size, flags)
            if not ok then
                pcall(cf.SetFont, cf, "Fonts\\FRIZQT__.TTF", size, flags)
            end

            if type(FCF_SetChatWindowFontSize) == "function" then
                pcall(FCF_SetChatWindowFontSize, nil, cf, size)
            end
        end
    end
end

local ABBR = {
    ["General"] = "G",
    ["Trade"] = "T",
    ["LocalDefense"] = "L",
    ["Local Defence"] = "L",
    ["WorldDefense"] = "WD",
    ["LookingForGroup"] = "LFG",
    ["GuildRecruitment"] = "GR",
    ["Guild Recruitment"] = "GR",
    ["Services"] = "S",

    ["Guild"] = "G",
    ["Officer"] = "O",
    ["Party"] = "P",
    ["Party Leader"] = "PL",
    ["Raid"] = "R",
    ["Raid Leader"] = "RL",
    ["Raid Warning"] = "RW",
    ["Instance"] = "I",
    ["Instance Leader"] = "IL",
    ["Say"] = "S",
    ["Yell"] = "Y",
    ["Whisper"] = "W",
    ["Whisper To"] = "W",
}

local function AbbrevChannelTag(msg)
    if type(msg) ~= "string" then return msg end

    msg = msg:gsub("%[(%d+)%. ([^%-%]]+)%s*%-%s*[^%]]+%]", function(_, chan)
        chan = chan:gsub("%s+$", "")
        return ("[%s]"):format(ABBR[chan] or chan)
    end)

    msg = msg:gsub("%[(%d+)%. ([^%]]+)%]", function(_, chan)
        chan = chan:gsub("%s+$", "")
        return ("[%s]"):format(ABBR[chan] or chan)
    end)

    msg = msg:gsub("%[([^%]]+)%]", function(tag)
        return ("[%s]"):format(ABBR[tag] or tag)
    end)

    return msg
end

local function BuildTimestamp()
    local cfg = GetChatCfg()
    if type(cfg) ~= "table" or cfg.timestamps == false then
        return ""
    end

    local fmt = cfg.timestampFormat or "%H:%M"
    local sep = cfg.timestampSeparator or " | "

    return date(fmt) .. sep
end

local function MessageFilter(_, _, msg, ...)
    if type(msg) ~= "string" then
        return false, msg, ...
    end

    msg = AbbrevChannelTag(msg)

    local cfg = GetChatCfg()
    if cfg and cfg.timestamps ~= false then
        local ts = BuildTimestamp()
        if ts ~= "" and not msg:find("^%d%d:%d%d") then
            msg = ts .. msg
        end
    end

    return false, msg, ...
end

local function SetupMessageFilters()
    if C.__filtersHooked then return end
    C.__filtersHooked = true

    local events = {
        "CHAT_MSG_CHANNEL",
        "CHAT_MSG_SAY",
        "CHAT_MSG_YELL",
        "CHAT_MSG_GUILD",
        "CHAT_MSG_OFFICER",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_INSTANCE_CHAT",
        "CHAT_MSG_INSTANCE_CHAT_LEADER",
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_BN_WHISPER",
        "CHAT_MSG_BN_WHISPER_INFORM",
    }

    for _, event in ipairs(events) do
        ChatFrame_AddMessageEventFilter(event, MessageFilter)
    end
end

function C:Apply()
    ApplyChatFont()
    SetupMessageFilters()
end

function C:Enable()
    if self.__enabled then return end
    self.__enabled = true

    local f = CreateFrame("Frame")
    self.__driver = f

    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("UPDATE_CHAT_WINDOWS")
    f:RegisterEvent("CHANNEL_UI_UPDATE")

    f:SetScript("OnEvent", function()
        C_Timer.After(0, function() self:Apply() end)
        C_Timer.After(0.20, function() self:Apply() end)
        C_Timer.After(0.60, function() self:Apply() end)
    end)

    C_Timer.After(0, function() self:Apply() end)
    C_Timer.After(0.20, function() self:Apply() end)
    C_Timer.After(0.60, function() self:Apply() end)
end
