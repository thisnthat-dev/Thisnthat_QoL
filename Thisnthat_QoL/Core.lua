local ADDON_NAME, ns = ...
local OPTIONS_ADDON_NAME = "Thisnthat_QoL_Options"

local Addon = CreateFrame("Frame")
ns.Addon = Addon
_G.Thisnthat_QoL_Addon = Addon

local GLOBAL_TEXTURE_COLOR = { r = 0.09, g = 0.11, b = 0.14, a = 0.95 }
local GLOBAL_BORDER_COLOR = { r = 0.18, g = 0.24, b = 0.30, a = 1 }

Addon.modules = {}
Addon.initialized = false
Addon.enabled = false

local defaults = {
    modules = {
        DatabrokerPanels = {
            enabled = true,
        },
        databrokers = {
            enabled = true,
        },
        PerformanceSettings = {
            enabled = true,
        },
        MPlusRewards = {
            enabled = true,
        },
    },
    databrokers = {
        unlocked = false,
        whitelistEnabled = false,
        whitelist = {},
        bars = {},
    },
    globalMedia = {
        font = nil,
        fontSize = 12,
        useClassAccentColor = false,
        accentColor = { r = 0.78, g = 0.23, b = 0.30, a = 1 },
    },
    moduleMedia = {
        databrokers = {
            useGlobal = false,
            font = nil,
            fontSize = nil,
            statusbar = nil,
            border = nil,
            background = nil,
            textureColor = nil,
            borderColor = nil,
            borderSize = nil,
        },
        MPlusRewards = {
            useGlobal = false,
            font = nil,
            fontSize = 12,
            textureColor = nil,
            borderColor = nil,
        },
    },
}

local databrokerMediaDefaults = {
    font = nil,
    fontSize = 12,
    statusbar = nil,
    border = nil,
    background = nil,
    textureColor = { r = 0.09, g = 0.11, b = 0.14, a = 0.95 },
    borderColor = { r = 0.18, g = 0.24, b = 0.30, a = 1 },
    borderSize = 1,
}

local mplusRewardsMediaDefaults = {
    font = nil,
    fontSize = 12,
    textureColor = { r = 0.08, g = 0.08, b = 0.08, a = 0.94 },
    borderColor = { r = 0.31, g = 0.30, b = 0.30, a = 0.85 },
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

local function PruneDeprecatedSettings(db)
    if type(db) ~= "table" then
        return
    end

    if type(db.modules) == "table" then
        if type(db.modules.DatabrokerPanels) ~= "table" then
            db.modules.DatabrokerPanels = {}
        end

        if type(db.modules.databroker_bars) == "table" and db.modules.DatabrokerPanels.enabled == nil then
            db.modules.DatabrokerPanels.enabled = db.modules.databroker_bars.enabled
        end

        if db.modules.DatabrokerPanels.enabled == nil and type(db.modules.databrokers) == "table" then
            db.modules.DatabrokerPanels.enabled = db.modules.databrokers.enabled
        end

        if type(db.modules.PerformanceSettings) ~= "table" then
            db.modules.PerformanceSettings = {}
        end
        if type(db.modules.performanceSettings) == "table" and db.modules.PerformanceSettings.enabled == nil then
            db.modules.PerformanceSettings.enabled = db.modules.performanceSettings.enabled
        end
        if type(db.modules.fps) == "table" and db.modules.PerformanceSettings.enabled == nil then
            db.modules.PerformanceSettings.enabled = db.modules.fps.enabled
        end

        if type(db.modules.MPlusRewards) ~= "table" then
            db.modules.MPlusRewards = {}
        end
        if type(db.modules.mplus_rewards) == "table" and db.modules.MPlusRewards.enabled == nil then
            db.modules.MPlusRewards.enabled = db.modules.mplus_rewards.enabled
        end

        db.modules.databroker_bars = nil
        db.modules.performanceSettings = nil
        db.modules.fps = nil
        db.modules.mplus_rewards = nil
    end

    if type(db.databrokers) == "table" then
        db.databrokers.defaultBackgroundColor = nil
        db.databrokers.defaultBorderColor = nil
    end

    if type(db.moduleMedia) == "table" then
        db.moduleMedia.shared_media = nil

        local dbMedia = db.moduleMedia.databrokers
        if type(dbMedia) == "table" then
            dbMedia.useGlobal = false
        end

        if type(db.moduleMedia.MPlusRewards) ~= "table" then
            db.moduleMedia.MPlusRewards = {}
        end
        local legacyMplusMedia = db.moduleMedia.mplus_rewards
        if type(legacyMplusMedia) == "table" then
            for k, v in pairs(legacyMplusMedia) do
                if db.moduleMedia.MPlusRewards[k] == nil then
                    db.moduleMedia.MPlusRewards[k] = v
                end
            end
        end
        db.moduleMedia.mplus_rewards = nil

        local mplusMedia = db.moduleMedia.MPlusRewards
        if type(mplusMedia) == "table" then
            mplusMedia.useGlobal = false
            mplusMedia.textureColor = nil
            mplusMedia.borderColor = nil
            mplusMedia.statusbar = nil
            mplusMedia.border = nil
            mplusMedia.background = nil
            mplusMedia.borderSize = nil
        end
    end

    if type(db.MPlusRewards) ~= "table" then
        db.MPlusRewards = {}
    end
    if type(db.mplus_rewards) == "table" then
        for k, v in pairs(db.mplus_rewards) do
            if db.MPlusRewards[k] == nil then
                db.MPlusRewards[k] = v
            end
        end
        db.mplus_rewards = nil
    end

    if type(db.MPlusRewards) == "table" then
        db.MPlusRewards.x = nil
        db.MPlusRewards.y = nil
    end

    if type(db.globalMedia) == "table" then
        db.globalMedia.textureColor = nil
        db.globalMedia.borderColor = nil
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

local function EnsureDatabase()
    Thisnthat_QoLDB = type(Thisnthat_QoLDB) == "table" and Thisnthat_QoLDB or {}
    return Thisnthat_QoLDB
end

function Addon:InitializeDatabase()
    self.db = EnsureDatabase()
    MergeDefaults(self.db, defaults)
    PruneDeprecatedSettings(self.db)
end

function Addon:GetGlobalMediaConfig()
    self.db = type(self.db) == "table" and self.db or EnsureDatabase()
    self.db.globalMedia = type(self.db.globalMedia) == "table" and self.db.globalMedia or {}
    local cfg = self.db.globalMedia

    cfg.font = type(cfg.font) == "string" and cfg.font or nil
    cfg.fontSize = tonumber(cfg.fontSize) or 12
    cfg.useClassAccentColor = cfg.useClassAccentColor and true or false
    cfg.accentColor = type(cfg.accentColor) == "table" and cfg.accentColor or { r = 0.78, g = 0.23, b = 0.30, a = 1 }
    cfg.accentColor.r = tonumber(cfg.accentColor.r) or 0.78
    cfg.accentColor.g = tonumber(cfg.accentColor.g) or 0.23
    cfg.accentColor.b = tonumber(cfg.accentColor.b) or 0.30
    cfg.accentColor.a = tonumber(cfg.accentColor.a) or 1
    cfg.textureColor = nil
    cfg.borderColor = nil

    return cfg
end

function Addon:GetModuleMediaConfig(moduleName)
    self.db = type(self.db) == "table" and self.db or EnsureDatabase()
    self.db.moduleMedia = type(self.db.moduleMedia) == "table" and self.db.moduleMedia or {}
    self.db.moduleMedia[moduleName] = type(self.db.moduleMedia[moduleName]) == "table" and self.db.moduleMedia[moduleName] or {}

    local cfg = self.db.moduleMedia[moduleName]
    if moduleName == "databrokers" or moduleName == "MPlusRewards" then
        cfg.useGlobal = false
    else
        cfg.useGlobal = cfg.useGlobal ~= false
    end
    cfg.font = type(cfg.font) == "string" and cfg.font or nil
    cfg.fontSize = tonumber(cfg.fontSize)
    cfg.statusbar = type(cfg.statusbar) == "string" and cfg.statusbar or nil
    cfg.border = type(cfg.border) == "string" and cfg.border or nil
    cfg.background = type(cfg.background) == "string" and cfg.background or nil
    cfg.textureColor = type(cfg.textureColor) == "table" and cfg.textureColor or nil
    cfg.borderColor = type(cfg.borderColor) == "table" and cfg.borderColor or nil
    cfg.borderSize = tonumber(cfg.borderSize)

    return cfg
end

function Addon:GetResolvedMediaConfig(moduleName)
    local globalCfg = self:GetGlobalMediaConfig()
    local moduleCfg = self:GetModuleMediaConfig(moduleName)

    if moduleName == "databrokers" then
        return {
            useGlobal = false,
            font = moduleCfg.font or databrokerMediaDefaults.font,
            fontSize = moduleCfg.fontSize or databrokerMediaDefaults.fontSize,
            statusbar = moduleCfg.statusbar or databrokerMediaDefaults.statusbar,
            border = moduleCfg.border or databrokerMediaDefaults.border,
            background = moduleCfg.background or databrokerMediaDefaults.background,
            textureColor = moduleCfg.textureColor or databrokerMediaDefaults.textureColor,
            borderColor = moduleCfg.borderColor or databrokerMediaDefaults.borderColor,
            borderSize = moduleCfg.borderSize or databrokerMediaDefaults.borderSize,
        }
    end

    if moduleName == "MPlusRewards" then
        return {
            useGlobal = false,
            font = moduleCfg.font or mplusRewardsMediaDefaults.font,
            fontSize = moduleCfg.fontSize or mplusRewardsMediaDefaults.fontSize,
            textureColor = moduleCfg.textureColor or mplusRewardsMediaDefaults.textureColor,
            borderColor = moduleCfg.borderColor or mplusRewardsMediaDefaults.borderColor,
        }
    end

    if moduleCfg.useGlobal then
        return {
            useGlobal = true,
            font = globalCfg.font,
            fontSize = globalCfg.fontSize,
            textureColor = GLOBAL_TEXTURE_COLOR,
            borderColor = GLOBAL_BORDER_COLOR,
        }
    end

    return {
        useGlobal = false,
        font = moduleCfg.font or globalCfg.font,
        fontSize = moduleCfg.fontSize or globalCfg.fontSize,
        textureColor = moduleCfg.textureColor or GLOBAL_TEXTURE_COLOR,
        borderColor = moduleCfg.borderColor or GLOBAL_BORDER_COLOR,
    }
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

function Addon:OpenOptions()
    local showOptions = rawget(_G, "Thisnthat_QoL_ShowOptions")
    if type(showOptions) == "function" then
        showOptions("addon_settings")
        return
    end

    local isAddOnLoaded = rawget(_G, "IsAddOnLoaded")
    local optionsLoaded = type(isAddOnLoaded) == "function" and isAddOnLoaded(OPTIONS_ADDON_NAME) or false

    if not optionsLoaded then
        local okLoad, loadResult, loadReason = false, nil, nil

        if C_AddOns and type(C_AddOns.LoadAddOn) == "function" then
            okLoad, loadResult, loadReason = pcall(C_AddOns.LoadAddOn, OPTIONS_ADDON_NAME)
        else
            local loadAddOn = rawget(_G, "LoadAddOn")
            if type(loadAddOn) == "function" then
                okLoad, loadResult, loadReason = pcall(loadAddOn, OPTIONS_ADDON_NAME)
            end
        end

        if not okLoad or loadResult == false then
            local reason = type(loadReason) == "string" and loadReason or (type(loadResult) == "string" and loadResult or nil)
            if reason == "DISABLED" or reason == "MISSING" or reason == "NOT_DEMAND_LOADED" then
                self:Print("Options addon '" .. OPTIONS_ADDON_NAME .. "' is not available. Enable it and try again.")
            else
                self:Print("Could not load options addon '" .. OPTIONS_ADDON_NAME .. "'.")
            end
            return
        end
    end

    showOptions = rawget(_G, "Thisnthat_QoL_ShowOptions")
    if type(showOptions) == "function" then
        showOptions("addon_settings")
        return
    end

    local aceConfigDialog = LibStub and LibStub("AceConfigDialog-3.0", true)
    if aceConfigDialog and type(aceConfigDialog.Open) == "function" then
        aceConfigDialog:Open(ADDON_NAME)
        return
    end

    local category = self.optionsCategory
    local openLegacyCategory = rawget(_G, "InterfaceOptionsFrame_OpenToCategory")
    local settingsApi = rawget(_G, "Settings")
    if not category then
        self:Print("Options UI is not available. Enable '" .. OPTIONS_ADDON_NAME .. "' and try again.")
        return
    end

    if settingsApi and settingsApi.OpenToCategory and type(category) == "table" and type(category.GetID) == "function" then
        settingsApi.OpenToCategory(category:GetID())
        return
    end

    if type(openLegacyCategory) == "function" then
        openLegacyCategory(category)
        openLegacyCategory(category)
        return
    end

    self:Print("No supported options API found.")
end

SLASH_THISNTHAT_QOL1 = "/thisnthat_qol"
SLASH_THISNTHAT_QOL2 = "/thisnthat"
SLASH_THISNTHAT_QOL3 = "/tnt"
do
    local slashCmdList = rawget(_G, "SlashCmdList")
    if slashCmdList then
        slashCmdList.THISNTHAT_QOL = function(msg)
            local command = string.lower(tostring(msg or ""))
            command = string.gsub(command, "^%s+", "")
            command = string.gsub(command, "%s+$", "")

            if command == "help" or command == "?" then
                local isAddOnLoaded = rawget(_G, "IsAddOnLoaded")
                local optionsLoaded = type(isAddOnLoaded) == "function" and isAddOnLoaded(OPTIONS_ADDON_NAME) or false

                Addon:Print("Commands:")
                Addon:Print("/tnt - Open options")
                Addon:Print("/tnt m+ - Open M+ Rewards window")
                Addon:Print("/tnt help - Show this help")
                if not optionsLoaded then
                    Addon:Print("Options addon '" .. OPTIONS_ADDON_NAME .. "' is currently not loaded (load-on-demand).")
                end
                return
            end

            if command == "m+" then
                local mplusModule = Addon:GetModule("MPlusRewards")
                if mplusModule and type(mplusModule.OpenWindow) == "function" then
                    mplusModule:OpenWindow()
                    return
                end
                Addon:Print("M+ Rewards module is not available.")
                return
            end

            Addon:OpenOptions()
        end
    end
end

Addon:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedName = ...
        if loadedName ~= ADDON_NAME then
            return
        end

        Addon:InitializeDatabase()
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
