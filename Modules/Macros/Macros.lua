local _, ns = ...

local Addon = ns.Addon
local Module = {
    frame = nil,
    pendingFlaskUpdate = false,
    pendingFlaskCreate = false,
    pendingCombatPotionUpdate = false,
    pendingCombatPotionCreate = false,
    pendingHealingPotionUpdate = false,
    pendingHealingPotionCreate = false,
    pendingWarlockHealthstoneUpdate = false,
    pendingWarlockHealthstoneCreate = false,
    healingCooldownTicker = nil,
    pendingDrinkUpdate = false,
    pendingDrinkCreate = false,
}

Addon:RegisterModule("Macros", Module)

local DEFAULT_DYNAMIC_MACRO_ICON = "INV_MISC_QUESTIONMARK"

local FLASK_STAT_ORDER = { "CRIT", "HASTE", "MASTERY", "VERSATILITY" }
local FLASK_STAT_LABELS = {
    CRIT = "Crit",
    HASTE = "Haste",
    MASTERY = "Mastery",
    VERSATILITY = "Versatility",
}

local FLASK_ITEM_PRIORITIES = {
    CRIT = { 245929, 245928, 241326, 241327 },
    HASTE = { 245931, 245930, 241324, 241325 },
    MASTERY = { 245933, 245932, 241322, 241323 },
    VERSATILITY = { 245926, 245927, 241320, 241321 },
}

local FLASK_ITEM_TO_STAT = {
    [245929] = "CRIT",
    [245928] = "CRIT",
    [241326] = "CRIT",
    [241327] = "CRIT",

    [245931] = "HASTE",
    [245930] = "HASTE",
    [241324] = "HASTE",
    [241325] = "HASTE",

    [245933] = "MASTERY",
    [245932] = "MASTERY",
    [241322] = "MASTERY",
    [241323] = "MASTERY",

    [245926] = "VERSATILITY",
    [245927] = "VERSATILITY",
    [241320] = "VERSATILITY",
    [241321] = "VERSATILITY",
}

local COMBAT_POTION_ORDER = { "LIGHTS_POTENTIAL", "RECKLESSNESS" }
local COMBAT_POTION_LABELS = {
    LIGHTS_POTENTIAL = "Light's Potential",
    RECKLESSNESS = "Recklessness",
}

local COMBAT_POTION_ITEM_PRIORITIES = {
    LIGHTS_POTENTIAL = {  245898, 245897, 241308, 241309},
    RECKLESSNESS = { 245902, 245903, 241288, 241289 },
}

local COMBAT_POTION_ITEM_TO_CHOICE = {
    [241308] = "LIGHTS_POTENTIAL",
    [241309] = "LIGHTS_POTENTIAL",
    [245898] = "LIGHTS_POTENTIAL",
    [245897] = "LIGHTS_POTENTIAL",

    [245902] = "RECKLESSNESS",
    [245903] = "RECKLESSNESS",
    [241288] = "RECKLESSNESS",
    [241289] = "RECKLESSNESS",
}

local SOULBURN_SPELL_ID = 385899
local RECUPERATE_SPELL_ID = 1231411
local PACT_OF_GLUTTONY_SPELL_ID = 386689
local DEMONIC_HEALTHSTONE_ITEM_ID = 224464
local HEALTHSTONE_ITEM_ID = 5512

local HEALING_POTION_ITEM_PRIORITIES = { 271884, 271883, 241304, 241305 }
local HEALTHSTONE_ITEM_PRIORITIES = { DEMONIC_HEALTHSTONE_ITEM_ID, HEALTHSTONE_ITEM_ID }

local DRINK_ENTRY_ORDER = { "TEA", "MAGE_FOOD", "WATER" }
local DRINK_ENTRY_LABELS = {
    TEA = "Tea",
    MAGE_FOOD = "Mage Food",
    WATER = "Water",
}

local DRINK_ENTRY_ITEM_IDS = {
    TEA = { 242297, 242298, 242299, 242300, 242301 },
    MAGE_FOOD = { 113509 },
    WATER = { 260260, 260261 },
}

local ROLE_ORDER = { "TANK", "HEALER", "MELEE", "RANGED" }
local ROLE_LABELS = {
    TANK = "Tank",
    HEALER = "Healer",
    MELEE = "Melee DPS",
    RANGED = "Ranged DPS",
}

local SPEC_ROLE_CATEGORY = {
    [62] = "RANGED", [63] = "RANGED", [64] = "RANGED", -- Mage
    [65] = "HEALER", [66] = "TANK", [70] = "MELEE", -- Paladin
    [71] = "MELEE", [72] = "MELEE", [73] = "TANK", -- Warrior
    [102] = "RANGED", [103] = "MELEE", [104] = "TANK", [105] = "HEALER", -- Druid
    [1467] = "RANGED", [1468] = "HEALER", [1473] = "RANGED", -- Evoker
    [250] = "TANK", [251] = "MELEE", [252] = "MELEE", -- Death Knight
    [253] = "RANGED", [254] = "RANGED", [255] = "MELEE", -- Hunter
    [256] = "HEALER", [257] = "HEALER", [258] = "RANGED", -- Priest
    [259] = "MELEE", [260] = "MELEE", [261] = "MELEE", -- Rogue
    [262] = "RANGED", [263] = "MELEE", [264] = "HEALER", -- Shaman
    [265] = "RANGED", [266] = "RANGED", [267] = "RANGED", -- Warlock
    [268] = "TANK", [269] = "MELEE", [270] = "HEALER", -- Monk
    [577] = "MELEE", [581] = "TANK", -- Demon Hunter
}

local function IsFlaskStat(value)
    return FLASK_STAT_LABELS[value] ~= nil
end

local function IsCombatPotionChoice(value)
    return COMBAT_POTION_LABELS[value] ~= nil
end

local function IsDrinkEntryKey(value)
    return DRINK_ENTRY_LABELS[value] ~= nil
end

local function NormalizeFlaskStat(value, fallback)
    if IsFlaskStat(value) then
        return value
    end

    return fallback
end

local function NormalizeCombatPotionChoice(value, fallback)
    if IsCombatPotionChoice(value) then
        return value
    end

    return fallback
end

local function BuildSpecStorageKey(classID, specID)
    return tostring(tonumber(classID) or 0) .. ":" .. tostring(tonumber(specID) or 0)
end

local function FindKeyword(text, keyword)
    return string.find(text, keyword, 1, true) ~= nil
end

local function ResolveBagItemInfo(bagID, slotID)
    if C_Container and type(C_Container.GetContainerItemInfo) == "function" then
        return C_Container.GetContainerItemInfo(bagID, slotID)
    end

    local getContainerItemID = rawget(_G, "GetContainerItemID")
    local itemID = type(getContainerItemID) == "function" and getContainerItemID(bagID, slotID) or nil
    if not itemID then
        return nil
    end

    local getContainerItemInfo = rawget(_G, "GetContainerItemInfo")
    local stackCount
    local quality
    if type(getContainerItemInfo) == "function" then
        local _, countValue, _, qualityValue = getContainerItemInfo(bagID, slotID)
        stackCount = countValue
        quality = qualityValue
    end

    return {
        itemID = itemID,
        stackCount = stackCount,
        quality = quality,
    }
end

local function GetBagSlotCount(bagID)
    if C_Container and type(C_Container.GetContainerNumSlots) == "function" then
        return tonumber(C_Container.GetContainerNumSlots(bagID)) or 0
    end

    local getContainerNumSlots = rawget(_G, "GetContainerNumSlots")
    if type(getContainerNumSlots) == "function" then
        return tonumber(getContainerNumSlots(bagID)) or 0
    end

    return 0
end

local function GetItemCooldownRemaining(itemID)
    local now = GetTime and GetTime() or 0

    if C_Item and type(C_Item.GetItemCooldown) == "function" then
        local cooldownInfo = C_Item.GetItemCooldown(itemID)
        if type(cooldownInfo) == "table" then
            local startTime = tonumber(cooldownInfo.startTime) or 0
            local duration = tonumber(cooldownInfo.duration) or 0
            local isEnabled = cooldownInfo.isEnabled
            if isEnabled == false then
                return 0
            end
            local remaining = (startTime + duration) - now
            return remaining > 0 and remaining or 0
        end
    end

    if type(C_Item.GetItemCooldown) == "function" then
        local startTime, duration, enableValue = C_Item.GetItemCooldown(itemID)
        startTime = tonumber(startTime) or 0
        duration = tonumber(duration) or 0
        if tonumber(enableValue) == 0 then
            return 0
        end
        local remaining = (startTime + duration) - now
        return remaining > 0 and remaining or 0
    end

    return 0
end

local function GetSpellCooldownRemaining(spellID)
    local now = GetTime and GetTime() or 0

    if C_Spell and type(C_Spell.GetSpellCooldown) == "function" then
        local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
        if type(cooldownInfo) == "table" then
            local startTime = tonumber(cooldownInfo.startTime) or 0
            local duration = tonumber(cooldownInfo.duration) or 0
            local isEnabled = cooldownInfo.isEnabled
            if isEnabled == false then
                return 0
            end
            local remaining = (startTime + duration) - now
            return remaining > 0 and remaining or 0
        end
    end

    if type(GetSpellCooldown) == "function" then
        local startTime, duration, isEnabled = GetSpellCooldown(spellID)
        startTime = tonumber(startTime) or 0
        duration = tonumber(duration) or 0
        if tonumber(isEnabled) == 0 then
            return 0
        end
        local remaining = (startTime + duration) - now
        return remaining > 0 and remaining or 0
    end

    return 0
end

function Module:GetConfig()
    Addon.db.macros = type(Addon.db.macros) == "table" and Addon.db.macros or {}
    local cfg = Addon.db.macros

    cfg.sectionState = type(cfg.sectionState) == "table" and cfg.sectionState or {}

    cfg.flask = type(cfg.flask) == "table" and cfg.flask or {}
    cfg.flask.enabled = cfg.flask.enabled ~= false
    cfg.flask.macroName = type(cfg.flask.macroName) == "string" and cfg.flask.macroName ~= "" and cfg.flask.macroName or "TNT: Flask"

    cfg.flask.roleDefaults = type(cfg.flask.roleDefaults) == "table" and cfg.flask.roleDefaults or {}
    cfg.flask.roleDefaults.TANK = NormalizeFlaskStat(cfg.flask.roleDefaults.TANK, "VERSATILITY")
    cfg.flask.roleDefaults.HEALER = NormalizeFlaskStat(cfg.flask.roleDefaults.HEALER, "MASTERY")
    cfg.flask.roleDefaults.MELEE = NormalizeFlaskStat(cfg.flask.roleDefaults.MELEE, "HASTE")
    cfg.flask.roleDefaults.RANGED = NormalizeFlaskStat(cfg.flask.roleDefaults.RANGED, "CRIT")

    cfg.flask.specOverrides = type(cfg.flask.specOverrides) == "table" and cfg.flask.specOverrides or {}

    cfg.healingPotion = type(cfg.healingPotion) == "table" and cfg.healingPotion or {}
    cfg.healingPotion.macroName = type(cfg.healingPotion.macroName) == "string" and cfg.healingPotion.macroName ~= "" and cfg.healingPotion.macroName or "TNT: Healing Potion"
    cfg.healingPotion.enabled = cfg.healingPotion.enabled ~= false
    cfg.healingPotion.useSoulburnForHealthstone = cfg.healingPotion.useSoulburnForHealthstone and true or false
    cfg.healingPotion.useRecuperateOutOfCombat = cfg.healingPotion.useRecuperateOutOfCombat and true or false
    cfg.healingPotion.enableHealthstones = cfg.healingPotion.enableHealthstones ~= false
    cfg.healingPotion.enableHealingPotions = cfg.healingPotion.enableHealingPotions ~= false
    cfg.healingPotion.addStopCast = cfg.healingPotion.addStopCast and true or false
    cfg.healingPotion.warlockSeparateMacros = cfg.healingPotion.warlockSeparateMacros and true or false
    cfg.healingPotion.warlockHealthstoneMacroName = type(cfg.healingPotion.warlockHealthstoneMacroName) == "string" and cfg.healingPotion.warlockHealthstoneMacroName ~= "" and cfg.healingPotion.warlockHealthstoneMacroName or "TNT: Healthstone"

    cfg.combatPotion = type(cfg.combatPotion) == "table" and cfg.combatPotion or {}
    cfg.combatPotion.macroName = type(cfg.combatPotion.macroName) == "string" and cfg.combatPotion.macroName ~= "" and cfg.combatPotion.macroName or "TNT: Combat Potion"
    cfg.combatPotion.enabled = cfg.combatPotion.enabled ~= false
    cfg.combatPotion.roleDefaults = type(cfg.combatPotion.roleDefaults) == "table" and cfg.combatPotion.roleDefaults or {}
    cfg.combatPotion.roleDefaults.TANK = NormalizeCombatPotionChoice(cfg.combatPotion.roleDefaults.TANK, "LIGHTS_POTENTIAL")
    cfg.combatPotion.roleDefaults.HEALER = NormalizeCombatPotionChoice(cfg.combatPotion.roleDefaults.HEALER, "LIGHTS_POTENTIAL")
    cfg.combatPotion.roleDefaults.MELEE = NormalizeCombatPotionChoice(cfg.combatPotion.roleDefaults.MELEE, "RECKLESSNESS")
    cfg.combatPotion.roleDefaults.RANGED = NormalizeCombatPotionChoice(cfg.combatPotion.roleDefaults.RANGED, "LIGHTS_POTENTIAL")
    cfg.combatPotion.specOverrides = type(cfg.combatPotion.specOverrides) == "table" and cfg.combatPotion.specOverrides or {}

    cfg.food = type(cfg.food) == "table" and cfg.food or {}
    cfg.food.macroName = type(cfg.food.macroName) == "string" and cfg.food.macroName ~= "" and cfg.food.macroName or "TNT: Food"

    cfg.drink = type(cfg.drink) == "table" and cfg.drink or {}
    cfg.drink.macroName = type(cfg.drink.macroName) == "string" and cfg.drink.macroName ~= "" and cfg.drink.macroName or "TNT: Drink"
    cfg.drink.enabled = cfg.drink.enabled ~= false
    cfg.drink.order = type(cfg.drink.order) == "table" and cfg.drink.order or {}
    do
        local normalized = {}
        for _, key in ipairs(cfg.drink.order) do
            if IsDrinkEntryKey(key) and not normalized[key] then
                normalized[key] = true
            end
        end
        for _, key in ipairs(DRINK_ENTRY_ORDER) do
            if not normalized[key] then
                cfg.drink.order[#cfg.drink.order + 1] = key
            end
        end
        local cleaned = {}
        local seen = {}
        for _, key in ipairs(cfg.drink.order) do
            if IsDrinkEntryKey(key) and not seen[key] then
                seen[key] = true
                cleaned[#cleaned + 1] = key
            end
        end
        cfg.drink.order = cleaned
    end

    return cfg
end

function Module:GetFlaskConfig()
    return self:GetConfig().flask
end

function Module:GetCombatPotionConfig()
    return self:GetConfig().combatPotion
end

function Module:GetHealingPotionConfig()
    return self:GetConfig().healingPotion
end

function Module:GetDrinkConfig()
    return self:GetConfig().drink
end

function Module:GetDrinkOrder()
    local drinkCfg = self:GetDrinkConfig()
    local out = {}
    for _, key in ipairs(drinkCfg.order) do
        out[#out + 1] = key
    end
    return out
end

function Module:GetDrinkLabelByKey(key)
    return DRINK_ENTRY_LABELS[key] or tostring(key)
end

function Module:GetRoleOptions()
    local items = {}
    for _, roleKey in ipairs(ROLE_ORDER) do
        items[#items + 1] = {
            value = roleKey,
            label = ROLE_LABELS[roleKey],
        }
    end
    return items
end

function Module:GetFlaskOptionItems(includeRoleDefault)
    local items = {}
    if includeRoleDefault then
        items[#items + 1] = { value = "ROLE_DEFAULT", label = "Role Default" }
    end

    for _, statKey in ipairs(FLASK_STAT_ORDER) do
        items[#items + 1] = {
            value = statKey,
            label = FLASK_STAT_LABELS[statKey],
        }
    end

    return items
end

function Module:GetCombatPotionOptionItems(includeRoleDefault)
    local items = {}
    if includeRoleDefault then
        items[#items + 1] = { value = "ROLE_DEFAULT", label = "Role Default" }
    end

    for _, potionKey in ipairs(COMBAT_POTION_ORDER) do
        items[#items + 1] = {
            value = potionKey,
            label = COMBAT_POTION_LABELS[potionKey],
        }
    end

    return items
end

local function IsPlayerWarlock()
    local _, classTag = UnitClass("player")
    return classTag == "WARLOCK"
end

local function GetHealthstonePriorityList()
    if IsPlayerWarlock() then
        return HEALTHSTONE_ITEM_PRIORITIES
    end

    return { HEALTHSTONE_ITEM_ID }
end

local function PlayerKnowsPactOfGluttony()
    if type(C_SpellBook.IsSpellKnown) ~= "function" then
        return false
    end
    return C_SpellBook.IsSpellKnown(PACT_OF_GLUTTONY_SPELL_ID) and true or false
end

local function GetWarlockHealthstoneItemID()
    if PlayerKnowsPactOfGluttony() then
        return DEMONIC_HEALTHSTONE_ITEM_ID
    end

    return HEALTHSTONE_ITEM_ID
end

local function PlayerKnowsSoulburn()
    if type(C_SpellBook.IsSpellKnown) ~= "function" then
        return false
    end
    return C_SpellBook.IsSpellKnown(SOULBURN_SPELL_ID) and true or false
end

local function PlayerKnowsSpell(spellID)
    if C_SpellBook and type(C_SpellBook.IsSpellInSpellBook) == "function" then
        return C_SpellBook.IsSpellInSpellBook(spellID) and true or false
    end

    if type(C_SpellBook.IsSpellKnown) == "function" then
        return C_SpellBook.IsSpellKnown(spellID) and true or false
    end

    return false
end

local function GetSpellDisplayName(spellID, fallbackName)
    if C_Spell and type(C_Spell.GetSpellName) == "function" then
        local name = C_Spell.GetSpellName(spellID)
        if type(name) == "string" and name ~= "" then
            return name
        end
    end

    local getSpellInfo = rawget(_G, "GetSpellInfo")
    if type(getSpellInfo) == "function" then
        local name = getSpellInfo(spellID)
        if type(name) == "string" and name ~= "" then
            return name
        end
    end

    return fallbackName or "Spell"
end

function Module:GetRoleCategoryForSpec(specID)
    local mapped = SPEC_ROLE_CATEGORY[tonumber(specID) or 0]
    if mapped then
        return mapped
    end

    local role = type(GetSpecializationRoleByID) == "function" and GetSpecializationRoleByID(specID) or nil
    if role == "TANK" then
        return "TANK"
    end
    if role == "HEALER" then
        return "HEALER"
    end

    return "MELEE"
end

function Module:GetSpecCatalog()
    local rows = {}
    if type(GetNumClasses) ~= "function" or type(GetClassInfo) ~= "function" then
        return rows
    end

    local classCount = tonumber(GetNumClasses()) or 0
    for classIndex = 1, classCount do
        local className, classFile, classID = GetClassInfo(classIndex)
        classID = tonumber(classID)
        if classID then
            local specCount = type(C_SpecializationInfo.GetNumSpecializationsForClassID) == "function" and tonumber(C_SpecializationInfo.GetNumSpecializationsForClassID(classID)) or 0
            for specIndex = 1, specCount do
                local specID, specName = GetSpecializationInfoForClassID(classID, specIndex)
                specID = tonumber(specID)
                if specID and type(specName) == "string" and specName ~= "" then
                    rows[#rows + 1] = {
                        classID = classID,
                        className = className or (classFile or tostring(classID)),
                        classFile = classFile,
                        specID = specID,
                        specName = specName,
                        roleCategory = self:GetRoleCategoryForSpec(specID),
                    }
                end
            end
        end
    end

    table.sort(rows, function(a, b)
        if a.className == b.className then
            return a.specID < b.specID
        end
        return a.className < b.className
    end)

    return rows
end

function Module:GetSpecGroups()
    local groups = {}
    local byClass = {}
    for _, row in ipairs(self:GetSpecCatalog()) do
        local key = tostring(row.className)
        if not byClass[key] then
            byClass[key] = {
                className = row.className,
                classID = row.classID,
                specs = {},
            }
            groups[#groups + 1] = byClass[key]
        end

        byClass[key].specs[#byClass[key].specs + 1] = row
    end

    table.sort(groups, function(a, b)
        return a.className < b.className
    end)

    return groups
end

function Module:GetPlayerClassAndSpec()
    local _, _, classID = UnitClass("player")
    classID = tonumber(classID)

    local specIndex = type(GetSpecialization) == "function" and GetSpecialization() or nil
    local specID
    if specIndex and type(GetSpecializationInfo) == "function" then
        specID = tonumber((GetSpecializationInfo(specIndex)))
    end

    return classID, specID
end

function Module:GetEffectiveFlaskStatForSpec(classID, specID)
    local flaskCfg = self:GetFlaskConfig()

    local specKey = BuildSpecStorageKey(classID, specID)
    local overrideValue = flaskCfg.specOverrides[specKey]
    if IsFlaskStat(overrideValue) then
        return overrideValue
    end

    local roleCategory = self:GetRoleCategoryForSpec(specID)
    return NormalizeFlaskStat(flaskCfg.roleDefaults[roleCategory], "VERSATILITY")
end

function Module:GetEffectiveFlaskStatForPlayer()
    local classID, specID = self:GetPlayerClassAndSpec()
    if not classID or not specID then
        local flaskCfg = self:GetFlaskConfig()
        return NormalizeFlaskStat(flaskCfg.roleDefaults.RANGED, "CRIT")
    end

    return self:GetEffectiveFlaskStatForSpec(classID, specID)
end

function Module:GetEffectiveCombatPotionChoiceForSpec(classID, specID)
    local combatCfg = self:GetCombatPotionConfig()
    local specKey = BuildSpecStorageKey(classID, specID)
    local overrideValue = combatCfg.specOverrides[specKey]
    if IsCombatPotionChoice(overrideValue) then
        return overrideValue
    end

    local roleCategory = self:GetRoleCategoryForSpec(specID)
    return NormalizeCombatPotionChoice(combatCfg.roleDefaults[roleCategory], "LIGHTS_POTENTIAL")
end

function Module:GetEffectiveCombatPotionChoiceForPlayer()
    local classID, specID = self:GetPlayerClassAndSpec()
    if not classID or not specID then
        local combatCfg = self:GetCombatPotionConfig()
        return NormalizeCombatPotionChoice(combatCfg.roleDefaults.RANGED, "LIGHTS_POTENTIAL")
    end

    return self:GetEffectiveCombatPotionChoiceForSpec(classID, specID)
end

function Module:GetSpecOverrideValue(classID, specID)
    local flaskCfg = self:GetFlaskConfig()
    local specKey = BuildSpecStorageKey(classID, specID)
    local value = flaskCfg.specOverrides[specKey]
    if IsFlaskStat(value) then
        return value
    end

    return "ROLE_DEFAULT"
end

function Module:GetCombatPotionSpecOverrideValue(classID, specID)
    local combatCfg = self:GetCombatPotionConfig()
    local specKey = BuildSpecStorageKey(classID, specID)
    local value = combatCfg.specOverrides[specKey]
    if IsCombatPotionChoice(value) then
        return value
    end

    return "ROLE_DEFAULT"
end

function Module:SetSpecOverrideValue(classID, specID, value)
    local flaskCfg = self:GetFlaskConfig()
    local specKey = BuildSpecStorageKey(classID, specID)

    if value == "ROLE_DEFAULT" or not IsFlaskStat(value) then
        flaskCfg.specOverrides[specKey] = nil
    else
        flaskCfg.specOverrides[specKey] = value
    end

    self:RequestFlaskMacroUpdate(false)
end

function Module:SetCombatPotionSpecOverrideValue(classID, specID, value)
    local combatCfg = self:GetCombatPotionConfig()
    local specKey = BuildSpecStorageKey(classID, specID)

    if value == "ROLE_DEFAULT" or not IsCombatPotionChoice(value) then
        combatCfg.specOverrides[specKey] = nil
    else
        combatCfg.specOverrides[specKey] = value
    end

    self:RequestCombatPotionMacroUpdate(false)
end

function Module:SetRoleDefault(roleKey, statKey)
    local flaskCfg = self:GetFlaskConfig()
    if not ROLE_LABELS[roleKey] then
        return
    end

    flaskCfg.roleDefaults[roleKey] = NormalizeFlaskStat(statKey, flaskCfg.roleDefaults[roleKey] or "VERSATILITY")
    self:RequestFlaskMacroUpdate(false)
end

function Module:SetCombatPotionRoleDefault(roleKey, choiceKey)
    local combatCfg = self:GetCombatPotionConfig()
    if not ROLE_LABELS[roleKey] then
        return
    end

    combatCfg.roleDefaults[roleKey] = NormalizeCombatPotionChoice(choiceKey, combatCfg.roleDefaults[roleKey] or "LIGHTS_POTENTIAL")
    self:RequestCombatPotionMacroUpdate(false)
end

function Module:IsMacroPresent(macroName)
    if type(GetMacroIndexByName) ~= "function" then
        return false
    end

    local index = tonumber(GetMacroIndexByName(macroName)) or 0
    return index > 0
end

function Module:GetMacroInfoByKey(macroKey)
    local cfg = self:GetConfig()

    if macroKey == "flask" then
        return cfg.flask.macroName, "Flask"
    end
    if macroKey == "healingPotion" then
        return cfg.healingPotion.macroName, "Healing Potion"
    end
    if macroKey == "warlockHealthstone" then
        return cfg.healingPotion.warlockHealthstoneMacroName, "Healthstone"
    end
    if macroKey == "combatPotion" then
        return cfg.combatPotion.macroName, "Combat Potion"
    end
    if macroKey == "food" then
        return cfg.food.macroName, "Food"
    end
    if macroKey == "drink" then
        return cfg.drink.macroName, "Drink"
    end

    return nil, nil
end

function Module:FindBestCombatPotionForChoice(choiceKey)
    if not IsCombatPotionChoice(choiceKey) then
        return nil
    end

    local preferredIDs = COMBAT_POTION_ITEM_PRIORITIES[choiceKey]
    if type(preferredIDs) ~= "table" then
        return nil
    end

    local availableByID = {}
    local maxBag = tonumber(rawget(_G, "NUM_BAG_SLOTS")) or 4
    for bagID = 0, maxBag do
        local slotCount = GetBagSlotCount(bagID)
        for slotID = 1, slotCount do
            local info = ResolveBagItemInfo(bagID, slotID)
            local itemID = info and tonumber(info.itemID)
            local stackCount = info and tonumber(info.stackCount) or 0
            if itemID and stackCount > 0 and not availableByID[itemID] then
                availableByID[itemID] = {
                    itemID = itemID,
                    itemName = C_Item.GetItemInfo(itemID),
                }
            end
        end
    end

    for priority, preferredID in ipairs(preferredIDs) do
        local found = availableByID[preferredID]
        if found then
            found.priority = #preferredIDs - priority + 1
            return found
        end
    end

    return nil
end

function Module:GetTopPriorityCombatPotionItemID(choiceKey)
    if not IsCombatPotionChoice(choiceKey) then
        return nil
    end

    local preferredIDs = COMBAT_POTION_ITEM_PRIORITIES[choiceKey]
    if type(preferredIDs) ~= "table" then
        return nil
    end

    return tonumber(preferredIDs[1])
end

function Module:GetAvailableItemsByID()
    local availableByID = {}
    local maxBag = tonumber(rawget(_G, "NUM_BAG_SLOTS")) or 4
    for bagID = 0, maxBag do
        local slotCount = GetBagSlotCount(bagID)
        for slotID = 1, slotCount do
            local info = ResolveBagItemInfo(bagID, slotID)
            local itemID = info and tonumber(info.itemID)
            local stackCount = info and tonumber(info.stackCount) or 0
            if itemID and stackCount > 0 and not availableByID[itemID] then
                availableByID[itemID] = {
                    itemID = itemID,
                    itemName = C_Item.GetItemInfo(itemID),
                    stackCount = stackCount,
                }
            end
        end
    end
    return availableByID
end

function Module:GetHealingPotionPriorityOrder(healingCfg)
    local order = {}

    local function AppendIDs(source)
        for _, itemID in ipairs(source) do
            order[#order + 1] = itemID
        end
    end

    if healingCfg.enableHealthstones ~= false then
        AppendIDs(GetHealthstonePriorityList())
    end
    if healingCfg.enableHealingPotions ~= false then
        AppendIDs(HEALING_POTION_ITEM_PRIORITIES)
    end

    return order
end

function Module:GetBestAvailableItemID(itemIDList, availableByID)
    for _, itemID in ipairs(itemIDList) do
        if availableByID[itemID] then
            return itemID
        end
    end

    return nil
end

function Module:GetTopPriorityHealingFallback(healingCfg)
    local priorityOrder = self:GetHealingPotionPriorityOrder(healingCfg)
    local fallbackItemID = tonumber(priorityOrder[1])
    if fallbackItemID then
        return {
            sourceType = "item",
            itemID = fallbackItemID,
            itemName = C_Item.GetItemInfo(fallbackItemID),
        }
    end

    return nil
end

function Module:SwapDrinkEntries(firstKey, secondKey)
    if not IsDrinkEntryKey(firstKey) or not IsDrinkEntryKey(secondKey) or firstKey == secondKey then
        return false
    end

    local drinkCfg = self:GetDrinkConfig()
    local firstIndex
    local secondIndex
    for idx, key in ipairs(drinkCfg.order) do
        if key == firstKey then
            firstIndex = idx
        elseif key == secondKey then
            secondIndex = idx
        end
    end

    if not firstIndex or not secondIndex then
        return false
    end

    drinkCfg.order[firstIndex], drinkCfg.order[secondIndex] = drinkCfg.order[secondIndex], drinkCfg.order[firstIndex]
    self:RequestDrinkMacroUpdate(false)
    return true
end

function Module:GetHealingCandidates(healingCfg)
    local candidates = {}

    local priorityOrder = self:GetHealingPotionPriorityOrder(healingCfg)
    local availableByID = self:GetAvailableItemsByID()
    for _, itemID in ipairs(priorityOrder) do
        local entry = availableByID[itemID]
        if entry then
            candidates[#candidates + 1] = {
                sourceType = "item",
                itemID = itemID,
                itemName = entry.itemName,
            }
        end
    end

    return candidates
end

function Module:MoveDrinkEntryToIndex(entryKey, targetIndex)
    if not IsDrinkEntryKey(entryKey) then
        return false
    end

    local drinkCfg = self:GetDrinkConfig()
    local count = #drinkCfg.order
    if count <= 1 then
        return false
    end

    local desiredIndex = tonumber(targetIndex)
    if not desiredIndex then
        return false
    end
    desiredIndex = math.floor(desiredIndex + 0.5)
    if desiredIndex < 1 then desiredIndex = 1 end
    if desiredIndex > count then desiredIndex = count end

    local currentIndex
    for idx, key in ipairs(drinkCfg.order) do
        if key == entryKey then
            currentIndex = idx
            break
        end
    end

    if not currentIndex or currentIndex == desiredIndex then
        return false
    end

    table.remove(drinkCfg.order, currentIndex)
    table.insert(drinkCfg.order, desiredIndex, entryKey)

    self:RequestDrinkMacroUpdate(false)
    return true
end

function Module:PickHealingItem()
    local healingCfg = self:GetHealingPotionConfig()
    local candidates = self:GetHealingCandidates(healingCfg)
    if #candidates == 0 then
        return nil, false
    end

    local fallback
    for _, candidate in ipairs(candidates) do
        if not fallback then
            fallback = candidate
        end

        local remaining = 0
        if candidate.sourceType == "spell" then
            remaining = GetSpellCooldownRemaining(candidate.spellID)
        else
            remaining = GetItemCooldownRemaining(candidate.itemID)
        end

        if remaining <= 0 then
            candidate.cooldownRemaining = 0
            return candidate, false
        end
    end

    if fallback then
        if fallback.sourceType == "spell" then
            fallback.cooldownRemaining = GetSpellCooldownRemaining(fallback.spellID)
        else
            fallback.cooldownRemaining = GetItemCooldownRemaining(fallback.itemID)
        end
        return fallback, true
    end

    return nil, false
end

function Module:GetMacroActionLabel(macroKey)
    local macroName = self:GetMacroInfoByKey(macroKey)
    if not macroName then
        return "Create Macro"
    end

    if self:IsMacroPresent(macroName) then
        return "Update Macro"
    end

    return "Create Macro"
end

function Module:EnsureGlobalMacro(macroName, bodyText)
    if type(GetMacroIndexByName) ~= "function" or type(CreateMacro) ~= "function" then
        return nil, "Macro API unavailable"
    end

    local idx = tonumber(GetMacroIndexByName(macroName)) or 0
    if idx > 0 then
        return idx
    end

    if type(GetNumMacros) == "function" then
        local globalCount = tonumber((GetNumMacros())) or 0
        if globalCount >= 120 then
            return nil, "Global macro limit reached (120)."
        end
    end

    local created = CreateMacro(macroName, DEFAULT_DYNAMIC_MACRO_ICON, bodyText or "#showtooltip", false)
    idx = tonumber(created) or tonumber(GetMacroIndexByName(macroName)) or 0
    if idx <= 0 then
        return nil, "Failed to create macro"
    end

    return idx
end

function Module:EditMacroByName(macroName, bodyText, createIfMissing)
    if type(EditMacro) ~= "function" or type(GetMacroIndexByName) ~= "function" then
        return false, "Macro API unavailable"
    end

    local idx = tonumber(GetMacroIndexByName(macroName)) or 0
    if idx <= 0 then
        if not createIfMissing then
            return false, "missing"
        end

        local createdIdx, createErr = self:EnsureGlobalMacro(macroName, bodyText)
        if not createdIdx then
            return false, createErr
        end
        idx = createdIdx
    end

    local ok = EditMacro(idx, macroName, DEFAULT_DYNAMIC_MACRO_ICON, bodyText)
    if ok == false then
        return false, "Failed to update macro"
    end

    return true
end

function Module:ResolveStatFromItemName(itemName)
    if type(itemName) ~= "string" or itemName == "" then
        return nil
    end

    local lowered = string.lower(itemName)
    if not FindKeyword(lowered, "flask") then
        return nil
    end

    if FindKeyword(lowered, "versatility") or FindKeyword(lowered, "vers") then
        return "VERSATILITY"
    end
    if FindKeyword(lowered, "mastery") then
        return "MASTERY"
    end
    if FindKeyword(lowered, "haste") then
        return "HASTE"
    end
    if FindKeyword(lowered, "critical") or FindKeyword(lowered, "crit") then
        return "CRIT"
    end

    return nil
end

function Module:ResolveStatFromItem(itemID, itemName)
    local id = tonumber(itemID)
    if id and FLASK_ITEM_TO_STAT[id] then
        return FLASK_ITEM_TO_STAT[id]
    end

    return self:ResolveStatFromItemName(itemName)
end

function Module:FindBestFlaskForStat(statKey)
    if not IsFlaskStat(statKey) then
        return nil
    end

    local preferredIDs = FLASK_ITEM_PRIORITIES[statKey]
    if type(preferredIDs) == "table" then
        local availableByID = {}
        local maxBag = tonumber(rawget(_G, "NUM_BAG_SLOTS")) or 4
        for bagID = 0, maxBag do
            local slotCount = GetBagSlotCount(bagID)
            for slotID = 1, slotCount do
                local info = ResolveBagItemInfo(bagID, slotID)
                local itemID = info and tonumber(info.itemID)
                local stackCount = info and tonumber(info.stackCount) or 0
                if itemID and stackCount > 0 and not availableByID[itemID] then
                    availableByID[itemID] = {
                        itemID = itemID,
                        itemName = C_Item.GetItemInfo(itemID),
                    }
                end
            end
        end

        for priority, preferredID in ipairs(preferredIDs) do
            local found = availableByID[preferredID]
            if found then
                found.priority = #preferredIDs - priority + 1
                return found
            end
        end
    end

    local best
    local maxBag = tonumber(rawget(_G, "NUM_BAG_SLOTS")) or 4

    for bagID = 0, maxBag do
        local slotCount = GetBagSlotCount(bagID)
        for slotID = 1, slotCount do
            local info = ResolveBagItemInfo(bagID, slotID)
            if info and info.itemID and (tonumber(info.stackCount) or 0) > 0 then
                local itemName = C_Item.GetItemInfo(info.itemID)
                local detectedStat = self:ResolveStatFromItem(info.itemID, itemName)
                if detectedStat == statKey then
                    local lowered = string.lower(itemName or "")
                    local isFleeting = FindKeyword(lowered, "fleeting")
                    local quality = tonumber(info.quality)
                    if not quality then
                        quality = tonumber(select(3, C_Item.GetItemInfo(info.itemID)))
                    end
                    local isRankTwo = (quality or 0) >= 2

                    local priority
                    if isFleeting and isRankTwo then
                        priority = 4
                    elseif isFleeting then
                        priority = 3
                    elseif isRankTwo then
                        priority = 2
                    else
                        priority = 1
                    end

                    local entry = {
                        itemID = info.itemID,
                        itemName = itemName,
                        isFleeting = isFleeting,
                        isRankTwo = isRankTwo,
                        priority = priority,
                    }

                    if not best or entry.priority > best.priority then
                        best = entry
                    end
                end
            end
        end
    end

    return best
end

function Module:GetTopPriorityFlaskItemID(statKey)
    if not IsFlaskStat(statKey) then
        return nil
    end

    local preferredIDs = FLASK_ITEM_PRIORITIES[statKey]
    if type(preferredIDs) ~= "table" then
        return nil
    end

    return tonumber(preferredIDs[1])
end

function Module:GetTopPriorityDrinkItemID()
    local drinkCfg = self:GetDrinkConfig()

    for _, entryKey in ipairs(drinkCfg.order) do
        local itemIDs = DRINK_ENTRY_ITEM_IDS[entryKey]
        if type(itemIDs) == "table" then
            local itemID = tonumber(itemIDs[1])
            if itemID then
                return itemID, entryKey
            end
        end
    end

    return nil, nil
end

function Module:BuildFlaskMacroText()
    local statKey = self:GetEffectiveFlaskStatForPlayer()
    local statLabel = FLASK_STAT_LABELS[statKey] or statKey
    local chosen = self:FindBestFlaskForStat(statKey)

    if chosen and chosen.itemID then
        local lines = {
            "#showtooltip item:" .. tostring(chosen.itemID),
            "/use item:" .. tostring(chosen.itemID),
        }
        return table.concat(lines, "\n"), chosen, statLabel
    end

    local fallbackItemID = self:GetTopPriorityFlaskItemID(statKey)
    if fallbackItemID then
        local lines = {
            "#showtooltip item:" .. tostring(fallbackItemID),
            "/use item:" .. tostring(fallbackItemID),
        }
        return table.concat(lines, "\n"), nil, statLabel
    end

    local lines = {
        "#showtooltip",
        "/run UIErrorsFrame:AddMessage(\"TNT Flask: No " .. statLabel .. " flask found in bags.\", 1, 0.2, 0.2, 1)",
    }

    return table.concat(lines, "\n"), nil, statLabel
end

function Module:GetFlaskMacroPreview()
    local macroBody, chosen, statLabel = self:BuildFlaskMacroText()
    return {
        macroBody = macroBody,
        chosenItemName = chosen and chosen.itemName or nil,
        chosenItemID = chosen and chosen.itemID or nil,
        selectedStatLabel = statLabel,
    }
end

function Module:BuildCombatPotionMacroText()
    local choiceKey = self:GetEffectiveCombatPotionChoiceForPlayer()
    local choiceLabel = COMBAT_POTION_LABELS[choiceKey] or tostring(choiceKey)
    local chosen = self:FindBestCombatPotionForChoice(choiceKey)

    if chosen and chosen.itemID then
        local lines = {
            "#showtooltip item:" .. tostring(chosen.itemID),
            "/use item:" .. tostring(chosen.itemID),
        }
        return table.concat(lines, "\n"), chosen, choiceLabel
    end

    local fallbackItemID = self:GetTopPriorityCombatPotionItemID(choiceKey)
    if fallbackItemID then
        local lines = {
            "#showtooltip item:" .. tostring(fallbackItemID),
            "/use item:" .. tostring(fallbackItemID),
        }
        return table.concat(lines, "\n"), nil, choiceLabel
    end

    local lines = {
        "#showtooltip",
        "/run UIErrorsFrame:AddMessage(\"TNT Combat Potion: No " .. choiceLabel .. " potion found in bags.\", 1, 0.2, 0.2, 1)",
    }

    return table.concat(lines, "\n"), nil, choiceLabel
end

function Module:GetCombatPotionMacroPreview()
    local macroBody, chosen, choiceLabel = self:BuildCombatPotionMacroText()
    return {
        macroBody = macroBody,
        chosenItemName = chosen and chosen.itemName or nil,
        chosenItemID = chosen and chosen.itemID or nil,
        selectedChoiceLabel = choiceLabel,
    }
end

function Module:GetRecuperateCastLine(healingCfg)
    if not healingCfg.useRecuperateOutOfCombat or not PlayerKnowsSpell(RECUPERATE_SPELL_ID) then
        return nil
    end

    local spellName = GetSpellDisplayName(RECUPERATE_SPELL_ID, "Recuperate")
    return "/cast [nocombat] " .. tostring(spellName)
end

function Module:BuildHealingCastSequenceMacroText(healingCfg, resetValue, healthstoneItemID, potionItemID)
    local lines = { "#showtooltip" }

    if healingCfg.addStopCast then
        lines[#lines + 1] = "/stopcasting"
    end

    local recuperateLine = self:GetRecuperateCastLine(healingCfg)
    if recuperateLine then
        lines[#lines + 1] = recuperateLine
    end

    lines[#lines + 1] = "/castsequence reset=" .. tostring(resetValue) .. " item:" .. tostring(healthstoneItemID) .. ", item:" .. tostring(potionItemID)

    local chosen = {
        sourceType = "castsequence",
        itemID = healthstoneItemID,
        secondItemID = potionItemID,
        itemName = C_Item.GetItemInfo(healthstoneItemID),
        secondItemName = C_Item.GetItemInfo(potionItemID),
    }

    return table.concat(lines, "\n"), chosen, false
end

function Module:BuildWarlockHealthstoneMacroText(healingCfg)
    local healthstoneItemID = GetWarlockHealthstoneItemID()
    local lines = { "#showtooltip" }

    if healingCfg.addStopCast then
        lines[#lines + 1] = "/stopcasting"
    end

    if healingCfg.useSoulburnForHealthstone and PlayerKnowsSoulburn() then
        lines[#lines + 1] = "/cast Soulburn"
    end

    lines[#lines + 1] = "/use item:" .. tostring(healthstoneItemID)

    local chosen = {
        sourceType = "item",
        itemID = healthstoneItemID,
        itemName = C_Item.GetItemInfo(healthstoneItemID),
    }

    return table.concat(lines, "\n"), chosen
end

function Module:BuildWarlockHealingPotionOnlyMacroText(healingCfg)
    local availableByID = self:GetAvailableItemsByID()
    local potionItemID = self:GetBestAvailableItemID(HEALING_POTION_ITEM_PRIORITIES, availableByID)

    local lines = { "#showtooltip" }

    if healingCfg.addStopCast then
        lines[#lines + 1] = "/stopcasting"
    end

    local recuperateLine = self:GetRecuperateCastLine(healingCfg)
    if recuperateLine then
        lines[#lines + 1] = recuperateLine
    end

    local chosen = nil
    if potionItemID then
        lines[#lines + 1] = "/use item:" .. tostring(potionItemID)
        chosen = {
            sourceType = "item",
            itemID = potionItemID,
            itemName = C_Item.GetItemInfo(potionItemID),
        }
    else
        lines[#lines + 1] = "/run UIErrorsFrame:AddMessage(\"TNT Healing: No healing potion found in bags.\", 1, 0.2, 0.2, 1)"
    end

    return table.concat(lines, "\n"), chosen, false
end

function Module:BuildHealingPotionMacroText()
    local healingCfg = self:GetHealingPotionConfig()

    if IsPlayerWarlock() then
        if healingCfg.warlockSeparateMacros then
            return self:BuildWarlockHealingPotionOnlyMacroText(healingCfg)
        end

        -- Combined mode: cast sequence using the talent-appropriate healthstone, only when both are on hand.
        if healingCfg.enableHealthstones ~= false and healingCfg.enableHealingPotions ~= false then
            local availableByID = self:GetAvailableItemsByID()
            local healthstoneItemID = GetWarlockHealthstoneItemID()
            local potionItemID = self:GetBestAvailableItemID(HEALING_POTION_ITEM_PRIORITIES, availableByID)

            if availableByID[healthstoneItemID] and potionItemID then
                local resetValue = PlayerKnowsPactOfGluttony() and "60" or "combat"
                return self:BuildHealingCastSequenceMacroText(healingCfg, resetValue, healthstoneItemID, potionItemID)
            end
        end
    elseif healingCfg.enableHealthstones ~= false and healingCfg.enableHealingPotions ~= false then
        -- Both types enabled and both on hand: use a cast sequence so the macro never needs an in-combat edit.
        local availableByID = self:GetAvailableItemsByID()
        local healthstoneItemID = self:GetBestAvailableItemID(GetHealthstonePriorityList(), availableByID)
        local potionItemID = self:GetBestAvailableItemID(HEALING_POTION_ITEM_PRIORITIES, availableByID)

        if healthstoneItemID and potionItemID then
            return self:BuildHealingCastSequenceMacroText(healingCfg, "combat", healthstoneItemID, potionItemID)
        end
    end

    local chosen, allOnCooldown = self:PickHealingItem()
    local fallback = nil
    if not chosen then
        fallback = self:GetTopPriorityHealingFallback(healingCfg)
        chosen = fallback
    end

    local lines = { "#showtooltip" }

    if healingCfg.addStopCast then
        lines[#lines + 1] = "/stopcasting"
    end

    local recuperateLine = self:GetRecuperateCastLine(healingCfg)
    if recuperateLine then
        lines[#lines + 1] = recuperateLine
    end

    if chosen and chosen.itemID then
        lines[#lines + 1] = "/use item:" .. tostring(chosen.itemID)
    else
        lines[#lines + 1] = "/run UIErrorsFrame:AddMessage(\"TNT Healing: No enabled healing items found in bags.\", 1, 0.2, 0.2, 1)"
    end

    return table.concat(lines, "\n"), chosen, allOnCooldown
end

function Module:GetWarlockHealthstoneMacroPreview()
    local healingCfg = self:GetHealingPotionConfig()
    local macroBody, chosen = self:BuildWarlockHealthstoneMacroText(healingCfg)
    return {
        macroBody = macroBody,
        chosenItemName = chosen and chosen.itemName or nil,
        chosenItemID = chosen and chosen.itemID or nil,
    }
end

function Module:GetHealingPotionMacroPreview()
    local macroBody, chosen, allOnCooldown = self:BuildHealingPotionMacroText()
    local selectedName = nil
    if chosen then
        if chosen.sourceType == "castsequence" then
            selectedName = string.format("%s -> %s (cast sequence)", chosen.itemName or "Healthstone", chosen.secondItemName or "Healing Potion")
        else
            selectedName = chosen.itemName
        end
    end

    return {
        macroBody = macroBody,
        chosenItemName = selectedName,
        chosenItemID = chosen and chosen.itemID or nil,
        allOnCooldown = allOnCooldown and true or false,
    }
end

function Module:PickDrinkItem()
    local drinkCfg = self:GetDrinkConfig()
    local availableByID = self:GetAvailableItemsByID()

    for _, entryKey in ipairs(drinkCfg.order) do
        local itemIDs = DRINK_ENTRY_ITEM_IDS[entryKey]
        if type(itemIDs) == "table" then
            for _, itemID in ipairs(itemIDs) do
                local found = availableByID[itemID]
                if found then
                    return found, entryKey
                end
            end
        end
    end

    return nil, nil
end

function Module:BuildDrinkMacroText()
    local chosen, entryKey = self:PickDrinkItem()

    if chosen and chosen.itemID then
        local lines = {
            "#showtooltip item:" .. tostring(chosen.itemID),
            "/use item:" .. tostring(chosen.itemID),
        }
        return table.concat(lines, "\n"), chosen, entryKey
    end

    local fallbackItemID, fallbackEntryKey = self:GetTopPriorityDrinkItemID()
    if fallbackItemID then
        local lines = {
            "#showtooltip item:" .. tostring(fallbackItemID),
            "/use item:" .. tostring(fallbackItemID),
        }
        return table.concat(lines, "\n"), nil, fallbackEntryKey
    end

    local lines = {
        "#showtooltip",
        "/run UIErrorsFrame:AddMessage(\"TNT Drink: No preferred drink item found in bags.\", 1, 0.2, 0.2, 1)",
    }
    return table.concat(lines, "\n"), nil, nil
end

function Module:GetDrinkMacroPreview()
    local macroBody, chosen, entryKey = self:BuildDrinkMacroText()
    return {
        macroBody = macroBody,
        chosenItemName = chosen and chosen.itemName or nil,
        chosenItemID = chosen and chosen.itemID or nil,
        selectedEntryLabel = entryKey and self:GetDrinkLabelByKey(entryKey) or nil,
    }
end

function Module:StopHealingCooldownTicker()
    if self.healingCooldownTicker and type(self.healingCooldownTicker.Cancel) == "function" then
        self.healingCooldownTicker:Cancel()
    end
    self.healingCooldownTicker = nil
end

function Module:StartHealingCooldownTicker()
    if self.healingCooldownTicker then
        return
    end

    if C_Timer and type(C_Timer.NewTicker) == "function" then
        self.healingCooldownTicker = C_Timer.NewTicker(10, function()
            Module:RequestHealingPotionMacroUpdate(false)
        end)
    end
end

function Module:UpdateFlaskMacro(createIfMissing)
    local flaskCfg = self:GetFlaskConfig()
    if flaskCfg.enabled == false then
        return false, "disabled"
    end

    if InCombatLockdown and InCombatLockdown() then
        self.pendingFlaskUpdate = true
        self.pendingFlaskCreate = self.pendingFlaskCreate or (createIfMissing and true or false)
        return false, "in_combat"
    end

    local macroBody = self:BuildFlaskMacroText()
    local ok, err = self:EditMacroByName(flaskCfg.macroName, macroBody, createIfMissing)
    if not ok and err == "missing" then
        return false, "missing"
    end

    if not ok then
        Addon:Print("Flask macro update failed: " .. tostring(err))
        return false, err
    end

    return true
end

function Module:UpdateCombatPotionMacro(createIfMissing)
    local combatCfg = self:GetCombatPotionConfig()
    if combatCfg.enabled == false then
        return false, "disabled"
    end

    if InCombatLockdown and InCombatLockdown() then
        self.pendingCombatPotionUpdate = true
        self.pendingCombatPotionCreate = self.pendingCombatPotionCreate or (createIfMissing and true or false)
        return false, "in_combat"
    end

    local macroBody = self:BuildCombatPotionMacroText()
    local ok, err = self:EditMacroByName(combatCfg.macroName, macroBody, createIfMissing)
    if not ok and err == "missing" then
        return false, "missing"
    end

    if not ok then
        Addon:Print("Combat potion macro update failed: " .. tostring(err))
        return false, err
    end

    return true
end

function Module:UpdateHealingPotionMacro(createIfMissing)
    local healingCfg = self:GetHealingPotionConfig()
    if healingCfg.enabled == false then
        self:StopHealingCooldownTicker()
        return false, "disabled"
    end

    if InCombatLockdown and InCombatLockdown() then
        self.pendingHealingPotionUpdate = true
        self.pendingHealingPotionCreate = self.pendingHealingPotionCreate or (createIfMissing and true or false)
        return false, "in_combat"
    end

    local macroBody, _, allOnCooldown = self:BuildHealingPotionMacroText()
    local ok, err = self:EditMacroByName(healingCfg.macroName, macroBody, createIfMissing)
    if not ok and err == "missing" then
        return false, "missing"
    end

    if not ok then
        Addon:Print("Healing potion macro update failed: " .. tostring(err))
        return false, err
    end

    if allOnCooldown then
        self:StartHealingCooldownTicker()
    else
        self:StopHealingCooldownTicker()
    end

    return true
end

function Module:UpdateWarlockHealthstoneMacro(createIfMissing)
    local healingCfg = self:GetHealingPotionConfig()
    if healingCfg.enabled == false or not healingCfg.warlockSeparateMacros or not IsPlayerWarlock() then
        return false, "disabled"
    end

    if InCombatLockdown and InCombatLockdown() then
        self.pendingWarlockHealthstoneUpdate = true
        self.pendingWarlockHealthstoneCreate = self.pendingWarlockHealthstoneCreate or (createIfMissing and true or false)
        return false, "in_combat"
    end

    local macroBody = self:BuildWarlockHealthstoneMacroText(healingCfg)
    local ok, err = self:EditMacroByName(healingCfg.warlockHealthstoneMacroName, macroBody, createIfMissing)
    if not ok and err == "missing" then
        return false, "missing"
    end

    if not ok then
        Addon:Print("Healthstone macro update failed: " .. tostring(err))
        return false, err
    end

    return true
end

function Module:UpdateDrinkMacro(createIfMissing)
    local drinkCfg = self:GetDrinkConfig()
    if drinkCfg.enabled == false then
        return false, "disabled"
    end

    if InCombatLockdown and InCombatLockdown() then
        self.pendingDrinkUpdate = true
        self.pendingDrinkCreate = self.pendingDrinkCreate or (createIfMissing and true or false)
        return false, "in_combat"
    end

    local macroBody = self:BuildDrinkMacroText()
    local ok, err = self:EditMacroByName(drinkCfg.macroName, macroBody, createIfMissing)
    if not ok and err == "missing" then
        return false, "missing"
    end

    if not ok then
        Addon:Print("Drink macro update failed: " .. tostring(err))
        return false, err
    end

    return true
end

function Module:RequestFlaskMacroUpdate(createIfMissing)
    local flaskCfg = self:GetFlaskConfig()
    if flaskCfg.enabled == false then
        return false, "disabled"
    end

    self.pendingFlaskUpdate = true
    self.pendingFlaskCreate = self.pendingFlaskCreate or (createIfMissing and true or false)

    if InCombatLockdown and InCombatLockdown() then
        return false, "in_combat"
    end

    return self:FlushPendingUpdates()
end

function Module:RequestCombatPotionMacroUpdate(createIfMissing)
    local combatCfg = self:GetCombatPotionConfig()
    if combatCfg.enabled == false then
        return false, "disabled"
    end

    self.pendingCombatPotionUpdate = true
    self.pendingCombatPotionCreate = self.pendingCombatPotionCreate or (createIfMissing and true or false)

    if InCombatLockdown and InCombatLockdown() then
        return false, "in_combat"
    end

    return self:FlushPendingUpdates()
end

function Module:RequestHealingPotionMacroUpdate(createIfMissing)
    local healingCfg = self:GetHealingPotionConfig()
    if healingCfg.enabled == false then
        self:StopHealingCooldownTicker()
        return false, "disabled"
    end

    self.pendingHealingPotionUpdate = true
    self.pendingHealingPotionCreate = self.pendingHealingPotionCreate or (createIfMissing and true or false)

    if IsPlayerWarlock() and healingCfg.warlockSeparateMacros then
        self.pendingWarlockHealthstoneUpdate = true
        self.pendingWarlockHealthstoneCreate = self.pendingWarlockHealthstoneCreate or (createIfMissing and true or false)
    end

    return self:FlushPendingUpdates()
end

function Module:RequestDrinkMacroUpdate(createIfMissing)
    local drinkCfg = self:GetDrinkConfig()
    if drinkCfg.enabled == false then
        return false, "disabled"
    end

    self.pendingDrinkUpdate = true
    self.pendingDrinkCreate = self.pendingDrinkCreate or (createIfMissing and true or false)

    if InCombatLockdown and InCombatLockdown() then
        return false, "in_combat"
    end

    return self:FlushPendingUpdates()
end

function Module:FlushPendingFlaskUpdate()
    if not self.pendingFlaskUpdate then
        return true
    end

    local createIfMissing = self.pendingFlaskCreate and true or false
    self.pendingFlaskUpdate = false
    self.pendingFlaskCreate = false

    local ok, err = self:UpdateFlaskMacro(createIfMissing)
    if not ok and err == "in_combat" then
        self.pendingFlaskUpdate = true
        self.pendingFlaskCreate = self.pendingFlaskCreate or createIfMissing
    end

    return ok, err
end

function Module:FlushPendingCombatPotionUpdate()
    if not self.pendingCombatPotionUpdate then
        return true
    end

    local createIfMissing = self.pendingCombatPotionCreate and true or false
    self.pendingCombatPotionUpdate = false
    self.pendingCombatPotionCreate = false

    local ok, err = self:UpdateCombatPotionMacro(createIfMissing)
    if not ok and err == "in_combat" then
        self.pendingCombatPotionUpdate = true
        self.pendingCombatPotionCreate = self.pendingCombatPotionCreate or createIfMissing
    end

    return ok, err
end

function Module:FlushPendingHealingPotionUpdate()
    if not self.pendingHealingPotionUpdate then
        return true
    end

    local createIfMissing = self.pendingHealingPotionCreate and true or false
    self.pendingHealingPotionUpdate = false
    self.pendingHealingPotionCreate = false

    local ok, err = self:UpdateHealingPotionMacro(createIfMissing)
    if not ok and err == "in_combat" then
        self.pendingHealingPotionUpdate = true
        self.pendingHealingPotionCreate = self.pendingHealingPotionCreate or createIfMissing
    end

    return ok, err
end

function Module:FlushPendingWarlockHealthstoneUpdate()
    if not self.pendingWarlockHealthstoneUpdate then
        return true
    end

    local createIfMissing = self.pendingWarlockHealthstoneCreate and true or false
    self.pendingWarlockHealthstoneUpdate = false
    self.pendingWarlockHealthstoneCreate = false

    local ok, err = self:UpdateWarlockHealthstoneMacro(createIfMissing)
    if not ok and err == "in_combat" then
        self.pendingWarlockHealthstoneUpdate = true
        self.pendingWarlockHealthstoneCreate = self.pendingWarlockHealthstoneCreate or createIfMissing
    end

    return ok, err
end

function Module:FlushPendingDrinkUpdate()
    if not self.pendingDrinkUpdate then
        return true
    end

    local createIfMissing = self.pendingDrinkCreate and true or false
    self.pendingDrinkUpdate = false
    self.pendingDrinkCreate = false

    local ok, err = self:UpdateDrinkMacro(createIfMissing)
    if not ok and err == "in_combat" then
        self.pendingDrinkUpdate = true
        self.pendingDrinkCreate = self.pendingDrinkCreate or createIfMissing
    end

    return ok, err
end

function Module:FlushPendingUpdates()
    local okFlask = true
    local errFlask
    local okCombat = true
    local errCombat
    local okHealing = true
    local errHealing
    local okWarlockHealthstone = true
    local errWarlockHealthstone
    local okDrink = true
    local errDrink

    okFlask, errFlask = self:FlushPendingFlaskUpdate()
    okCombat, errCombat = self:FlushPendingCombatPotionUpdate()
    okHealing, errHealing = self:FlushPendingHealingPotionUpdate()
    okWarlockHealthstone, errWarlockHealthstone = self:FlushPendingWarlockHealthstoneUpdate()
    okDrink, errDrink = self:FlushPendingDrinkUpdate()

    if not okFlask then
        return false, errFlask
    end

    if not okCombat then
        return false, errCombat
    end

    if not okHealing then
        return false, errHealing
    end

    if not okWarlockHealthstone then
        return false, errWarlockHealthstone
    end

    if not okDrink then
        return false, errDrink
    end

    return true
end

function Module:SetFlaskEnabled(enabled)
    local flaskCfg = self:GetFlaskConfig()
    flaskCfg.enabled = enabled and true or false

    if flaskCfg.enabled then
        self:RequestFlaskMacroUpdate(true)
    end
end

function Module:SetCombatPotionEnabled(enabled)
    local combatCfg = self:GetCombatPotionConfig()
    combatCfg.enabled = enabled and true or false

    if combatCfg.enabled then
        self:RequestCombatPotionMacroUpdate(true)
    end
end

function Module:SetHealingPotionEnabled(enabled)
    local healingCfg = self:GetHealingPotionConfig()
    healingCfg.enabled = enabled and true or false

    if healingCfg.enabled then
        self:RequestHealingPotionMacroUpdate(true)
        return
    end

    self:StopHealingCooldownTicker()
end

function Module:SetHealingUseSoulburn(value)
    local healingCfg = self:GetHealingPotionConfig()
    healingCfg.useSoulburnForHealthstone = value and true or false
    self:RequestHealingPotionMacroUpdate(false)
end

function Module:SetHealingUseRecuperateOutOfCombat(value)
    local healingCfg = self:GetHealingPotionConfig()
    healingCfg.useRecuperateOutOfCombat = value and true or false
    self:RequestHealingPotionMacroUpdate(false)
end

function Module:SetHealingEnableHealthstones(value)
    local healingCfg = self:GetHealingPotionConfig()
    healingCfg.enableHealthstones = value and true or false
    self:RequestHealingPotionMacroUpdate(false)
end

function Module:SetHealingEnablePotions(value)
    local healingCfg = self:GetHealingPotionConfig()
    healingCfg.enableHealingPotions = value and true or false
    self:RequestHealingPotionMacroUpdate(false)
end

function Module:SetHealingAddStopCast(value)
    local healingCfg = self:GetHealingPotionConfig()
    healingCfg.addStopCast = value and true or false
    self:RequestHealingPotionMacroUpdate(false)
end

function Module:SetWarlockSeparateMacros(value)
    local healingCfg = self:GetHealingPotionConfig()
    healingCfg.warlockSeparateMacros = value and true or false
    self:RequestHealingPotionMacroUpdate(true)
end

function Module:SetDrinkEnabled(enabled)
    local drinkCfg = self:GetDrinkConfig()
    drinkCfg.enabled = enabled and true or false

    if drinkCfg.enabled then
        self:RequestDrinkMacroUpdate(true)
    end
end

function Module:CreateOrUpdateSimpleMacro(macroKey)
    local macroName, macroLabel = self:GetMacroInfoByKey(macroKey)
    if not macroName then
        return false
    end

    local body = table.concat({
        "#showtooltip",
        "/run print(\"Thisnthat QoL: " .. macroLabel .. " macro placeholder.\")",
    }, "\n")

    if InCombatLockdown and InCombatLockdown() then
        Addon:Print("Cannot create or edit macros during combat.")
        return false
    end

    local ok, err = self:EditMacroByName(macroName, body, true)
    if not ok then
        Addon:Print("Macro update failed: " .. tostring(err))
        return false
    end

    return true
end

function Module:HandleEvent(event, ...)
    if event == "BAG_UPDATE_DELAYED" then
        self:RequestFlaskMacroUpdate(false)
        self:RequestCombatPotionMacroUpdate(false)
        self:RequestHealingPotionMacroUpdate(false)
        self:RequestDrinkMacroUpdate(false)
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unitToken = ...
        if unitToken == "player" then
            self:RequestFlaskMacroUpdate(false)
            self:RequestCombatPotionMacroUpdate(false)
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitToken = ...
        if unitToken == "player" then
            self:RequestFlaskMacroUpdate(false)
            self:RequestCombatPotionMacroUpdate(false)
            self:RequestHealingPotionMacroUpdate(false)
            self:RequestDrinkMacroUpdate(false)
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:RequestHealingPotionMacroUpdate(false)
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:RequestHealingPotionMacroUpdate(false)
        self:FlushPendingUpdates()    
    elseif event == "PLAYER_LEAVE_COMBAT" or event == "PLAYER_ENTER_COMBAT" then
        self:RequestHealingPotionMacroUpdate(false)
        self:FlushPendingUpdates()    
    end
end

function Module:OnInitialize(hostAddon)
    self.hostAddon = hostAddon
    self:GetConfig()
end

function Module:OnEnable()
    local cfg = self:GetConfig()

    if not self.frame then
        self.frame = CreateFrame("Frame")
        self.frame:SetScript("OnEvent", function(_, event, ...)
            Module:HandleEvent(event, ...)
        end)
    end

    self.frame:RegisterEvent("BAG_UPDATE_DELAYED")
    self.frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self.frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.frame:RegisterEvent("PLAYER_ENTER_COMBAT")
    self.frame:RegisterEvent("PLAYER_LEAVE_COMBAT")

    if cfg and cfg.flask and cfg.flask.enabled ~= false then
        self:RequestFlaskMacroUpdate(true)
    end

    if cfg and cfg.combatPotion and cfg.combatPotion.enabled ~= false then
        self:RequestCombatPotionMacroUpdate(true)
    end

    if cfg and cfg.healingPotion and cfg.healingPotion.enabled ~= false then
        self:RequestHealingPotionMacroUpdate(true)
    end

    if cfg and cfg.drink and cfg.drink.enabled ~= false then
        self:RequestDrinkMacroUpdate(true)
    end
end
