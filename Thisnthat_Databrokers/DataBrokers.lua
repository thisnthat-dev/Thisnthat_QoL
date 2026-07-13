local ADDON_NAME, ns = ...

local Addon = type(ns) == "table" and ns.Addon
if not Addon then
    return
end

local DataBrokers = {
    Names = {},
    Initializers = {},
    Refreshers = {},
    initialized = false,
}

ns.DataBrokers = DataBrokers
_G.Thisnthat_Databrokers_DataBrokers = DataBrokers

local LDB = LibStub and LibStub("LibDataBroker-1.1", true)

local function AddCustomBrokerName(name)
    if type(name) ~= "string" or name == "" then
        return
    end

    for _, existingName in ipairs(DataBrokers.Names) do
        if existingName == name then
            return
        end
    end

    DataBrokers.Names[#DataBrokers.Names + 1] = name
    table.sort(DataBrokers.Names)
end

local function BuildBrokerMap()
    local brokersByName = {}
    local names = {}

    if not LDB or type(LDB.DataObjectIterator) ~= "function" then
        return brokersByName, names
    end

    for name, dataObject in LDB:DataObjectIterator() do
        brokersByName[name] = dataObject
        names[#names + 1] = name
    end

    table.sort(names)
    return brokersByName, names
end

function DataBrokers:RegisterBroker(initializer)
    if type(initializer) ~= "function" then
        return
    end

    self.Initializers[#self.Initializers + 1] = initializer

    if self.initialized then
        local ok, brokerName = pcall(initializer, Addon, self, LDB)
        if ok then
            AddCustomBrokerName(brokerName)
        else
            Addon:Print("Failed to initialize custom DataBroker: " .. tostring(brokerName))
        end
    end
end

function DataBrokers:RegisterBrokerRefresher(refresher)
    if type(refresher) ~= "function" then
        return
    end

    self.Refreshers[#self.Refreshers + 1] = refresher
end

function DataBrokers:RefreshCustomBrokers()
    for _, refresher in ipairs(self.Refreshers) do
        local ok, err = pcall(refresher)
        if not ok then
            Addon:Print("Failed to refresh custom DataBroker: " .. tostring(err))
        end
    end
end

function DataBrokers:InitializeCustomBrokers()
    if self.initialized then
        return
    end

    self.initialized = true

    for _, initializer in ipairs(self.Initializers) do
        local ok, brokerName = pcall(initializer, Addon, self, LDB)
        if ok then
            AddCustomBrokerName(brokerName)
        else
            Addon:Print("Failed to initialize custom DataBroker: " .. tostring(brokerName))
        end
    end
end

function DataBrokers:GetCustomBrokerNames()
    local out = {}
    for i, name in ipairs(self.Names) do
        out[i] = name
    end
    return out
end

_G.Thisnthat_Databrokers_GetCustomBrokerNames = function()
    return DataBrokers:GetCustomBrokerNames()
end

function DataBrokers:GetAvailableBrokerNames()
    local _, names = BuildBrokerMap()
    return names
end
