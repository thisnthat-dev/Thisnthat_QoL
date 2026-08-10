local _, ns = ...

local Addon = ns.Addon
local Module = {
    frame = nil,
    eventFrame = nil,
    iconFrames = {},
}

Addon:RegisterModule("Consumables", Module)

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local VALID_POINTS = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true,
}

local VALID_GROW = {
    LEFT = true,
    RIGHT = true,
    UP = true,
    DOWN = true,
    CENTER_HORIZONTAL = true,
    CENTER_VERTICAL = true,
}

local VALID_ALERT_COUNT_SOURCE = {
    TOTAL = true,
    HIGHEST_QUALITY = true,
}

local ALERT_BORDER_COLOR = { r = 1, g = 0.16, b = 0.16, a = 1 }
local NORMAL_BORDER_COLOR = { r = 0.18, g = 0.24, b = 0.30, a = 0.55 }
local ICON_BACKGROUND_COLOR = { r = 0.06, g = 0.06, b = 0.06, a = 0.92 }
local BATTLE_RES_SPELL_IDS = {
    20484,  -- Rebirth
    61999,  -- Raise Ally
    20707,  -- Soulstone
    391054, -- Intercession
}

local HEALTH_POTION_ITEMS = {
    [1] = { id = 271884, name = "Concentrated Silvermoon Health Potion", rank = 2, min_patch = 120100 },
    [2] = { id = 271883, name = "Concentrated Silvermoon Health Potion", rank = 1, min_patch = 120100 },
    [3] = { id = 241304, name = "Silvermoon Health Potion", rank = 2, min_patch = 120000 },
    [4] = { id = 241305, name = "Silvermoon Health Potion", rank = 1, min_patch = 120000 },
}

local COMBAT_POTION_TYPES = {
    Lights_Potential = 1,
    Recklessness = 2,
}

local COMBAT_POTION_TYPE_ORDER = {
    "lights_potential",
    "recklessness",
}

local COMBAT_POTION_TYPE_LABELS = {
    lights_potential = "Light's Potential",
    recklessness = "Recklessness",
}

local COMBAT_POTION_ITEMS = {
    [1] = {
        { id = 245898, name = "Fleeting Light's Potential", rank = 2, min_patch = 120000 },
        { id = 245897, name = "Fleeting Light's Potential", rank = 1, min_patch = 120000 },
        { id = 241308, name = "Light's Potential", rank = 2, min_patch = 120000 },
        { id = 241309, name = "Light's Potential", rank = 1, min_patch = 120000 },
    },
    [2] = {
        { id = 245902, name = "Fleeting Recklessness", rank = 2, min_patch = 120000 },
        { id = 245903, name = "Fleeting Recklessness", rank = 1, min_patch = 120000 },
        { id = 241288, name = "Recklessness", rank = 2, min_patch = 120000 },
        { id = 241289, name = "Recklessness", rank = 1, min_patch = 120000 },
    },
}

local FLASK_TYPES = {
    crit = 1,
    haste = 2,
    mastery = 3,
    versatility = 4,
}

local FLASK_TYPE_ORDER = {
    "crit",
    "haste",
    "mastery",
    "versatility",
}

local FLASK_TYPE_LABELS = {
    crit = "Crit",
    haste = "Haste",
    mastery = "Mastery",
    versatility = "Versatility",
}

local FLASK_ITEMS = {
    [FLASK_TYPES.crit] = {
        { id = 245929, name = "Fleeting Shattered Sun", rank = 2, min_patch = 120000 },
        { id = 245928, name = "Fleeting Shattered Sun", rank = 1, min_patch = 120000 },
        { id = 241326, name = "Shattered Sun", rank = 2, min_patch = 120000 },
        { id = 241327, name = "Shattered Sun", rank = 1, min_patch = 120000 },
    },
    [FLASK_TYPES.haste] = {
        { id = 245931, name = "Fleeting Blood Knights", rank = 2, min_patch = 120000 },
        { id = 245932, name = "Fleeting Blood Knights", rank = 1, min_patch = 120000 },
        { id = 241324, name = "Blood Knights", rank = 2, min_patch = 120000 },
        { id = 241325, name = "Blood Knights", rank = 1, min_patch = 120000 },
    },
    [FLASK_TYPES.mastery] = {
        { id = 245933, name = "Fleeting Magisters", rank = 2, min_patch = 120000 },
        { id = 245932, name = "Fleeting Magisters", rank = 1, min_patch = 120000 },
        { id = 241322, name = "Magisters", rank = 2, min_patch = 120000 },
        { id = 241323, name = "Magisters", rank = 1, min_patch = 120000 },
    },
    [FLASK_TYPES.versatility] = {
        { id = 245926, name = "Fleeting Thalassian Resistance", rank = 2, min_patch = 120000 },
        { id = 245927, name = "Fleeting Thalassian Resistance", rank = 1, min_patch = 120000 },
        { id = 241320, name = "Thalassian Resistance", rank = 2, min_patch = 120000 },
        { id = 241321, name = "Thalassian Resistance", rank = 1, min_patch = 120000 },
    },
}

local OILS = {
    [1] = { id = 243734, name = "Thalassian Phoenix Oil", rank = 2, min_patch = 120000 },
    [2] = { id = 243733, name = "Thalassian Phoenix Oil", rank = 1, min_patch = 120000 },
}

local FOOD = {
    [1] = { id = 242747, name = "Hearty Royal Roast", rank = 1, min_patch = 120000 },
    [2] = { id = 268679, name = "Hearty Impossible Royal Roast", rank = 1, min_patch = 120000 },
}

local FEASTS = {
    [1] = { id = 266996, name = "Hearty Harandar Celebration", rank = 2, min_patch = 120000 },
    [2] = { id = 266995, name = "Hearty Silvermoon Parade", rank = 1, min_patch = 120000 },
}

local BATTLE_RES = {
    [1] = { id = 269586, name = "Emergency Soul Link", rank = 2, min_patch = 120000 },
    [2] = { id = 248486, name = "Emergency Soul Link", rank = 1, min_patch = 120000 },
}

local CATEGORY_ORDER = {
    "healthPotion",
    "combatPotion",
    "flask",
    "oil",
    "food",
    "feast",
    "battleRes",
}

local CATEGORY_LABELS = {
    healthPotion = "Health Potion",
    combatPotion = "Combat Potion",
    flask = "Flask",
    oil = "Oil",
    food = "Food",
    feast = "Feast",
    battleRes = "Battle Res",
}

local CATEGORY_TRACKING_DEFAULTS = {
    healthPotion = true,
    combatPotion = true,
    flask = true,
    oil = true,
    food = true,
    feast = true,
    battleRes = true,
}

local patchCache = 0

local function Clamp(value, minValue, maxValue, fallback)
    local numberValue = tonumber(value)
    if not numberValue then
        return fallback
    end
    if numberValue < minValue then
        return minValue
    end
    if numberValue > maxValue then
        return maxValue
    end
    return numberValue
end

local function Trim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function NormalizePoint(value, fallback)
    if type(value) ~= "string" then
        return fallback
    end

    local upper = string.upper(value)
    if VALID_POINTS[upper] then
        return upper
    end

    return fallback
end

local function NormalizeGrow(value, fallback)
    if type(value) ~= "string" then
        return fallback
    end

    local upper = string.upper(value)
    if VALID_GROW[upper] then
        return upper
    end

    return fallback
end

local function NormalizeAlertCountSource(value, fallback)
    if type(value) ~= "string" then
        return fallback
    end

    local upper = string.upper(value)
    if VALID_ALERT_COUNT_SOURCE[upper] then
        return upper
    end

    return fallback
end

local function NormalizeFlaskType(value, fallback)
    if type(value) == "number" then
        for key, typeID in pairs(FLASK_TYPES) do
            if typeID == value then
                return key
            end
        end
    end

    if type(value) == "string" then
        local normalized = string.lower(value)
        if FLASK_TYPES[normalized] then
            return normalized
        end
    end

    return fallback
end

local function NormalizeCombatPotionType(value, fallback)
    if type(value) == "number" then
        for key, typeID in pairs(COMBAT_POTION_TYPES) do
            if typeID == value then
                return string.lower(key)
            end
        end
    end

    if type(value) == "string" then
        local normalized = string.lower(value)
        if normalized == "lights_potential" or normalized == "lights potential" then
            return "lights_potential"
        end
        if normalized == "recklessness" then
            return "recklessness"
        end
    end

    return fallback
end

local function IsCategoryKey(value)
    return CATEGORY_LABELS[value] ~= nil
end

local function IsFoodOrFeast(sectionKey)
    return sectionKey == "food" or sectionKey == "feast"
end

local function ShouldSkipBattleResIcon(cfg, sectionKey, hasBattleResSpell)
    return sectionKey == "battleRes" and cfg.battleRes and cfg.battleRes.disableIfClassHasSpell and hasBattleResSpell
end

local function GetPatch()
    if patchCache == 0 then
        patchCache = select(4, GetBuildInfo()) or 0
    end
    return patchCache
end

local function GetItemCountSafe(itemID)
    if C_Item and type(C_Item.GetItemCount) == "function" then
        return tonumber(C_Item.GetItemCount(itemID, false, false, false)) or 0
    end

    local getItemCount = rawget(_G, "GetItemCount")
    if type(getItemCount) == "function" then
        return tonumber(getItemCount(itemID, false, false, false)) or 0
    end

    return 0
end

local function GetItemQualityAtlas(quality)
    local tier = tonumber(quality) or 1
    if tier < 1 then
        tier = 1
    end
    return "Professions-Icon-Quality-12-Tier" .. tostring(tier) .. "-small"
end

local function GetIconTexture(itemID)
    if C_Item and type(C_Item.GetItemIconByID) == "function" then
        local icon = C_Item.GetItemIconByID(itemID)
        if type(icon) == "string" and icon ~= "" then
            return icon
        end
        if type(icon) == "number" and icon > 0 then
            return icon
        end
    end

    local getItemInfoInstant = rawget(_G, "GetItemInfoInstant")
    if type(getItemInfoInstant) == "function" then
        local _, _, _, _, icon = getItemInfoInstant(itemID)
        if type(icon) == "string" and icon ~= "" then
            return icon
        end
        if type(icon) == "number" and icon > 0 then
            return icon
        end
    end

    local getItemInfo = rawget(_G, "GetItemInfo")
    if type(getItemInfo) == "function" then
        local _, _, _, _, icon = getItemInfo(itemID)
        if type(icon) == "string" and icon ~= "" then
            return icon
        end
        if type(icon) == "number" and icon > 0 then
            return icon
        end
    end

    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetSpecID()
    local specIndex = type(GetSpecialization) == "function" and GetSpecialization() or nil
    if not specIndex then
        return nil
    end

    if type(GetSpecializationInfo) ~= "function" then
        return nil
    end

    return tonumber((GetSpecializationInfo(specIndex)))
end

local function GetDataFromItems(items)
    local itemID = 0
    local itemCount = 0
    local total = 0
    local patch = GetPatch()

    for i = 1, #items do
        local item = items[i]
        if item and item.min_patch <= patch then
            local count = GetItemCountSafe(item.id)
            if count > 0 then
                if itemID == 0 then
                    itemID = item.id
                    itemCount = count
                end
                total = total + count
            end
        end
    end

    if itemID == 0 then
        for i = 1, #items do
            local item = items[i]
            if item.min_patch <= patch then
                return item.id, 0, 0
            end
        end
    end

    return itemID, itemCount, total
end

local function GetQualityForItem(itemID)
    if not itemID then
        return 1
    end

    if C_TradeSkillUI and type(C_TradeSkillUI.GetItemReagentQualityByItemInfo) == "function" then
        return C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemID) or 1
    end

    return 1
end

function Module:GetConfig()
    Addon.db.Consumables = type(Addon.db.Consumables) == "table" and Addon.db.Consumables or {}
    local cfg = Addon.db.Consumables

    cfg.enabled = cfg.enabled ~= false
    cfg.hideInCombat = cfg.hideInCombat and true or false
    cfg.hideInEncounter = cfg.hideInEncounter and true or false
    cfg.customAnchor = cfg.customAnchor and true or false
    cfg.anchorPanel = type(cfg.anchorPanel) == "string" and Trim(cfg.anchorPanel) or "UIParent"
    if cfg.anchorPanel == "" then
        cfg.anchorPanel = "UIParent"
    end
    if not cfg.customAnchor then
        cfg.anchorPanel = "UIParent"
    end
    cfg.point = NormalizePoint(cfg.point, "CENTER")
    cfg.relativePoint = NormalizePoint(cfg.relativePoint, "CENTER")
    cfg.x = Clamp(cfg.x, -4000, 4000, 0)
    cfg.y = Clamp(cfg.y, -4000, 4000, 0)
    cfg.font = type(cfg.font) == "string" and cfg.font or nil
    cfg.fontSize = Clamp(cfg.fontSize, 6, 64, 12)
    cfg.fontOutline = type(cfg.fontOutline) == "string" and string.upper(cfg.fontOutline) or "NONE"
    if cfg.fontOutline ~= "NONE" and cfg.fontOutline ~= "OUTLINE" and cfg.fontOutline ~= "THICKOUTLINE" and cfg.fontOutline ~= "MONOCHROME" then
        cfg.fontOutline = "NONE"
    end
    cfg.grow = NormalizeGrow(cfg.grow, "RIGHT")
    cfg.iconWidth = Clamp(cfg.iconWidth, 16, 128, 36)
    cfg.iconHeight = Clamp(cfg.iconHeight, 16, 128, 36)
    cfg.iconGap = Clamp(cfg.iconGap, 0, 32, 4)
    cfg.qualitySize = Clamp(cfg.qualitySize, 8, 48, 28)
    cfg.battleRes = type(cfg.battleRes) == "table" and cfg.battleRes or {}
    cfg.battleRes.disableIfClassHasSpell = cfg.battleRes.disableIfClassHasSpell and true or false
    cfg.tracking = type(cfg.tracking) == "table" and cfg.tracking or {}
    for key, defaultValue in pairs(CATEGORY_TRACKING_DEFAULTS) do
        if cfg.tracking[key] == nil then
            cfg.tracking[key] = defaultValue
        else
            cfg.tracking[key] = cfg.tracking[key] and true or false
        end
    end

    cfg.flask = type(cfg.flask) == "table" and cfg.flask or {}
    cfg.flask.defaultType = NormalizeFlaskType(cfg.flask.defaultType, "crit")
    cfg.flask.specOverrides = type(cfg.flask.specOverrides) == "table" and cfg.flask.specOverrides or {}

    for specID, value in pairs(cfg.flask.specOverrides) do
        local normalized = NormalizeFlaskType(value, "default")
        if normalized == "default" then
            cfg.flask.specOverrides[specID] = nil
        else
            cfg.flask.specOverrides[specID] = normalized
        end
    end

    cfg.combatPotion = type(cfg.combatPotion) == "table" and cfg.combatPotion or {}
    cfg.combatPotion.defaultType = NormalizeCombatPotionType(cfg.combatPotion.defaultType, "lights_potential")
    cfg.combatPotion.specOverrides = type(cfg.combatPotion.specOverrides) == "table" and cfg.combatPotion.specOverrides or {}

    for specID, value in pairs(cfg.combatPotion.specOverrides) do
        local normalized = NormalizeCombatPotionType(value, "default")
        if normalized == "default" then
            cfg.combatPotion.specOverrides[specID] = nil
        else
            cfg.combatPotion.specOverrides[specID] = normalized
        end
    end

    cfg.alerts = type(cfg.alerts) == "table" and cfg.alerts or {}

    for _, sectionKey in ipairs(CATEGORY_ORDER) do
        cfg.alerts[sectionKey] = type(cfg.alerts[sectionKey]) == "table" and cfg.alerts[sectionKey] or {}
        local alert = cfg.alerts[sectionKey]

        if alert.enabled == nil then
            alert.enabled = true
        else
            alert.enabled = alert.enabled and true or false
        end
        alert.minCount = Clamp(alert.minCount, 0, 100000, 5)
        alert.countSource = NormalizeAlertCountSource(alert.countSource, "TOTAL")
        if IsFoodOrFeast(sectionKey) then
            alert.countSource = "TOTAL"
        end
    end

    return cfg
end

local function IsPlayerInCombat()
    local inCombatLockdown = rawget(_G, "InCombatLockdown")
    if type(inCombatLockdown) == "function" then
        return inCombatLockdown() and true or false
    end

    local unitAffectingCombat = rawget(_G, "UnitAffectingCombat")
    if type(unitAffectingCombat) == "function" then
        return unitAffectingCombat("player") and true or false
    end

    return false
end

local function IsEncounterActive()
    local isEncounterInProgress = rawget(_G, "IsEncounterInProgress")
    if type(isEncounterInProgress) == "function" then
        return isEncounterInProgress() and true or false
    end

    return false
end

function Module:ShouldShowFrame()
    local cfg = self:GetConfig()
    if cfg.enabled == false then
        return false
    end

    if cfg.hideInEncounter and (self.inEncounter or IsEncounterActive()) then
        return false
    end

    if cfg.hideInCombat and IsPlayerInCombat() then
        return false
    end

    return true
end

function Module:GetAlertConfig(sectionKey)
    if not IsCategoryKey(sectionKey) then
        return nil
    end

    local cfg = self:GetConfig()
    return cfg.alerts[sectionKey]
end

function Module:ApplyBorderState(iconFrame, isAlert)
    if not iconFrame then
        return
    end

    iconFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    iconFrame:SetBackdropColor(ICON_BACKGROUND_COLOR.r, ICON_BACKGROUND_COLOR.g, ICON_BACKGROUND_COLOR.b, ICON_BACKGROUND_COLOR.a)

    iconFrame:SetBackdropBorderColor(NORMAL_BORDER_COLOR.r, NORMAL_BORDER_COLOR.g, NORMAL_BORDER_COLOR.b, NORMAL_BORDER_COLOR.a)
    if iconFrame.alertBorder then
        iconFrame.alertBorder:SetShown(isAlert and true or false)
    end
end

function Module:PlayerHasBattleResSpell()
    local isPlayerSpell = rawget(_G, "IsPlayerSpell")
    if type(isPlayerSpell) ~= "function" then
        return false
    end

    for i = 1, #BATTLE_RES_SPELL_IDS do
        if isPlayerSpell(BATTLE_RES_SPELL_IDS[i]) then
            return true
        end
    end

    return false
end

function Module:ShouldAlert(entry)
    if type(entry) ~= "table" or not IsCategoryKey(entry.key) then
        return false
    end

    local alertCfg = self:GetAlertConfig(entry.key)
    if not alertCfg or alertCfg.enabled == false then
        return false
    end

    local sourceValue = (alertCfg.countSource == "HIGHEST_QUALITY") and (entry.itemCount or 0) or (entry.total or 0)
    return tonumber(sourceValue) < tonumber(alertCfg.minCount or 0)
end

function Module:ApplyGlow(iconFrame, entry)
    if not iconFrame then
        return
    end

    self:ApplyBorderState(iconFrame, self:ShouldAlert(entry))
end

function Module:GetCombatPotionOptionItems(includeDefault)
    local items = {}

    if includeDefault then
        items[#items + 1] = {
            value = "default",
            label = "Default",
        }
    end

    for _, key in ipairs(COMBAT_POTION_TYPE_ORDER) do
        items[#items + 1] = {
            value = key,
            label = COMBAT_POTION_TYPE_LABELS[key] or key,
        }
    end

    return items
end

function Module:GetDefaultCombatPotionType()
    local cfg = self:GetConfig()
    return NormalizeCombatPotionType(cfg.combatPotion.defaultType, "lights_potential")
end

function Module:SetDefaultCombatPotionType(value)
    local cfg = self:GetConfig()
    cfg.combatPotion.defaultType = NormalizeCombatPotionType(value, cfg.combatPotion.defaultType or "lights_potential")
    self:Refresh()
end

function Module:GetSpecCombatPotionOverride(specID)
    local cfg = self:GetConfig()
    local key = tostring(tonumber(specID) or 0)
    local value = NormalizeCombatPotionType(cfg.combatPotion.specOverrides[key], "default")
    if value == "default" then
        return "default"
    end
    return value
end

function Module:SetSpecCombatPotionOverride(specID, value)
    local cfg = self:GetConfig()
    local key = tostring(tonumber(specID) or 0)
    local normalized = NormalizeCombatPotionType(value, "default")

    if normalized == "default" then
        cfg.combatPotion.specOverrides[key] = nil
    else
        cfg.combatPotion.specOverrides[key] = normalized
    end

    self:Refresh()
end

function Module:GetFlaskOptionItems(includeDefault)
    local items = {}

    if includeDefault then
        items[#items + 1] = {
            value = "default",
            label = "Default",
        }
    end

    for _, key in ipairs(FLASK_TYPE_ORDER) do
        items[#items + 1] = {
            value = key,
            label = FLASK_TYPE_LABELS[key] or key,
        }
    end

    return items
end

function Module:GetDefaultFlaskType()
    local cfg = self:GetConfig()
    return NormalizeFlaskType(cfg.flask.defaultType, "crit")
end

function Module:SetDefaultFlaskType(value)
    local cfg = self:GetConfig()
    cfg.flask.defaultType = NormalizeFlaskType(value, cfg.flask.defaultType or "crit")
    self:Refresh()
end

function Module:GetSpecFlaskOverride(specID)
    local cfg = self:GetConfig()
    local key = tostring(tonumber(specID) or 0)
    local value = NormalizeFlaskType(cfg.flask.specOverrides[key], "default")
    if value == "default" then
        return "default"
    end
    return value
end

function Module:SetSpecFlaskOverride(specID, value)
    local cfg = self:GetConfig()
    local key = tostring(tonumber(specID) or 0)
    local normalized = NormalizeFlaskType(value, "default")

    if normalized == "default" then
        cfg.flask.specOverrides[key] = nil
    else
        cfg.flask.specOverrides[key] = normalized
    end

    self:Refresh()
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
        if classID and type(GetSpecializationInfoForClassID) == "function" then
            local specCount = type(C_SpecializationInfo.GetNumSpecializationsForClassID) == "function" and tonumber(C_SpecializationInfo.GetNumSpecializationsForClassID(classID)) or 0
            for specIndex = 1, specCount do
                local specID, specName = GetSpecializationInfoForClassID(classID, specIndex)
                specID = tonumber(specID)
                if specID and type(specName) == "string" and specName ~= "" then
                    rows[#rows + 1] = {
                        classID = classID,
                        className = className or classFile or tostring(classID),
                        classFile = classFile,
                        specID = specID,
                        specName = specName,
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
        local classKey = tostring(row.classID or row.className)
        if not byClass[classKey] then
            byClass[classKey] = {
                classID = row.classID,
                className = row.className,
                specs = {},
            }
            groups[#groups + 1] = byClass[classKey]
        end

        byClass[classKey].specs[#byClass[classKey].specs + 1] = row
    end

    table.sort(groups, function(a, b)
        return (a.className or "") < (b.className or "")
    end)

    return groups
end

function Module:GetHealthPotionItems()
    return HEALTH_POTION_ITEMS
end

function Module:GetCombatPotionItems()
    local specID = GetSpecID()
    local cfg = self:GetConfig()
    local defaultTypeKey = NormalizeCombatPotionType(cfg.combatPotion.defaultType, "lights_potential")
    local specKey = tostring(specID or 0)
    local overrideTypeKey = NormalizeCombatPotionType(cfg.combatPotion.specOverrides[specKey], defaultTypeKey)
    local typeToken = overrideTypeKey == "recklessness" and "Recklessness" or "Lights_Potential"
    local potionTypeID = COMBAT_POTION_TYPES[typeToken] or COMBAT_POTION_TYPES.Lights_Potential
    return COMBAT_POTION_ITEMS[potionTypeID]
end

function Module:GetFlaskItems()
    local specID = GetSpecID()
    local cfg = self:GetConfig()
    local defaultTypeKey = NormalizeFlaskType(cfg.flask.defaultType, "crit")
    local specKey = tostring(specID or 0)
    local overrideTypeKey = NormalizeFlaskType(cfg.flask.specOverrides[specKey], defaultTypeKey)
    local flaskTypeID = FLASK_TYPES[overrideTypeKey] or FLASK_TYPES[defaultTypeKey] or FLASK_TYPES.crit
    return FLASK_ITEMS[flaskTypeID]
end

function Module:GetOilItems()
    return OILS
end

function Module:GetFoodItems()
    return FOOD
end

function Module:GetFeastItems()
    return FEASTS
end

function Module:GetBattleResItems()
    return BATTLE_RES
end

function Module:GetCategoryCallbacks()
    return {
        healthPotion = function() return self:GetHealthPotionItems() end,
        combatPotion = function() return self:GetCombatPotionItems() end,
        flask = function() return self:GetFlaskItems() end,
        oil = function() return self:GetOilItems() end,
        food = function() return self:GetFoodItems() end,
        feast = function() return self:GetFeastItems() end,
        battleRes = function() return self:GetBattleResItems() end,
    }
end

function Module:GetCategoryEntries()
    local callbacks = self:GetCategoryCallbacks()
    local cfg = self:GetConfig()
    local entries = {}
    local skipBattleRes = cfg.battleRes and cfg.battleRes.disableIfClassHasSpell and self:PlayerHasBattleResSpell()

    for _, key in ipairs(CATEGORY_ORDER) do
        if cfg.tracking[key] ~= false then
            if not ShouldSkipBattleResIcon(cfg, key, skipBattleRes) then
                local callback = callbacks[key]
                local items = type(callback) == "function" and callback() or nil
                local itemID, itemCount, total = GetDataFromItems(items or {})
                local quality
                if not IsFoodOrFeast(key) then
                    quality = GetQualityForItem(itemID)
                end

                entries[#entries + 1] = {
                    key = key,
                    label = CATEGORY_LABELS[key],
                    itemID = itemID,
                    itemCount = itemCount,
                    total = total,
                    icon = GetIconTexture(itemID),
                    quality = quality,
                    enabled = true,
                }
            end
        end
    end

    return entries
end

function Module:CreateFrame()
    if self.frame then
        return self.frame
    end

    local uiParent = rawget(_G, "UIParent")
    if not uiParent then
        return nil
    end

    local frame = CreateFrame("Frame", "ThisnthatQOL_ConsumablesFrame", uiParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(false)
    frame:EnableMouse(false)

    self.frame = frame
    self.iconFrames = {}

    for index = 1, #CATEGORY_ORDER do
        local iconFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        self:ApplyBorderState(iconFrame, false)

        local icon = iconFrame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local count = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        count:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMLEFT", 2, 1)
        count:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 1)
        count:SetJustifyH("CENTER")
        count:SetWordWrap(false)
        count:SetTextColor(1, 1, 1, 0.96)

        local quality = iconFrame:CreateTexture(nil, "OVERLAY")
        quality:SetSize(12, 12)
        quality:SetPoint("TOPRIGHT", iconFrame, "TOPRIGHT", 6, 6)

        local alertBorder = CreateFrame("Frame", nil, iconFrame, "BackdropTemplate")
        alertBorder:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 0, 0)
        alertBorder:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 0, 0)
        alertBorder:SetFrameLevel(iconFrame:GetFrameLevel() + 6)
        alertBorder:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        alertBorder:SetBackdropBorderColor(ALERT_BORDER_COLOR.r, ALERT_BORDER_COLOR.g, ALERT_BORDER_COLOR.b, ALERT_BORDER_COLOR.a)
        alertBorder:Hide()

        iconFrame:SetScript("OnEnter", function(self)
            if not self.itemID or not GameTooltip then
                return
            end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if type(GameTooltip.SetItemByID) == "function" then
                GameTooltip:SetItemByID(self.itemID)
            else
                local getItemInfo = rawget(_G, "GetItemInfo")
                if type(getItemInfo) == "function" then
                    local itemName, itemLink = getItemInfo(self.itemID)
                    if itemLink then
                        GameTooltip:SetHyperlink(itemLink)
                    elseif itemName then
                        GameTooltip:AddLine(itemName)
                    end
                end
            end
            GameTooltip:Show()
        end)

        iconFrame:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)

        iconFrame.icon = icon
        iconFrame.count = count
        iconFrame.quality = quality
        iconFrame.alertBorder = alertBorder
        iconFrame.index = index
        self.iconFrames[index] = iconFrame
    end

    return frame
end

function Module:UpdateStyle()
    if not self.frame then
        return
    end

    local cfg = self:GetConfig()
    local fontPath = rawget(_G, "STANDARD_TEXT_FONT") or "Fonts\\FRIZQT__.TTF"
    if cfg.font and LSM and type(LSM.Fetch) == "function" then
        fontPath = LSM:Fetch("font", cfg.font, true) or fontPath
    end

    local qualitySize = Clamp(cfg.qualitySize, 8, 48, 12)
    for _, iconFrame in ipairs(self.iconFrames) do
        if iconFrame and iconFrame.count then
            iconFrame.count:SetFont(fontPath, cfg.fontSize, cfg.fontOutline ~= "NONE" and cfg.fontOutline or "")
            if iconFrame.quality then
                local s = Clamp(qualitySize, 8, 48, 12)
                iconFrame.quality:SetSize(s, s)
            end
        end
    end
end

function Module:ApplyLayout()
    if not self.frame then
        return
    end

    local entries = self:GetCategoryEntries()
    local cfg = self:GetConfig()
    local iconWidth = cfg.iconWidth or 36
    local iconHeight = cfg.iconHeight or 36
    local gap = cfg.iconGap or 4
    local stepX = iconWidth + gap
    local verticalStep = iconHeight + gap
    local count = #entries
    local centerOffset = (count - 1) / 2

    for index, iconFrame in ipairs(self.iconFrames) do
        local entry = entries[index]
        if entry then
            iconFrame:Show()
            iconFrame:SetSize(iconWidth, iconHeight)
            iconFrame.itemID = entry.itemID
            iconFrame.icon:SetTexture(entry.icon)
            iconFrame.count:SetText(string.format("%d/%d", entry.itemCount or 0, entry.total or 0))
            if entry.quality then
                iconFrame.quality:SetAtlas(GetItemQualityAtlas(entry.quality))
                iconFrame.quality:Show()
            else
                iconFrame.quality:Hide()
            end
            self:ApplyGlow(iconFrame, entry)
        else
            iconFrame:Hide()
            iconFrame.itemID = nil
            self:ApplyBorderState(iconFrame, false)
        end
    end

    for index, iconFrame in ipairs(self.iconFrames) do
        iconFrame:ClearAllPoints()
    end

    self.frame:SetSize(math.max(1, iconWidth), math.max(1, iconHeight))

    if cfg.grow == "LEFT" then
        for index, iconFrame in ipairs(self.iconFrames) do
            if index == 1 then
                iconFrame:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
            else
                iconFrame:SetPoint("RIGHT", self.iconFrames[index - 1], "LEFT", -gap, 0)
            end
        end
    elseif cfg.grow == "RIGHT" then
        for index, iconFrame in ipairs(self.iconFrames) do
            if index == 1 then
                iconFrame:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
            else
                iconFrame:SetPoint("LEFT", self.iconFrames[index - 1], "RIGHT", gap, 0)
            end
        end
    elseif cfg.grow == "UP" then
        for index, iconFrame in ipairs(self.iconFrames) do
            if index == 1 then
                iconFrame:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
            else
                iconFrame:SetPoint("BOTTOM", self.iconFrames[index - 1], "TOP", 0, gap)
            end
        end
    elseif cfg.grow == "DOWN" then
        for index, iconFrame in ipairs(self.iconFrames) do
            if index == 1 then
                iconFrame:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
            else
                iconFrame:SetPoint("TOP", self.iconFrames[index - 1], "BOTTOM", 0, -gap)
            end
        end
    elseif cfg.grow == "CENTER_VERTICAL" then
        for index, iconFrame in ipairs(self.iconFrames) do
            local offsetY = (index - 1 - centerOffset) * verticalStep
            iconFrame:SetPoint("CENTER", self.frame, "CENTER", 0, offsetY)
        end
    elseif cfg.grow == "CENTER_HORIZONTAL" then
        for index, iconFrame in ipairs(self.iconFrames) do
            local offsetX = (index - 1 - centerOffset) * stepX
            iconFrame:SetPoint("CENTER", self.frame, "CENTER", offsetX, 0)
        end
    end

    self:UpdateStyle()
end

function Module:ApplyAnchor()
    if not self.frame then
        return
    end

    local cfg = self:GetConfig()
    local anchor = UIParent
    if cfg.customAnchor then
        local anchorObject = rawget(_G, cfg.anchorPanel or "")
        if anchorObject and type(anchorObject.GetObjectType) == "function" then
            anchor = anchorObject
        end
    end

    self.frame:ClearAllPoints()
    self.frame:SetPoint(cfg.point or "CENTER", anchor, cfg.relativePoint or "CENTER", cfg.x or 0, cfg.y or 0)
end

function Module:Refresh()
    local frame = self:CreateFrame()
    if not frame then
        return
    end

    self:ApplyLayout()
    self:ApplyAnchor()
    frame:SetShown(self:ShouldShowFrame())
end

function Module:HandleEvent(event, ...)
    if event == "ENCOUNTER_START" then
        self.inEncounter = true
    elseif event == "ENCOUNTER_END" then
        self.inEncounter = false
    elseif event == "PLAYER_ENTERING_WORLD" then
        self.inEncounter = IsEncounterActive()
    end

    if event == "PLAYER_ENTERING_WORLD"
        or event == "PLAYER_SPECIALIZATION_CHANGED"
        or event == "BAG_UPDATE"
        or event == "PLAYER_REGEN_DISABLED"
        or event == "PLAYER_REGEN_ENABLED"
        or event == "ENCOUNTER_START"
        or event == "ENCOUNTER_END" then
        self:Refresh()
    end
end

function Module:OnInitialize()
    self:GetConfig()
    self.inEncounter = IsEncounterActive()
    self:CreateFrame()
end

function Module:OnEnable()
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:SetScript("OnEvent", function(_, event, ...)
            self:HandleEvent(event)
        end)
    end

    self.eventFrame:RegisterEvent("BAG_UPDATE")
    self.eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.eventFrame:RegisterEvent("ENCOUNTER_START")
    self.eventFrame:RegisterEvent("ENCOUNTER_END")

    self:Refresh()
end
