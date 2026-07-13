local ADDON_NAME, ns = ...

local brokerName = "TNT: System"
local dataObject = nil
local addonRef = nil
local moduleRef = nil
local refreshFrame = nil

local function ResolveBrokerLabel(noLabel, customLabel, fallback)
    if noLabel then
        return ""
    end

    local label = type(customLabel) == "string" and string.match(customLabel, "^%s*(.-)%s*$") or ""
    if label == "" then
        return fallback
    end

    return label
end

local SYSTEM_BROKER_COLOR_DEFAULTS = {
    fpsColors = {
        critical = { r = 1, g = 0, b = 0, a = 1 },
        warning = { r = 1, g = 1, b = 0, a = 1 },
        ok = { r = 0, g = 1, b = 0, a = 1 },
    },
    latencyColors = {
        critical = { r = 1, g = 0, b = 0, a = 1 },
        warning = { r = 1, g = 1, b = 0, a = 1 },
        ok = { r = 0, g = 1, b = 0, a = 1 },
    },
}

local function GetNetStatsFunction()
    return rawget(_G, "GetNetStats")
end

local function GetFramerateFunction()
    return rawget(_G, "GetFramerate")
end

local function GetHomeLatency()
    local getNetStats = GetNetStatsFunction()
    if type(getNetStats) ~= "function" then
        return nil
    end

    local ok, bandwidthIn, bandwidthOut, latencyHome = pcall(getNetStats)
    if not ok then
        return nil
    end

    if type(latencyHome) == "number" then
        return math.floor(latencyHome + 0.5)
    end

    return nil
end

local function GetWorldLatency()
    local getNetStats = GetNetStatsFunction()
    if type(getNetStats) ~= "function" then
        return nil
    end

    local ok, bandwidthIn, bandwidthOut, latencyHome, latencyWorld = pcall(getNetStats)
    if not ok then
        return nil
    end

    if type(latencyWorld) == "number" then
        return math.floor(latencyWorld + 0.5)
    end

    return nil
end

local function GetFPS()
    local getFramerate = GetFramerateFunction()
    if type(getFramerate) ~= "function" then
        return nil
    end

    local ok, framerate = pcall(getFramerate)
    if not ok or type(framerate) ~= "number" then
        return nil
    end

    return math.floor(framerate + 0.5)
end

local function ColorText(text, red, green, blue)
    return string.format("|cff%02x%02x%02x%s|r", math.floor((red or 1) * 255), math.floor((green or 1) * 255), math.floor((blue or 1) * 255), tostring(text))
end

local function ResolveColor(colorValue, defaultColor)
    local color = type(colorValue) == "table" and colorValue or defaultColor
    return color.r or defaultColor.r, color.g or defaultColor.g, color.b or defaultColor.b
end

local function GetSystemBrokerConfig()
    local databrokers = addonRef and addonRef.db and addonRef.db.databrokers
    local config = databrokers and databrokers.systemBroker
    if type(config) ~= "table" then
        return {
            enabled = true,
            noLabel = false,
            customLabel = "",
        }
    end

    return config
end

local function GetSystemColorPalette(paletteName)
    local config = GetSystemBrokerConfig()
    local palette = config and config[paletteName]
    if type(palette) ~= "table" then
        return nil
    end

    if paletteName == "fpsColors" then
        if type(palette.ok) ~= "table" and type(palette.green) == "table" then
            palette.ok = palette.green
        end
        if type(palette.warning) ~= "table" and type(palette.yellow) == "table" then
            palette.warning = palette.yellow
        end
        if type(palette.critical) ~= "table" and type(palette.red) == "table" then
            palette.critical = palette.red
        end

        palette.red = nil
        palette.orange = nil
        palette.yellow = nil
        palette.green = nil
    end

    if paletteName == "latencyColors" then
        if type(palette.ok) ~= "table" and type(palette.green) == "table" then
            palette.ok = palette.green
        end
        if type(palette.warning) ~= "table" and type(palette.yellow) == "table" then
            palette.warning = palette.yellow
        end
        if type(palette.critical) ~= "table" and type(palette.red) == "table" then
            palette.critical = palette.red
        end

        palette.red = nil
        palette.orange = nil
        palette.yellow = nil
        palette.green = nil
    end

    return palette
end

local function GetConfiguredColor(paletteName, colorName)
    local paletteDefaults = SYSTEM_BROKER_COLOR_DEFAULTS[paletteName]
    local defaultColor = paletteDefaults and paletteDefaults[colorName]
    if not defaultColor then
        return 1, 1, 1
    end

    local palette = GetSystemColorPalette(paletteName)
    return ResolveColor(palette and palette[colorName], defaultColor)
end

local function GetFpsColor(fps)
    if type(fps) ~= "number" then
        return 1, 1, 1
    end

    if fps < 20 then
        return GetConfiguredColor("fpsColors", "critical")
    end

    if fps < 60 then
        return GetConfiguredColor("fpsColors", "warning")
    end

    return GetConfiguredColor("fpsColors", "ok")
end

local function GetLatencyColor(latency)
    if type(latency) ~= "number" then
        return 1, 1, 1
    end

    if latency > 300 then
        return GetConfiguredColor("latencyColors", "critical")
    end

    if latency > 150 then
        return GetConfiguredColor("latencyColors", "warning")
    end

    return GetConfiguredColor("latencyColors", "ok")
end

local function BuildText()
    local homeLatency = GetHomeLatency() or 0
    local fps = GetFPS() or 0
    local fpsRed, fpsGreen, fpsBlue = GetFpsColor(fps)
    local latencyRed, latencyGreen, latencyBlue = GetLatencyColor(homeLatency)
    return "FPS: " .. ColorText(fps, fpsRed, fpsGreen, fpsBlue) .. " MS: " .. ColorText(homeLatency, latencyRed, latencyGreen, latencyBlue)
end

local function RefreshDataObject()
    if not dataObject then
        return
    end

    local config = GetSystemBrokerConfig()
    dataObject.label = ResolveBrokerLabel(config.noLabel, config.customLabel, "System")
    if config.enabled == false then
        dataObject.text = ""
        dataObject.icon = nil
        if moduleRef and type(moduleRef.RefreshBars) == "function" then
            moduleRef:RefreshBars()
        end
        return
    end

    dataObject.text = BuildText()
    dataObject.icon = nil

    if moduleRef and type(moduleRef.RefreshBars) == "function" then
        moduleRef:RefreshBars()
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

local function InitializeBroker(addon, module, ldb)
    if dataObject or not (ldb and type(ldb.NewDataObject) == "function") then
        return brokerName
    end

    addonRef = addon
    moduleRef = module

    dataObject = ldb:NewDataObject(brokerName, {
        type = "data source",
        label = "System",
        text = "",
        icon = nil,
        OnTooltipShow = function(tooltip)
            if not tooltip then
                return
            end

            local homeLatency = GetHomeLatency() or 0
            local worldLatency = GetWorldLatency() or 0
            local fps = GetFPS() or 0

            tooltip:AddLine("System")
            local homeRed, homeGreen, homeBlue = GetLatencyColor(homeLatency)
            local worldRed, worldGreen, worldBlue = GetLatencyColor(worldLatency)
            local fpsRed, fpsGreen, fpsBlue = GetFpsColor(fps)

            tooltip:AddDoubleLine("Home Latency", ColorText(homeLatency .. " ms", homeRed, homeGreen, homeBlue), 0.7, 0.7, 0.7, homeRed, homeGreen, homeBlue)
            tooltip:AddDoubleLine("World Latency", ColorText(worldLatency .. " ms", worldRed, worldGreen, worldBlue), 0.7, 0.7, 0.7, worldRed, worldGreen, worldBlue)
            tooltip:AddDoubleLine("FPS", ColorText(fps, fpsRed, fpsGreen, fpsBlue), 0.7, 0.7, 0.7, fpsRed, fpsGreen, fpsBlue)
        end,
    })

    EnsureRefreshFrame()
    RefreshDataObject()

    if moduleRef and type(moduleRef.RegisterCustomBrokerRefresher) == "function" then
        moduleRef:RegisterCustomBrokerRefresher(RefreshDataObject)
    end

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