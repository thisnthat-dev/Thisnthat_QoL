local ADDON_NAME, ns = ...

local brokerName = ADDON_NAME .. " Clock"
local dataObject = nil
local addonRef = nil
local moduleRef = nil
local refreshFrame = nil
local eventFrame = nil

local totalPlayedSeconds = nil
local levelPlayedSeconds = nil
local loginTimestamp = time()
local lastTimePlayedRequest = 0

local function GetClockConfig()
    local databrokers = addonRef and addonRef.db and addonRef.db.databrokers
    local cfg = databrokers and databrokers.clockBroker
    if type(cfg) ~= "table" then
        return {
            useServerTime = false,
            use24Hour = false,
        }
    end

    return {
        useServerTime = cfg.useServerTime and true or false,
        use24Hour = cfg.use24Hour and true or false,
    }
end

local function FormatHour(hour, minute, second, use24Hour, includeSeconds)
    hour = tonumber(hour) or 0
    minute = tonumber(minute) or 0
    second = tonumber(second) or 0

    if use24Hour then
        if includeSeconds then
            return string.format("%02d:%02d:%02d", hour, minute, second)
        end

        return string.format("%02d:%02d", hour, minute)
    end

    local suffix = "AM"
    local displayHour = hour
    if displayHour == 0 then
        displayHour = 12
    elseif displayHour == 12 then
        suffix = "PM"
    elseif displayHour > 12 then
        displayHour = displayHour - 12
        suffix = "PM"
    end

    if includeSeconds then
        return string.format("%d:%02d:%02d %s", displayHour, minute, second, suffix)
    end

    return string.format("%d:%02d %s", displayHour, minute, suffix)
end

local function GetLocalDateString()
    return date("%Y-%m-%d")
end

local function GetLocalTimeString(use24Hour, includeSeconds)
    local now = date("*t")
    return FormatHour(now.hour, now.min, now.sec, use24Hour, includeSeconds)
end

local function GetServerTimeString(use24Hour, includeSeconds)
    local getGameTime = rawget(_G, "GetGameTime")
    if type(getGameTime) == "function" then
        local ok, hour, minute = pcall(getGameTime)
        if ok and type(hour) == "number" and type(minute) == "number" then
            return FormatHour(hour, minute, 0, use24Hour, includeSeconds)
        end
    end

    return "--"
end

local function GetUtcTimeString(use24Hour, includeSeconds)
    local now = date("!*t")
    return FormatHour(now.hour, now.min, now.sec, use24Hour, includeSeconds)
end

local function FormatDuration(seconds)
    if type(seconds) ~= "number" or seconds < 0 then
        return "--"
    end

    local total = math.floor(seconds + 0.5)
    local days = math.floor(total / 86400)
    total = total % 86400
    local hours = math.floor(total / 3600)
    total = total % 3600
    local minutes = math.floor(total / 60)

    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, minutes)
    end

    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    end

    return string.format("%dm", minutes)
end

local function GetSessionPlayedSeconds()
    local getSessionTime = rawget(_G, "GetSessionTime")
    if type(getSessionTime) == "function" then
        local ok, value = pcall(getSessionTime)
        if ok and type(value) == "number" then
            return value
        end
    end

    local now = time()
    if type(now) == "number" and type(loginTimestamp) == "number" then
        return math.max(0, now - loginTimestamp)
    end

    return nil
end

local function GetSecondsUntilDailyReset()
    local cDateAndTime = rawget(_G, "C_DateAndTime")
    if type(cDateAndTime) == "table" and type(cDateAndTime.GetSecondsUntilDailyReset) == "function" then
        local ok, seconds = pcall(cDateAndTime.GetSecondsUntilDailyReset)
        if ok and type(seconds) == "number" and seconds >= 0 then
            return seconds
        end
    end

    local getQuestResetTime = rawget(_G, "GetQuestResetTime")
    if type(getQuestResetTime) == "function" then
        local ok, seconds = pcall(getQuestResetTime)
        if ok and type(seconds) == "number" and seconds >= 0 then
            return seconds
        end
    end

    return nil
end

local function RequestPlayedTime()
    local now = time()
    if type(now) ~= "number" or now - lastTimePlayedRequest < 5 then
        return
    end

    local requestTimePlayed = rawget(_G, "RequestTimePlayed")
    if type(requestTimePlayed) ~= "function" then
        return
    end

    lastTimePlayedRequest = now
    pcall(requestTimePlayed)
end

local function BuildText()
    local cfg = GetClockConfig()
    if cfg.useServerTime then
        return GetServerTimeString(cfg.use24Hour, false)
    end

    return GetLocalTimeString(cfg.use24Hour, false)
end

local function RefreshDataObject()
    if not dataObject then
        return
    end

    dataObject.text = BuildText()
    dataObject.icon = nil

    if moduleRef and type(moduleRef.RefreshBars) == "function" then
        moduleRef:RefreshBars()
    end
end

local function BuildTooltip(tooltip)
    if not tooltip then
        return
    end

    local cfg = GetClockConfig()

    tooltip:AddLine("Clock")
    tooltip:AddLine(" ")
    tooltip:AddLine("Time", 1, 0.82, 0)
    tooltip:AddDoubleLine("Date", GetLocalDateString(), 0.7, 0.7, 0.7, 1, 1, 1)
    tooltip:AddDoubleLine("Local Time", GetLocalTimeString(cfg.use24Hour, true), 0.7, 0.7, 0.7, 1, 1, 1)
    tooltip:AddDoubleLine("Server Time", GetServerTimeString(cfg.use24Hour, true), 0.7, 0.7, 0.7, 1, 1, 1)
    tooltip:AddDoubleLine("UTC Time", GetUtcTimeString(cfg.use24Hour, true), 0.7, 0.7, 0.7, 1, 1, 1)

    tooltip:AddLine(" ")
    tooltip:AddLine("Played Time", 1, 0.82, 0)
    tooltip:AddDoubleLine("Total", FormatDuration(totalPlayedSeconds), 0.7, 0.7, 0.7, 1, 1, 1)
    tooltip:AddDoubleLine("This Level", FormatDuration(levelPlayedSeconds), 0.7, 0.7, 0.7, 1, 1, 1)
    tooltip:AddDoubleLine("This Session", FormatDuration(GetSessionPlayedSeconds()), 0.7, 0.7, 0.7, 1, 1, 1)

    tooltip:AddLine(" ")
    tooltip:AddLine("Reset Times", 1, 0.82, 0)
    tooltip:AddDoubleLine("Daily Reset", FormatDuration(GetSecondsUntilDailyReset()), 0.7, 0.7, 0.7, 1, 1, 1)
end

local function OpenCalendarWindow()
    local toggleCalendar = rawget(_G, "ToggleCalendar")
    if type(toggleCalendar) == "function" then
        pcall(toggleCalendar)
        return
    end

    local calendarFrame = rawget(_G, "CalendarFrame")
    local showUIPanel = rawget(_G, "ShowUIPanel")
    if calendarFrame and type(showUIPanel) == "function" then
        pcall(showUIPanel, calendarFrame)
    end
end

local function EnsureRefreshFrame()
    if refreshFrame then
        return
    end

    refreshFrame = CreateFrame("Frame")
    refreshFrame.elapsed = 0
    refreshFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 1 then
            return
        end

        self.elapsed = 0
        RefreshDataObject()
    end)
end

local function EnsureEventFrame()
    if eventFrame then
        return
    end

    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("TIME_PLAYED_MSG")
    eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "TIME_PLAYED_MSG" then
            local total, level = ...
            totalPlayedSeconds = type(total) == "number" and total or totalPlayedSeconds
            levelPlayedSeconds = type(level) == "number" and level or levelPlayedSeconds
            RefreshDataObject()
            return
        end

        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LEVEL_UP" then
            RequestPlayedTime()
            RefreshDataObject()
        end
    end)
end

local function InitializeBroker(addon, module, ldb)
    if dataObject or not (ldb and type(ldb.NewDataObject) == "function") then
        return brokerName
    end

    addonRef = addon
    moduleRef = module
    loginTimestamp = time()

    dataObject = ldb:NewDataObject(brokerName, {
        type = "data source",
        label = "Clock",
        text = "",
        icon = nil,
        OnClick = function(_, mouseButton)
            if mouseButton == "LeftButton" then
                OpenCalendarWindow()
            end
        end,
        OnTooltipShow = function(tooltip)
            BuildTooltip(tooltip)
        end,
    })

    EnsureRefreshFrame()
    EnsureEventFrame()
    RequestPlayedTime()
    RefreshDataObject()

    return brokerName
end

local function GetDatabrokersModule()
    local hostAddon = type(ns) == "table" and ns.Addon
    if hostAddon and type(hostAddon.GetModule) == "function" then
        return hostAddon:GetModule("databrokers")
    end

    return nil
end

local databrokersModule = GetDatabrokersModule()
if databrokersModule and type(databrokersModule.RegisterCustomBroker) == "function" then
    databrokersModule:RegisterCustomBroker(InitializeBroker)
end