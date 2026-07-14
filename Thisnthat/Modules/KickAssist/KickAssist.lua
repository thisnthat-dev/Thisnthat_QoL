local _, ns = ...

local Addon = ns.Addon
local Module = {
    eventFrame = nil,
}

Addon:RegisterModule("KickAssist", Module)

local CLASS_INTERRUPT_SPELL = {
    DEATHKNIGHT = "Mind Freeze",
    DEMONHUNTER = "Disrupt",
    DRUID = "Skull Bash",
    EVOKER = "Quell",
    HUNTER = "Counter Shot",
    MAGE = "Counterspell",
    MONK = "Spear Hand Strike",
    PALADIN = "Rebuke",
    PRIEST = "Silence",
    ROGUE = "Kick",
    SHAMAN = "Wind Shear",
    WARLOCK = "Spell Lock",
    WARRIOR = "Pummel",
}

local INTERRUPT_SPELL_CHOICES = {
    "Axe Toss",
    "Counter Shot",
    "Counterspell",
    "Disrupt",
    "Kick",
    "Mind Freeze",
    "Pummel",
    "Quell",
    "Rebuke",
    "Silence",
    "Skull Bash",
    "Spear Hand Strike",
    "Spell Lock",
    "Wind Shear",
}

local RAID_MARKERS = {
    { index = 1, name = "Star" },
    { index = 2, name = "Circle" },
    { index = 3, name = "Diamond" },
    { index = 4, name = "Triangle" },
    { index = 5, name = "Moon" },
    { index = 6, name = "Square" },
    { index = 7, name = "Cross" },
    { index = 8, name = "Skull" },
}

local KICK_MACRO_NAME = "TNT: Kick Macro"
local FOCUS_MACRO_NAME = "TNT: Focus Macro"
local FOCUS_MACRO_ICON = 132212

local function ClampMarkerIndex(index)
    local marker = tonumber(index)
    if not marker then
        return 4
    end

    marker = math.floor(marker + 0.5)
    if marker < 1 then
        marker = 1
    elseif marker > 8 then
        marker = 8
    end

    return marker
end

function Module:GetConfig()
    Addon.db.KickAssist = type(Addon.db.KickAssist) == "table" and Addon.db.KickAssist or {}
    local cfg = Addon.db.KickAssist

    cfg.markerIndex = ClampMarkerIndex(cfg.markerIndex)
    cfg.interruptSpell = type(cfg.interruptSpell) == "string" and cfg.interruptSpell or "AUTO"
    if cfg.interruptSpell == "" then
        cfg.interruptSpell = "AUTO"
    end
    cfg.announceOnReadyCheck = cfg.announceOnReadyCheck and true or false
    cfg.announceTemplate = type(cfg.announceTemplate) == "string" and cfg.announceTemplate or "My Kick target is {RAIDMARKER}"
    cfg.announceInMythicPlus = cfg.announceInMythicPlus and true or false
    cfg.announceInMythicDungeon = cfg.announceInMythicDungeon and true or false
    cfg.announceInHeroicDungeon = cfg.announceInHeroicDungeon and true or false
    cfg.announceInNormalDungeon = cfg.announceInNormalDungeon and true or false

    return cfg
end

function Module:GetRaidMarkers()
    return RAID_MARKERS
end

function Module:GetSelectedMarker()
    local cfg = self:GetConfig()
    local index = ClampMarkerIndex(cfg.markerIndex)
    local marker = RAID_MARKERS[index]
    if marker then
        return marker
    end

    return RAID_MARKERS[4]
end

function Module:GetMarkerTextureTag(index, size)
    local markerIndex = ClampMarkerIndex(index)
    local iconSize = tonumber(size) or 14
    return string.format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:%d:%d:0:0|t", markerIndex, iconSize, iconSize)
end

function Module:GetMarkerChatTag(index)
    return "{rt" .. tostring(ClampMarkerIndex(index)) .. "}"
end

function Module:GetInterruptSpellName()
    local cfg = self:GetConfig()
    if cfg.interruptSpell and cfg.interruptSpell ~= "AUTO" and cfg.interruptSpell ~= "" then
        return cfg.interruptSpell
    end

    local _, classToken = UnitClass("player")
    local spellName = CLASS_INTERRUPT_SPELL[classToken or ""]

    if not spellName or spellName == "" then
        return "Interrupt"
    end

    return spellName
end

function Module:GetInterruptSpellChoices()
    local choices = {
        { value = "AUTO", label = "Auto (Class Default)" },
    }

    for _, spellName in ipairs(INTERRUPT_SPELL_CHOICES) do
        choices[#choices + 1] = {
            value = spellName,
            label = spellName,
        }
    end

    return choices
end

function Module:BuildKickMacro()
    local interruptSpell = self:GetInterruptSpellName()
    return table.concat({
        "#showtooltip " .. interruptSpell,
        "/cast [@focus,exists,harm,nodead] " .. interruptSpell .. "; [@target,harm] " .. interruptSpell .. "; [@targettarget,harm] " .. interruptSpell,
    }, "\n")
end

function Module:BuildFocusMacro(markerIndex)
    local index = ClampMarkerIndex(markerIndex or self:GetConfig().markerIndex)
    return table.concat({
        "/focus [@mouseover, exists][]",
        "/tm [@mouseover, exists][] ~" .. tostring(index),
    }, "\n")
end

local function UpsertMacro(name, icon, body, isCharacterSpecific)
    if type(CreateMacro) ~= "function" then
        return false, "Macro API unavailable"
    end

    local index = type(GetMacroIndexByName) == "function" and GetMacroIndexByName(name) or 0
    local perCharacterFlag = isCharacterSpecific and 1 or 0

    if index and index > 0 and type(EditMacro) == "function" then
        local ok = pcall(EditMacro, index, name, icon, body, perCharacterFlag, 1)
        if ok then
            return true
        end
        return false, "Failed to update macro"
    end

    local ok, createdIndex = pcall(CreateMacro, name, icon, body, isCharacterSpecific and true or false, true)
    if ok and createdIndex then
        return true
    end

    return false, "Failed to create macro"
end

function Module:CreateKickMacro()
    local spellName = self:GetInterruptSpellName()
    local getSpellTexture = rawget(_G, "GetSpellTexture")
    local icon = nil
    if type(getSpellTexture) == "function" then
        icon = getSpellTexture(spellName)
    end
    if icon == nil and C_Spell and type(C_Spell.GetSpellTexture) == "function" then
        icon = C_Spell.GetSpellTexture(spellName)
    end
    icon = icon or "INV_MISC_QUESTIONMARK"
    local ok, err = UpsertMacro(KICK_MACRO_NAME, icon, self:BuildKickMacro(), true)
    if ok then
        Addon:Print("Created/updated character macro '" .. KICK_MACRO_NAME .. "'.")
        return true
    end

    Addon:Print("Could not create/update '" .. KICK_MACRO_NAME .. "': " .. tostring(err))
    return false
end

function Module:CreateFocusMacro()
    local ok, err = UpsertMacro(FOCUS_MACRO_NAME, FOCUS_MACRO_ICON, self:BuildFocusMacro(), false)
    if ok then
        Addon:Print("Created/updated account macro '" .. FOCUS_MACRO_NAME .. "'.")
        return true
    end

    Addon:Print("Could not create/update '" .. FOCUS_MACRO_NAME .. "': " .. tostring(err))
    return false
end

function Module:BuildAnnouncementMessage()
    local cfg = self:GetConfig()
    local markerTag = self:GetMarkerChatTag(cfg.markerIndex)
    local template = cfg.announceTemplate or ""

    if template == "" then
        template = "My Kick target is {RAIDMARKER}"
    end

    template = string.gsub(template, "{RAIDMARKER}", markerTag)
    return template
end

local function GetDungeonCategory()
    local _, instanceType, difficultyID = GetInstanceInfo()
    if instanceType ~= "party" then
        return nil
    end

    if tonumber(difficultyID) == 8 then
        return "mythicplus"
    end

    if tonumber(difficultyID) == 23 then
        return "mythic"
    end

    if tonumber(difficultyID) == 2 then
        return "heroic"
    end

    if tonumber(difficultyID) == 1 then
        return "normal"
    end

    return nil
end

function Module:ShouldAnnounceForCurrentDungeon()
    local cfg = self:GetConfig()
    local category = GetDungeonCategory()

    if category == "mythicplus" then
        return cfg.announceInMythicPlus
    end
    if category == "mythic" then
        return cfg.announceInMythicDungeon
    end
    if category == "heroic" then
        return cfg.announceInHeroicDungeon
    end
    if category == "normal" then
        return cfg.announceInNormalDungeon
    end
    return false
end

function Module:HandleReadyCheck()
    local cfg = self:GetConfig()
    if cfg.announceOnReadyCheck ~= true then
        return
    end

    if IsInRaid() then
        return
    end

    if not IsInGroup() then
        return
    end

    if not self:ShouldAnnounceForCurrentDungeon() then
        return
    end

    local message = self:BuildAnnouncementMessage()
    if message and message ~= "" then
        if C_ChatInfo and type(C_ChatInfo.SendChatMessage) == "function" then
            C_ChatInfo.SendChatMessage(message, "PARTY")
        end
    end
end

function Module:OnInitialize()
    self:GetConfig()

    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:SetScript("OnEvent", function(_, event)
            if event == "READY_CHECK" then
                self:HandleReadyCheck()
            end
        end)
    end
end

function Module:OnEnable()
    if self.eventFrame then
        self.eventFrame:RegisterEvent("READY_CHECK")
    end
end
