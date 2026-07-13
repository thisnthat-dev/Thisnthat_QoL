local ADDON_NAME, ns = ...

local Addon = type(ns) == "table" and ns.Addon
if not Addon then
    return
end

local Module = {
    customBrokerNames = {},
    customBrokerInitializers = {},
    initialized = false,
}

Addon:RegisterModule("databrokers", Module)

local LDB = LibStub and LibStub("LibDataBroker-1.1", true)

local function AddCustomBrokerName(name)
    if type(name) ~= "string" or name == "" then
        return
    end

    for _, existingName in ipairs(Module.customBrokerNames) do
        if existingName == name then
            return
        end
    end

    Module.customBrokerNames[#Module.customBrokerNames + 1] = name
    table.sort(Module.customBrokerNames)
end

local function BuildBrokerMap()
    local byName = {}
    local names = {}

    if not LDB or type(LDB.DataObjectIterator) ~= "function" then
        return byName, names
    end

    for name, dataObject in LDB:DataObjectIterator() do
        byName[name] = dataObject
        names[#names + 1] = name
    end

    table.sort(names)
    return byName, names
end

function Module:RegisterCustomBroker(initializer)
    if type(initializer) ~= "function" then
        return
    end

    self.customBrokerInitializers[#self.customBrokerInitializers + 1] = initializer

    if self.initialized then
        local barsModule = Addon:GetModule("databroker_bars")
        local ok, brokerName = pcall(initializer, Addon, barsModule or self, LDB)
        if ok then
            AddCustomBrokerName(brokerName)
        else
            Addon:Print("Failed to initialize custom DataBroker: " .. tostring(brokerName))
        end
    end
end

function Module:InitializeCustomBrokers()
    if self.initialized then
        return
    end

    self.initialized = true

    local barsModule = Addon:GetModule("databroker_bars")

    for _, initializer in ipairs(self.customBrokerInitializers) do
        local ok, brokerName = pcall(initializer, Addon, barsModule or self, LDB)
        if ok then
            AddCustomBrokerName(brokerName)
        else
            Addon:Print("Failed to initialize custom DataBroker: " .. tostring(brokerName))
        end
    end
end

function Module:GetCustomBrokerNames()
    local out = {}
    for i, name in ipairs(self.customBrokerNames) do
        out[i] = name
    end
    return out
end

function Module:GetAvailableBrokerNames()
    local _, names = BuildBrokerMap()
    return names
end

function Module:OnInitialize()
    self:InitializeCustomBrokers()
end

function Module:OnEnable()
end
