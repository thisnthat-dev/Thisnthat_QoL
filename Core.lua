local ADDON_NAME, ns = ...

local Addon = CreateFrame("Frame")
ns.Addon = Addon
_G.Thisnthat_Addon = Addon
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
        EllesmereUIAbsorb = {
            enabled = true,
        },
        PerformanceSettings = {
            enabled = true,
        },
        MPlusRewards = {
            enabled = true,
        },
        Macros = {
            enabled = true,
        },
        Consumables = {
            enabled = true,
            hideInCombat = false,
            hideInEncounter = false,
            tracking = {
                healthPotion = true,
                combatPotion = true,
                flask = true,
                oil = true,
                food = true,
                feast = true,
                battleRes = true,
            },
            alerts = {
                healthPotion = { enabled = true, minCount = 5, countSource = "TOTAL" },
                combatPotion = { enabled = true, minCount = 5, countSource = "TOTAL" },
                flask = { enabled = true, minCount = 5, countSource = "TOTAL" },
                oil = { enabled = true, minCount = 5, countSource = "TOTAL" },
                food = { enabled = true, minCount = 5, countSource = "TOTAL" },
                feast = { enabled = true, minCount = 5, countSource = "TOTAL" },
                battleRes = { enabled = true, minCount = 5, countSource = "TOTAL" },
            },
            battleRes = {
                disableIfClassHasSpell = false,
            },
            flask = {
                defaultType = "crit",
                specOverrides = {},
            },
            combatPotion = {
                defaultType = "lights_potential",
                specOverrides = {},
            },
            iconWidth = 36,
            iconHeight = 36,
            iconGap = 4,
            qualitySize = 12,
        },
        ElvUI = {},
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
    macros = {
        sectionState = {},
        flask = {
            enabled = true,
            macroName = "TNT: Flask",
            roleDefaults = {
                TANK = "VERSATILITY",
                HEALER = "MASTERY",
                MELEE = "HASTE",
                RANGED = "CRIT",
            },
            specOverrides = {},
        },
        healingPotion = {
            enabled = true,
            macroName = "TNT: Healing Potion",
            useSoulburnForHealthstone = false,
            useRecuperateOutOfCombat = false,
            enableHealthstones = true,
            enableHealingPotions = true,
            addStopCast = false,
            prioritizeHealingPotions = false,
        },
        combatPotion = {
            enabled = true,
            macroName = "TNT: Combat Potion",
            roleDefaults = {
                TANK = "LIGHTS_POTENTIAL",
                HEALER = "LIGHTS_POTENTIAL",
                MELEE = "RECKLESSNESS",
                RANGED = "LIGHTS_POTENTIAL",
            },
            specOverrides = {},
        },
        food = {
            macroName = "TNT: Food",
        },
        drink = {
            enabled = true,
            macroName = "TNT: Drink",
            order = { "TEA", "MAGE_FOOD", "WATER" },
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

local PROFILE_EXPORT_PREFIX_V1 = "TNTQOL_PROFILE_V1:"
local PROFILE_EXPORT_PREFIX_V2 = "TNTQOL_PROFILE_V2:"

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

local function Trim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
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

local function EnsureRootDatabase()
    ThisnthatDB = type(ThisnthatDB) == "table" and ThisnthatDB or {}
    return ThisnthatDB
end

local function GetLibDeflate()
    if type(LibStub) == "table" and type(LibStub.GetLibrary) == "function" then
        local lib = LibStub("LibDeflate", true)
        if type(lib) == "table" then
            return lib
        end
    end

    local globalLib = rawget(_G, "LibDeflate")
    if type(globalLib) == "table" then
        return globalLib
    end

    return nil
end

local function IsIdentifierKey(key)
    return type(key) == "string" and string.match(key, "^[_%a][_%w]*$") ~= nil
end

local function SerializeValue(value, seen)
    local valueType = type(value)
    if valueType == "nil" then
        return "nil"
    end
    if valueType == "boolean" then
        return value and "true" or "false"
    end
    if valueType == "number" then
        if value ~= value then
            return "0"
        end
        if value == math.huge then
            return "1/0"
        end
        if value == -math.huge then
            return "-1/0"
        end
        return tostring(value)
    end
    if valueType == "string" then
        return string.format("%q", value)
    end
    if valueType ~= "table" then
        return nil
    end

    if seen[value] then
        return nil
    end
    seen[value] = true

    local keys = {}
    for key in pairs(value) do
        keys[#keys + 1] = key
    end

    table.sort(keys, function(a, b)
        if type(a) == type(b) and (type(a) == "number" or type(a) == "string") then
            return a < b
        end
        return tostring(a) < tostring(b)
    end)

    local parts = {}
    for _, key in ipairs(keys) do
        local serializedValue = SerializeValue(value[key], seen)
        local serializedKey = SerializeValue(key, seen)
        if serializedValue and serializedKey then
            local keyPart = IsIdentifierKey(key) and key or ("[" .. serializedKey .. "]")
            parts[#parts + 1] = keyPart .. "=" .. serializedValue
        end
    end

    seen[value] = nil
    return "{" .. table.concat(parts, ",") .. "}"
end

local function SerializeTable(value)
    if type(value) ~= "table" then
        return nil
    end
    return SerializeValue(value, {})
end

local function DeserializeTable(serializedText)
    local text = Trim(serializedText)
    if text == "" then
        return nil, "Import text is empty"
    end

    local loader = rawget(_G, "loadstring") or rawget(_G, "load")
    if type(loader) ~= "function" then
        return nil, "Lua loader is unavailable"
    end

    local chunk, loadErr = loader("return " .. text)
    if not chunk then
        return nil, tostring(loadErr or "Invalid profile payload")
    end

    local setEnv = rawget(_G, "setfenv")
    if type(setEnv) == "function" then
        setEnv(chunk, {})
    end

    local ok, result = pcall(chunk)
    if not ok then
        return nil, tostring(result)
    end
    if type(result) ~= "table" then
        return nil, "Profile payload must decode to a table"
    end

    return result
end

local function IsAddOnLoadedByName(addOnName)
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        return C_AddOns.IsAddOnLoaded(addOnName) and true or false
    end

    local isAddOnLoaded = rawget(_G, "IsAddOnLoaded")
    if type(isAddOnLoaded) == "function" then
        return isAddOnLoaded(addOnName) and true or false
    end

    return false
end

function Addon:GetDefaultProfileTemplate()
    return DeepCopyTable(defaults)
end

function Addon:NormalizeProfile(profile)
    if type(profile) ~= "table" then
        return
    end

    MergeDefaults(profile, defaults)
    PruneDeprecatedSettings(profile)

    profile.modules = type(profile.modules) == "table" and profile.modules or {}
    profile.modules.ElvUI = type(profile.modules.ElvUI) == "table" and profile.modules.ElvUI or {}
    if profile.modules.ElvUI.enabled == nil then
        profile.modules.ElvUI.enabled = IsAddOnLoadedByName("ElvUI")
    end
end

function Addon:GetProfileNames()
    local root = self.rootDB or EnsureRootDatabase()
    root.profiles = type(root.profiles) == "table" and root.profiles or {}

    local names = {}
    for name, profile in pairs(root.profiles) do
        if type(name) == "string" and type(profile) == "table" then
            names[#names + 1] = name
        end
    end

    table.sort(names)
    return names
end

function Addon:GetUniqueProfileName(baseName)
    local root = self.rootDB or EnsureRootDatabase()
    root.profiles = type(root.profiles) == "table" and root.profiles or {}

    local base = Trim(baseName)
    if base == "" then
        base = "Imported"
    end

    if type(root.profiles[base]) ~= "table" then
        return base
    end

    local index = 2
    while true do
        local candidate = string.format("%s (%d)", base, index)
        if type(root.profiles[candidate]) ~= "table" then
            return candidate
        end
        index = index + 1
    end
end

function Addon:GetActiveProfileName()
    local root = self.rootDB or EnsureRootDatabase()
    return type(root.activeProfile) == "string" and root.activeProfile or "Default"
end

function Addon:GetActiveProfileTable()
    if type(self.db) == "table" then
        return self.db
    end

    self:InitializeDatabase()
    return self.db
end

function Addon:ApplyProfile()
    for name, module in pairs(self.modules) do
        local enabled = self:IsModuleEnabled(name)

        if enabled then
            if not module._tntInitialized and type(module.OnInitialize) == "function" then
                local okInit, errInit = pcall(module.OnInitialize, module, self)
                if okInit then
                    module._tntInitialized = true
                else
                    self:Print("Failed to initialize module '" .. name .. "': " .. tostring(errInit))
                end
            end

            if not module._tntEnabled and type(module.OnEnable) == "function" then
                local okEnable, errEnable = pcall(module.OnEnable, module, self)
                if okEnable then
                    module._tntEnabled = true
                else
                    self:Print("Failed to enable module '" .. name .. "': " .. tostring(errEnable))
                end
            end

            if type(module.Refresh) == "function" then
                local okRefresh, errRefresh = pcall(module.Refresh, module)
                if not okRefresh then
                    self:Print("Failed to refresh module '" .. name .. "': " .. tostring(errRefresh))
                end
            end
        else
            if module.frame and type(module.frame.Hide) == "function" then
                module.frame:Hide()
            end
            if type(module.RefreshVisibility) == "function" then
                pcall(module.RefreshVisibility, module)
            end
        end
    end

    if ns.OptionsFrame and type(ns.OptionsFrame.ApplyCurrentAccent) == "function" then
        ns.OptionsFrame:ApplyCurrentAccent()
    end
    if ns.OptionsFrame and type(ns.OptionsFrame.ApplyCurrentFont) == "function" then
        ns.OptionsFrame:ApplyCurrentFont()
    end
    if type(ns.RefreshCurrentPage) == "function" then
        ns.RefreshCurrentPage()
    end
end

function Addon:SetActiveProfile(profileName)
    local root = self.rootDB or EnsureRootDatabase()
    root.profiles = type(root.profiles) == "table" and root.profiles or {}

    local name = Trim(profileName)
    if name == "" then
        return false, "Profile name cannot be empty"
    end

    local profile = root.profiles[name]
    if type(profile) ~= "table" then
        return false, "Profile does not exist"
    end

    root.activeProfile = name
    self.profileName = name
    self.db = profile
    self:NormalizeProfile(self.db)
    self:ApplyProfile()
    return true
end

function Addon:CreateProfile(profileName, selectProfile)
    local root = self.rootDB or EnsureRootDatabase()
    root.profiles = type(root.profiles) == "table" and root.profiles or {}

    local name = Trim(profileName)
    if name == "" then
        return false, "Profile name cannot be empty"
    end
    if type(root.profiles[name]) == "table" then
        return false, "A profile with that name already exists"
    end

    root.profiles[name] = self:GetDefaultProfileTemplate()
    self:NormalizeProfile(root.profiles[name])

    if selectProfile then
        return self:SetActiveProfile(name)
    end

    return true, name
end

function Addon:CloneProfile(newProfileName, sourceProfileName, selectProfile)
    local root = self.rootDB or EnsureRootDatabase()
    root.profiles = type(root.profiles) == "table" and root.profiles or {}

    local targetName = Trim(newProfileName)
    if targetName == "" then
        return false, "Profile name cannot be empty"
    end
    if type(root.profiles[targetName]) == "table" then
        return false, "A profile with that name already exists"
    end

    local sourceName = Trim(sourceProfileName)
    if sourceName == "" then
        sourceName = self:GetActiveProfileName()
    end

    local sourceProfile = root.profiles[sourceName]
    if type(sourceProfile) ~= "table" then
        return false, "Source profile does not exist"
    end

    root.profiles[targetName] = DeepCopyTable(sourceProfile)
    self:NormalizeProfile(root.profiles[targetName])

    if selectProfile then
        return self:SetActiveProfile(targetName)
    end

    return true, targetName
end

function Addon:ResetProfile(profileName, selectProfile)
    local root = self.rootDB or EnsureRootDatabase()
    root.profiles = type(root.profiles) == "table" and root.profiles or {}

    local name = Trim(profileName)
    if name == "" then
        name = self:GetActiveProfileName()
    end
    if type(root.profiles[name]) ~= "table" then
        return false, "Profile does not exist"
    end

    root.profiles[name] = self:GetDefaultProfileTemplate()
    self:NormalizeProfile(root.profiles[name])

    if selectProfile then
        local ok, err = self:SetActiveProfile(name)
        if not ok then
            return false, err
        end
    elseif self:GetActiveProfileName() == name then
        self.db = root.profiles[name]
        self:ApplyProfile()
    end

    return true, name
end

function Addon:DeleteProfile(profileName)
    local root = self.rootDB or EnsureRootDatabase()
    root.profiles = type(root.profiles) == "table" and root.profiles or {}

    local name = Trim(profileName)
    if name == "" then
        return false, "Profile name cannot be empty"
    end
    if type(root.profiles[name]) ~= "table" then
        return false, "Profile does not exist"
    end

    local activeName = self:GetActiveProfileName()
    if activeName == name then
        return false, "Cannot delete the active profile. Switch profiles first."
    end

    root.profiles[name] = nil

    if next(root.profiles) == nil then
        root.profiles.Default = self:GetDefaultProfileTemplate()
        self:NormalizeProfile(root.profiles.Default)
        root.activeProfile = "Default"
        self.profileName = "Default"
        self.db = root.profiles.Default
        self:ApplyProfile()
    end

    return true
end

function Addon:ExportProfile(profileName)
    local root = self.rootDB or EnsureRootDatabase()
    root.profiles = type(root.profiles) == "table" and root.profiles or {}

    local name = Trim(profileName)
    if name == "" then
        name = self:GetActiveProfileName()
    end

    local profile = root.profiles[name]
    if type(profile) ~= "table" then
        return false, "Profile does not exist"
    end

    local payload = {
        version = 1,
        name = name,
        data = DeepCopyTable(profile),
    }
    local serialized = SerializeTable(payload)
    if not serialized then
        return false, "Could not serialize profile"
    end

    local libDeflate = GetLibDeflate()
    if not libDeflate then
        return true, PROFILE_EXPORT_PREFIX_V1 .. serialized
    end

    local compressed = libDeflate:CompressDeflate(serialized, { level = 9 })
    if type(compressed) ~= "string" or compressed == "" then
        return false, "Could not compress profile payload"
    end

    local encoded = libDeflate:EncodeForPrint(compressed)
    if type(encoded) ~= "string" or encoded == "" then
        return false, "Could not encode compressed profile payload"
    end

    return true, PROFILE_EXPORT_PREFIX_V2 .. encoded
end

local function DecodeImportPayload(serializedText)
    local text = Trim(serializedText)
    local decodedText = nil

    if string.sub(text, 1, #PROFILE_EXPORT_PREFIX_V2) == PROFILE_EXPORT_PREFIX_V2 then
        local libDeflate = GetLibDeflate()
        if not libDeflate then
            return nil, "LibDeflate is required to import compressed profile strings"
        end

        local encoded = string.sub(text, #PROFILE_EXPORT_PREFIX_V2 + 1)
        local compressed = libDeflate:DecodeForPrint(encoded)
        if type(compressed) ~= "string" then
            return nil, "Compressed profile text is invalid"
        end

        decodedText = libDeflate:DecompressDeflate(compressed)
        if type(decodedText) ~= "string" or decodedText == "" then
            return nil, "Could not decompress profile payload"
        end
    else
        decodedText = text
        if string.sub(decodedText, 1, #PROFILE_EXPORT_PREFIX_V1) == PROFILE_EXPORT_PREFIX_V1 then
            decodedText = string.sub(decodedText, #PROFILE_EXPORT_PREFIX_V1 + 1)
        end
    end

    local decoded, decodeErr = DeserializeTable(decodedText)
    if type(decoded) ~= "table" then
        return nil, decodeErr or "Invalid profile data"
    end

    return decoded
end

function Addon:InspectImportProfile(serializedText)
    local decoded, decodeErr = DecodeImportPayload(serializedText)
    if type(decoded) ~= "table" then
        return false, decodeErr or "Invalid profile data"
    end

    local incomingData = type(decoded.data) == "table" and decoded.data or decoded
    if type(incomingData) ~= "table" then
        return false, "Profile payload must decode to a table"
    end

    local incomingName = type(decoded.name) == "string" and Trim(decoded.name) or ""
    if incomingName == "" then
        incomingName = "Imported"
    end

    return true, incomingName
end

function Addon:ImportProfile(serializedText, requestedName, selectProfile, options)
    local root = self.rootDB or EnsureRootDatabase()
    root.profiles = type(root.profiles) == "table" and root.profiles or {}

    local decoded, decodeErr = DecodeImportPayload(serializedText)
    if type(decoded) ~= "table" then
        return false, decodeErr or "Invalid profile data"
    end

    local incomingData = type(decoded.data) == "table" and decoded.data or decoded
    local incomingName = type(decoded.name) == "string" and decoded.name or nil
    local name = Trim(requestedName)
    if name == "" then
        name = Trim(incomingName)
    end
    if name == "" then
        name = "Imported"
    end

    local collisionMode = type(options) == "table" and options.collisionMode or "overwrite"
    local existing = type(root.profiles[name]) == "table"
    if existing then
        if collisionMode == "auto_rename" then
            name = self:GetUniqueProfileName(name)
        elseif collisionMode == "fail" then
            return false, "A profile with that name already exists"
        else
            collisionMode = "overwrite"
        end
    end

    root.profiles[name] = DeepCopyTable(incomingData)
    self:NormalizeProfile(root.profiles[name])

    if selectProfile then
        local ok, err = self:SetActiveProfile(name)
        if not ok then
            return false, err
        end
    end

    return true, name
end

function Addon:InitializeDatabase()
    local root = EnsureRootDatabase()

    local needsMigration = type(root.profiles) ~= "table" or next(root.profiles) == nil
    if needsMigration then
        local recovered = {}
        for key, value in pairs(root) do
            if key ~= "profiles" and key ~= "activeProfile" then
                recovered[key] = DeepCopyTable(value)
            end
        end

        local migratedRoot = {
            profiles = {
                Default = self:GetDefaultProfileTemplate(),
            },
            activeProfile = "Default",
        }

        self:NormalizeProfile(migratedRoot.profiles.Default)

        if next(recovered) ~= nil then
            self:NormalizeProfile(recovered)
            migratedRoot.profiles.Recovered = recovered
            migratedRoot.activeProfile = "Recovered"
        end

        ThisnthatDB = migratedRoot
        root = migratedRoot
    end

    root.profiles = type(root.profiles) == "table" and root.profiles or {}
    if type(root.profiles.Default) ~= "table" then
        root.profiles.Default = self:GetDefaultProfileTemplate()
    end

    for key in pairs(root) do
        if key ~= "profiles" and key ~= "activeProfile" then
            root[key] = nil
        end
    end

    for name, profile in pairs(root.profiles) do
        if type(name) ~= "string" or type(profile) ~= "table" then
            root.profiles[name] = nil
        else
            self:NormalizeProfile(profile)
        end
    end

    if next(root.profiles) == nil then
        root.profiles.Default = self:GetDefaultProfileTemplate()
        self:NormalizeProfile(root.profiles.Default)
    end

    local activeName = type(root.activeProfile) == "string" and root.activeProfile or nil
    if not activeName or type(root.profiles[activeName]) ~= "table" then
        if type(root.profiles.Recovered) == "table" then
            activeName = "Recovered"
        else
            activeName = "Default"
        end
    end

    root.activeProfile = activeName
    self.rootDB = root
    self.profileName = activeName
    self.db = root.profiles[activeName]
    self:NormalizeProfile(self.db)
end

function Addon:GetProfileRoot()
    self.rootDB = type(self.rootDB) == "table" and self.rootDB or EnsureRootDatabase()
    self.rootDB.profiles = type(self.rootDB.profiles) == "table" and self.rootDB.profiles or {}
    return self.rootDB
end

function Addon:EnsureActiveProfile()
    if type(self.db) == "table" then
        return self.db
    end

    self:InitializeDatabase()
    return self.db
end

function Addon:GetGlobalMediaConfig()
    self.db = type(self.db) == "table" and self.db or self:EnsureActiveProfile()
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
    self.db = type(self.db) == "table" and self.db or self:EnsureActiveProfile()
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
            else
                module._tntInitialized = true
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
            else
                module._tntEnabled = true
            end
        end
    end
end

function Addon:OpenOptions()
    local showOptions = rawget(_G, "Thisnthat_ShowOptions")
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
        self:Print("Options UI is not available.")
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

SLASH_THISNTHAT1 = "/thisnthat"
SLASH_THISNTHAT2 = "/tnt"
do
    local slashCmdList = rawget(_G, "SlashCmdList")
    if slashCmdList then
        slashCmdList.THISNTHAT = function(msg)
            local command = string.lower(tostring(msg or ""))
            command = string.gsub(command, "^%s+", "")
            command = string.gsub(command, "%s+$", "")

            if command == "help" or command == "?" then
                Addon:Print("Commands:")
                Addon:Print("/tnt - Open options")
                Addon:Print("/tnt m+ - Open M+ Rewards window")
                Addon:Print("/tnt help - Show this help")
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
