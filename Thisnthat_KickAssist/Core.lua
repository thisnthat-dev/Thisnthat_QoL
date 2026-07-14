local ADDON_NAME, ns = ...

local Addon = CreateFrame("Frame")
ns.Addon = Addon
_G.Thisnthat_KickAssist_Addon = Addon

local LibStubRef = rawget(_G, "LibStub")
local LDB = LibStubRef and LibStubRef("LibDataBroker-1.1", true)
local LibDBIcon = LibStubRef and LibStubRef("LibDBIcon-1.0", true)

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
    { index = 0, name = "None" },
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
local MINIMAP_BUTTON_ICON = 132219
local MINIMAP_LDB_NAME = "Thisnthat_KickAssist"

local defaults = {
    markerIndex = 0,
    hideMinimapButton = false,
    minimapButtonAngle = 220,
    minimap = {
        hide = false,
        minimapPos = 220,
    },
    interruptSpell = "AUTO",
    announceOnReadyCheck = false,
    announceTemplate = "My Kick target is {RAIDMARKER}",
    announceInMythicPlus = true,
    announceInMythicDungeon = false,
    announceInHeroicDungeon = false,
    announceInNormalDungeon = false,
}

local function DeepCopyTable(src)
    if type(src) ~= "table" then
        return src
    end

    local out = {}
    for key, value in pairs(src) do
        out[key] = DeepCopyTable(value)
    end

    return out
end

local function MergeDefaults(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return
    end

    for key, value in pairs(source) do
        if target[key] == nil then
            target[key] = DeepCopyTable(value)
        elseif type(value) == "table" and type(target[key]) == "table" then
            MergeDefaults(target[key], value)
        end
    end
end

local function ClampMarkerIndex(index)
    local marker = tonumber(index)
    if not marker then
        return 0
    end

    marker = math.floor(marker + 0.5)
    if marker < 0 then
        marker = 0
    elseif marker > 8 then
        marker = 8
    end

    return marker
end

function Addon:Print(message)
    local prefix = "|cff4ec9b0" .. ADDON_NAME .. "|r"
    print(prefix .. ": " .. tostring(message))
end

function Addon:GetConfig()
    self.db = type(self.db) == "table" and self.db or {}
    MergeDefaults(self.db, defaults)

    self.db.minimap = type(self.db.minimap) == "table" and self.db.minimap or {}
    self.db.markerIndex = ClampMarkerIndex(self.db.markerIndex)
    if self.db.hideMinimapButton == nil and self.db.minimap.hide ~= nil then
        self.db.hideMinimapButton = self.db.minimap.hide and true or false
    end
    self.db.hideMinimapButton = self.db.hideMinimapButton and true or false
    if self.db.minimapButtonAngle == nil and self.db.minimap.minimapPos ~= nil then
        self.db.minimapButtonAngle = tonumber(self.db.minimap.minimapPos)
    end
    self.db.minimapButtonAngle = tonumber(self.db.minimapButtonAngle) or 220
    self.db.minimap.hide = self.db.hideMinimapButton
    self.db.minimap.minimapPos = self.db.minimapButtonAngle
    self.db.interruptSpell = type(self.db.interruptSpell) == "string" and self.db.interruptSpell or "AUTO"
    if self.db.interruptSpell == "" then
        self.db.interruptSpell = "AUTO"
    end
    self.db.announceOnReadyCheck = self.db.announceOnReadyCheck and true or false
    self.db.announceTemplate = type(self.db.announceTemplate) == "string" and self.db.announceTemplate or defaults.announceTemplate
    self.db.announceInMythicPlus = self.db.announceInMythicPlus and true or false
    self.db.announceInMythicDungeon = self.db.announceInMythicDungeon and true or false
    self.db.announceInHeroicDungeon = self.db.announceInHeroicDungeon and true or false
    self.db.announceInNormalDungeon = self.db.announceInNormalDungeon and true or false

    return self.db
end

function Addon:UpdateMinimapButtonPosition()
    local cfg = self:GetConfig()
    cfg.minimap.minimapPos = tonumber(cfg.minimapButtonAngle) or 220
end

function Addon:UpdateMinimapButton()
    local cfg = self:GetConfig()
    cfg.minimap.hide = cfg.hideMinimapButton
    self:UpdateMinimapButtonPosition()

    if not (self.minimapIconRegistered and LibDBIcon) then
        return
    end

    if cfg.hideMinimapButton then
        LibDBIcon:Hide(MINIMAP_LDB_NAME)
    else
        LibDBIcon:Show(MINIMAP_LDB_NAME)
    end

    if type(ns.RefreshOptionsFrame) == "function" then
        ns:RefreshOptionsFrame()
    end

    local refreshSharedOptionsTab = rawget(_G, "Thisnthat_RefreshOptionsTab")
    if type(refreshSharedOptionsTab) == "function" then
        refreshSharedOptionsTab("KickAssist")
    end
end

function Addon:EnsureLibDBIconButton()
    if self.minimapIconRegistered or not (LDB and LibDBIcon) then
        return false
    end

    self.ldbObject = self.ldbObject or LDB:NewDataObject(MINIMAP_LDB_NAME, {
        type = "launcher",
        text = "Kick Assist",
        label = "Kick Assist",
        icon = MINIMAP_BUTTON_ICON,
        OnClick = function(_, mouseButton)
            if mouseButton == "RightButton" then
                local cfg = self:GetConfig()
                cfg.hideMinimapButton = true
                self:UpdateMinimapButton()
                return
            end

            self:ToggleOptions()
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip then
                return
            end
            tooltip:AddLine("Thisnthat Kick Assist")
            tooltip:AddLine("Left-click: Toggle options", 0.8, 0.8, 0.8)
            tooltip:AddLine("Right-click: Hide minimap button", 0.8, 0.8, 0.8)
        end,
    })

    local cfg = self:GetConfig()
    LibDBIcon:Register(MINIMAP_LDB_NAME, self.ldbObject, cfg.minimap)
    self.minimapIconRegistered = true
    return true
end

function Addon:GetRaidMarkers()
    return RAID_MARKERS
end

function Addon:GetSelectedMarker()
    local cfg = self:GetConfig()
    local index = ClampMarkerIndex(cfg.markerIndex)
    for _, marker in ipairs(RAID_MARKERS) do
        if marker.index == index then
            return marker
        end
    end

    return RAID_MARKERS[1]
end

function Addon:GetMarkerTextureTag(index, size)
    local markerIndex = ClampMarkerIndex(index)
    if markerIndex == 0 then
        return ""
    end

    local iconSize = tonumber(size) or 14
    return string.format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:%d:%d:0:0|t", markerIndex, iconSize, iconSize)
end

function Addon:GetMarkerChatTag(index)
    if ClampMarkerIndex(index) == 0 then
        return ""
    end

    return "{rt" .. tostring(ClampMarkerIndex(index)) .. "}"
end

function Addon:GetInterruptSpellName()
    local cfg = self:GetConfig()
    if cfg.interruptSpell ~= "AUTO" and cfg.interruptSpell ~= "" then
        return cfg.interruptSpell
    end

    local _, classToken = UnitClass("player")
    local spellName = CLASS_INTERRUPT_SPELL[classToken or ""]
    if not spellName or spellName == "" then
        return "Interrupt"
    end

    return spellName
end

function Addon:GetInterruptSpellChoices()
    local choices = {
        { value = "AUTO", label = "Auto (Class Default)" },
    }

    for _, spellName in ipairs(INTERRUPT_SPELL_CHOICES) do
        choices[#choices + 1] = { value = spellName, label = spellName }
    end

    return choices
end

function Addon:BuildKickMacro()
    local interruptSpell = self:GetInterruptSpellName()
    return table.concat({
        "#showtooltip " .. interruptSpell,
        "/cast [@focus,exists,harm,nodead] " .. interruptSpell .. "; [@target,harm] " .. interruptSpell .. "; [@targettarget,harm] " .. interruptSpell,
    }, "\n")
end

function Addon:BuildFocusMacro(markerIndex)
    local index = ClampMarkerIndex(markerIndex or self:GetConfig().markerIndex)
    local lines = {
        "/focus [@mouseover, exists][]",
    }
    if index > 0 then
        lines[#lines + 1] = "/tm [@mouseover, exists][] ~" .. tostring(index)
    end

    return table.concat(lines, "\n")
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

function Addon:CreateKickMacro()
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
        self:Print("Created/updated character macro '" .. KICK_MACRO_NAME .. "'.")
        return true
    end

    self:Print("Could not create/update '" .. KICK_MACRO_NAME .. "': " .. tostring(err))
    return false
end

function Addon:CreateFocusMacro()
    local ok, err = UpsertMacro(FOCUS_MACRO_NAME, FOCUS_MACRO_ICON, self:BuildFocusMacro(), false)
    if ok then
        self:Print("Created/updated account macro '" .. FOCUS_MACRO_NAME .. "'.")
        return true
    end

    self:Print("Could not create/update '" .. FOCUS_MACRO_NAME .. "': " .. tostring(err))
    return false
end

function Addon:BuildAnnouncementMessage()
    local cfg = self:GetConfig()
    if ClampMarkerIndex(cfg.markerIndex) == 0 then
        return ""
    end

    local template = cfg.announceTemplate or ""
    if template == "" then
        template = defaults.announceTemplate
    end

    return string.gsub(template, "{RAIDMARKER}", self:GetMarkerChatTag(cfg.markerIndex))
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

function Addon:ShouldAnnounceForCurrentDungeon()
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

function Addon:HandleReadyCheck()
    local cfg = self:GetConfig()
    if cfg.announceOnReadyCheck ~= true then
        return
    end
    if ClampMarkerIndex(cfg.markerIndex) == 0 then
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
    if message ~= "" and C_ChatInfo and type(C_ChatInfo.SendChatMessage) == "function" then
        C_ChatInfo.SendChatMessage(message, "PARTY")
    end
end

function Addon:ToggleOptions()
    local sharedShowOptions = rawget(_G, "Thisnthat_ShowOptions")
    local sharedFrame = rawget(_G, "ThisnthatQoL_OptionsFrame")
    if type(sharedShowOptions) == "function" then
        if sharedFrame and type(sharedFrame.IsShown) == "function" and sharedFrame:IsShown() then
            sharedFrame:Hide()
        else
            sharedShowOptions("KickAssist")
        end
        return
    end

    if type(ns.IsOptionsFrameShown) == "function" and ns:IsOptionsFrameShown() then
        if type(ns.HideOptionsFrame) == "function" then
            ns:HideOptionsFrame()
        end
        return
    end

    if type(ns.OpenOptionsFrame) == "function" then
        ns:OpenOptionsFrame()
    end
end

function Addon:OpenOptions()
    local sharedShowOptions = rawget(_G, "Thisnthat_ShowOptions")
    if type(sharedShowOptions) == "function" then
        sharedShowOptions("KickAssist")
        return
    end

    if type(ns.OpenOptionsFrame) == "function" then
        ns:OpenOptionsFrame()
    end
end

SLASH_THISNTHATKICKASSIST1 = "/tntk"
SLASH_THISNTHATKICKASSIST2 = "/tntkick"
SLASH_THISNTHATKICKASSIST3 = "/tntka"
do
    local slashCmdList = rawget(_G, "SlashCmdList")
    if slashCmdList then
        slashCmdList.THISNTHATKICKASSIST = function()
            Addon:ToggleOptions()
        end
    end
end

Addon:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedName = ...
        if loadedName ~= ADDON_NAME then
            return
        end

        Thisnthat_KickAssistDB = type(Thisnthat_KickAssistDB) == "table" and Thisnthat_KickAssistDB or {}
        Addon.db = Thisnthat_KickAssistDB
        Addon:GetConfig()
    elseif event == "PLAYER_LOGIN" then
        Addon:EnsureLibDBIconButton()
        Addon:UpdateMinimapButton()
        Addon:RegisterEvent("READY_CHECK")
    elseif event == "READY_CHECK" then
        Addon:HandleReadyCheck()
    end
end)

Addon:RegisterEvent("ADDON_LOADED")
Addon:RegisterEvent("PLAYER_LOGIN")
