local ADDON_NAME, ns = ...

local Addon = CreateFrame("Frame")
ns.Addon = Addon
_G.Thisnthat_Databrokers_Addon = Addon

Addon.modules = {}
Addon.initialized = false
Addon.enabled = false

local defaults = {
    modules = {
        databrokers = {
            enabled = true,
        },
    },
    databrokers = {
        clockBroker = {
            enabled = true,
            useServerTime = false,
            use24Hour = false,
        },
        durabilityColors = {
            enabled = true,
            ok = {
                r = 0,
                g = 1,
                b = 0,
                a = 1,
            },
            warning = {
                r = 1,
                g = 1,
                b = 0,
                a = 1,
            },
            critical = {
                r = 1,
                g = 0,
                b = 0,
                a = 1,
            },
        },
        systemBroker = {
            enabled = true,
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
        },
        specializationBroker = {
            enabled = true,
            hideLootIconWhenSame = true,
        },
        options = {
            selectedBrokerKey = "clockBroker",
        },
    },
    globalMedia = {
        font = nil,
        fontSize = 12,
    },
}

local function DeepCopyTable(src)
    if type(src) ~= "table" then
        return src
    end

    local out = {}
    for k, v in pairs(src) do
        out[k] = DeepCopyTable(v)
    end

    return out
end

local function MergeDefaults(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return
    end

    for k, v in pairs(source) do
        if target[k] == nil then
            target[k] = DeepCopyTable(v)
        elseif type(v) == "table" and type(target[k]) == "table" then
            MergeDefaults(target[k], v)
        end
    end
end

function Addon:Print(message)
    local prefix = "|cff4ec9b0" .. ADDON_NAME .. "|r"
    print(prefix .. ": " .. tostring(message))
end

function Addon:RegisterModule(name, module)
    assert(type(name) == "string" and name ~= "", "Module name must be a non-empty string")
    assert(type(module) == "table", "Module must be a table")

    module.name = name
    self.modules[name] = module
end

function Addon:GetModule(name)
    return self.modules[name]
end

function Addon:IsModuleEnabled(name)
    local moduleConfig = self.db and self.db.modules and self.db.modules[name]
    if moduleConfig and moduleConfig.enabled ~= nil then
        return moduleConfig.enabled
    end

    return true
end

function Addon:GetGlobalMediaConfig()
    self.db = type(self.db) == "table" and self.db or {}
    self.db.globalMedia = type(self.db.globalMedia) == "table" and self.db.globalMedia or {}

    local cfg = self.db.globalMedia
    cfg.font = type(cfg.font) == "string" and cfg.font or nil
    cfg.fontSize = tonumber(cfg.fontSize) or 12

    return cfg
end

function Addon:InitializeModules()
    for name, module in pairs(self.modules) do
        if self:IsModuleEnabled(name) and type(module.OnInitialize) == "function" then
            local ok, err = pcall(module.OnInitialize, module, self)
            if not ok then
                self:Print("Failed to initialize module '" .. name .. "': " .. tostring(err))
            end
        end
    end
end

function Addon:EnableModules()
    for name, module in pairs(self.modules) do
        if self:IsModuleEnabled(name) and type(module.OnEnable) == "function" then
            local ok, err = pcall(module.OnEnable, module, self)
            if not ok then
                self:Print("Failed to enable module '" .. name .. "': " .. tostring(err))
            end
        end
    end
end

Addon:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedName = ...
        if loadedName ~= ADDON_NAME then
            return
        end

        Thisnthat_DatabrokersDB = type(Thisnthat_DatabrokersDB) == "table" and Thisnthat_DatabrokersDB or {}
        Addon.db = Thisnthat_DatabrokersDB
        MergeDefaults(Addon.db, defaults)
        Addon:InitializeModules()
        Addon.initialized = true
    elseif event == "PLAYER_LOGIN" then
        if not Addon.initialized then
            return
        end

        Addon:EnableModules()
        Addon.enabled = true
    end
end)

Addon:RegisterEvent("ADDON_LOADED")
Addon:RegisterEvent("PLAYER_LOGIN")