local ADDON_NAME, ns = ...

local brokerName = ADDON_NAME .. " Durability"
local dataObject = nil
local addonRef = nil
local moduleRef = nil
local eventFrame = nil

local DURABILITY_COLORS = {
    green = { r = 0, g = 1, b = 0 },
    yellow = { r = 1, g = 1, b = 0 },
    red = { r = 1, g = 0, b = 0 },
}

local DURABILITY_BROKER_COLOR_DEFAULTS = {
    ok = { r = 0, g = 1, b = 0, a = 1 },
    warning = { r = 1, g = 1, b = 0, a = 1 },
    critical = { r = 1, g = 0, b = 0, a = 1 },
}

local EQUIPPED_SLOTS = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
}

local function GetInventoryItemLinkFunction()
    return rawget(_G, "GetInventoryItemLink")
end

local function GetInventoryItemDurabilityFunction()
    return rawget(_G, "GetInventoryItemDurability")
end

local function ColorText(text, red, green, blue)
    return string.format("|cff%02x%02x%02x%s|r", math.floor((red or 1) * 255), math.floor((green or 1) * 255), math.floor((blue or 1) * 255), tostring(text))
end

local function GetDurabilityBrokerConfig()
    local databrokers = addonRef and addonRef.db and addonRef.db.databrokers
    local config = databrokers and databrokers.durabilityColors
    return type(config) == "table" and config or nil
end

local function GetConfiguredColor(colorName)
    local defaultColor = DURABILITY_BROKER_COLOR_DEFAULTS[colorName]
    if not defaultColor then
        return 1, 1, 1
    end

    local config = GetDurabilityBrokerConfig()
    local color = config and config[colorName]
    if type(color) == "table" then
        return color.r or defaultColor.r, color.g or defaultColor.g, color.b or defaultColor.b
    end

    return defaultColor.r, defaultColor.g, defaultColor.b
end

local function GetDurabilityColor(percent)
    if type(percent) ~= "number" then
        return GetConfiguredColor("ok")
    end

    if percent <= 20 then
        return GetConfiguredColor("critical")
    end

    if percent <= 50 then
        return GetConfiguredColor("warning")
    end

    return GetConfiguredColor("ok")
end

local function GetSlotItemLink(slotID)
    local getInventoryItemLink = GetInventoryItemLinkFunction()
    if type(getInventoryItemLink) ~= "function" then
        return nil
    end

    local ok, link = pcall(getInventoryItemLink, "player", slotID)
    if ok and type(link) == "string" and link ~= "" then
        return link
    end

    return nil
end

local function GetSlotDurability(slotID)
    local getInventoryItemDurability = GetInventoryItemDurabilityFunction()
    if type(getInventoryItemDurability) ~= "function" then
        return nil, nil
    end

    local ok, current, maximum = pcall(getInventoryItemDurability, slotID)
    if not ok or type(current) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then
        return nil, nil
    end

    return current, maximum
end

local function GetDurabilityPercent(current, maximum)
    if type(current) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then
        return nil
    end

    return math.floor(((current / maximum) * 100) + 0.5)
end

local function BuildDurabilitySnapshot()
    local lowestPercent = nil
    local items = {}

    for _, slotID in ipairs(EQUIPPED_SLOTS) do
        local link = GetSlotItemLink(slotID)
        if link then
            local current, maximum = GetSlotDurability(slotID)
            local percent = GetDurabilityPercent(current, maximum)
            if percent then
                items[#items + 1] = {
                    slotID = slotID,
                    link = link,
                    current = current,
                    maximum = maximum,
                    percent = percent,
                }

                if not lowestPercent or percent < lowestPercent then
                    lowestPercent = percent
                end
            end
        end
    end

    return lowestPercent, items
end

local function BuildText()
    local lowestPercent = BuildDurabilitySnapshot()
    if type(lowestPercent) ~= "number" then
        return "Durability: --"
    end

    local red, green, blue = GetDurabilityColor(lowestPercent)
    return "Durability: " .. ColorText(lowestPercent .. "%", red, green, blue)
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

    local items = select(2, BuildDurabilitySnapshot())
    tooltip:AddLine("Durability")

    if not items or #items == 0 then
        tooltip:AddLine("No equipped items with durability.")
        return
    end

    for _, item in ipairs(items) do
        local displayLink = item.link
        local red, green, blue = GetDurabilityColor(item.percent)
        local currentText = item.percent and (item.percent .. "%") or "N/A"

        tooltip:AddDoubleLine(displayLink, currentText, 1, 1, 1, red, green, blue)
    end
end

local function OpenCharacterWindow()
    local toggleCharacter = rawget(_G, "ToggleCharacter")
    if type(toggleCharacter) == "function" then
        pcall(toggleCharacter, "PaperDollFrame")
        return
    end

    local togglePaperDollInfo = rawget(_G, "TogglePaperDollInfo")
    if type(togglePaperDollInfo) == "function" then
        pcall(togglePaperDollInfo)
        return
    end

    local characterFrame = rawget(_G, "CharacterFrame")
    local showUIPanel = rawget(_G, "ShowUIPanel")
    if characterFrame and type(showUIPanel) == "function" then
        pcall(showUIPanel, characterFrame)
    end
end

local function EnsureEventFrame()
    if eventFrame then
        return
    end

    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
    eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    eventFrame:RegisterEvent("MERCHANT_SHOW")
    eventFrame:RegisterEvent("MERCHANT_CLOSED")
    eventFrame:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then
            return
        end

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
        label = "Durability",
        text = "",
        icon = nil,
        OnClick = function(_, mouseButton)
            if mouseButton == "LeftButton" then
                OpenCharacterWindow()
            end
        end,
        OnTooltipShow = function(tooltip)
            BuildTooltip(tooltip)
        end,
    })

    EnsureEventFrame()
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