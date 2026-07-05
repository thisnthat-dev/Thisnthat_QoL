local _, ns = ...

local Addon = ns.Addon
local Module = {
    frame = nil,
    text = nil,
    closeBtn = nil,
    pveHooksInstalled = false,
}

Addon:RegisterModule("mplus_rewards", Module)

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

local COLORS = {
    base = "f3f3f3",
    champion = "0070dd",
    hero = "a335ee",
    myth = "ff8000",
}

local ILEVEL_RANGE = {
    champion = { 246, 250, 253, 256, 259, 263 },
    hero = { 259, 263, 266, 269, 272, 276 },
    myth = { 272, 276, 279, 282, 285, 289 },
}

local TRACK = {
    champion = { short = "C", name = "Champion", color = COLORS.champion, range = ILEVEL_RANGE.champion },
    hero = { short = "H", name = "Hero", color = COLORS.hero, range = ILEVEL_RANGE.hero },
    myth = { short = "M", name = "Myth", color = COLORS.myth, range = ILEVEL_RANGE.myth },
}

local KEY_REWARDS = {
    [1] = { loot = { track = TRACK.champion, value = 246 }, vault = { track = TRACK.champion, value = 256 }, crests = { track = TRACK.champion, value = 8 } },
    [2] = { loot = { track = TRACK.champion, value = 250 }, vault = { track = TRACK.champion, value = 259 }, crests = { track = TRACK.champion, value = 10 } },
    [3] = { loot = { track = TRACK.champion, value = 250 }, vault = { track = TRACK.champion, value = 259 }, crests = { track = TRACK.champion, value = 12 } },
    [4] = { loot = { track = TRACK.champion, value = 253 }, vault = { track = TRACK.hero, value = 263 }, crests = { track = TRACK.hero, value = 10 } },
    [5] = { loot = { track = TRACK.champion, value = 256 }, vault = { track = TRACK.hero, value = 263 }, crests = { track = TRACK.hero, value = 12 } },
    [6] = { loot = { track = TRACK.champion, value = 259 }, vault = { track = TRACK.hero, value = 266 }, crests = { track = TRACK.hero, value = 14 } },
    [7] = { loot = { track = TRACK.champion, value = 259 }, vault = { track = TRACK.hero, value = 269 }, crests = { track = TRACK.hero, value = 16 } },
    [8] = { loot = { track = TRACK.champion, value = 263 }, vault = { track = TRACK.hero, value = 269 }, crests = { track = TRACK.hero, value = 18 } },
    [9] = { loot = { track = TRACK.champion, value = 263 }, vault = { track = TRACK.hero, value = 269 }, crests = { track = TRACK.myth, value = 10 } },
    [10] = { loot = { track = TRACK.hero, value = 266 }, vault = { track = TRACK.myth, value = 272 }, crests = { track = TRACK.myth, value = 12 } },
    [11] = { loot = { track = TRACK.hero, value = 266 }, vault = { track = TRACK.myth, value = 272 }, crests = { track = TRACK.myth, value = 14 } },
    [12] = { loot = { track = TRACK.hero, value = 266 }, vault = { track = TRACK.myth, value = 272 }, crests = { track = TRACK.myth, value = 16 } },
}

local AFFIX_RULES = {
    [1] = { min = 2, maxExclusive = 6 },
    [2] = { min = 4, maxExclusive = 12 },
    [3] = { min = 7 },
    [4] = { min = 10 },
    [5] = { min = 12 },
}

local function Clamp(value, minValue, maxValue, fallback)
    local n = tonumber(value)
    if not n then
        return fallback
    end
    if n < minValue then
        return minValue
    end
    if n > maxValue then
        return maxValue
    end
    return n
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

local function NormalizeColor(value, defaultR, defaultG, defaultB, defaultA)
    local c = type(value) == "table" and value or {}
    return {
        r = Clamp(c.r, 0, 1, defaultR),
        g = Clamp(c.g, 0, 1, defaultG),
        b = Clamp(c.b, 0, 1, defaultB),
        a = Clamp(c.a, 0, 1, defaultA),
    }
end

local function GetModuleMedia()
    local mediaCfg = (Addon.GetModuleMediaConfig and Addon:GetModuleMediaConfig("mplus_rewards")) or {}
    return {
        font = mediaCfg.font,
        fontSize = Clamp(mediaCfg.fontSize, 8, 32, 12),
    }
end

local function GetOwnedKeystoneInfo()
    if not C_MythicPlus then
        return nil, nil
    end

    local mapID
    local level

    if type(C_MythicPlus.GetOwnedKeystoneChallengeMapID) == "function" then
        mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    end
    if type(C_MythicPlus.GetOwnedKeystoneLevel) == "function" then
        level = C_MythicPlus.GetOwnedKeystoneLevel()
    end

    return tonumber(mapID), tonumber(level)
end

local function GetKeystoneDisplayText()
    local mapID, keyLevel = GetOwnedKeystoneInfo()
    if not mapID or not keyLevel or keyLevel <= 0 then
        return "|cffff5555No Keystone|r"
    end

    local mapName
    if C_ChallengeMode and type(C_ChallengeMode.GetMapUIInfo) == "function" then
        mapName = C_ChallengeMode.GetMapUIInfo(mapID)
    end

    mapName = (type(mapName) == "string" and mapName ~= "") and mapName or ("Map " .. tostring(mapID))
    return "|cff22c55e+" .. tostring(keyLevel) .. "|r " .. mapName
end

local function GetAffixStatusLines()
    if not C_MythicPlus or type(C_MythicPlus.GetCurrentAffixes) ~= "function" then
        return { "|cffff5555No affix data available|r" }
    end

    local affixes = C_MythicPlus.GetCurrentAffixes() or {}
    if #affixes == 0 then
        return { "|cffff5555No active affixes found|r" }
    end

    local _, keyLevel = GetOwnedKeystoneInfo()
    local lines = {}

    local function IsAffixActive(index, keyLevel)
        local rule = AFFIX_RULES[index]
        if not rule then
            return false
        end

        if keyLevel < (rule.min or 0) then
            return false
        end

        if rule.maxExclusive and keyLevel >= rule.maxExclusive then
            return false
        end

        return true
    end

    for i, affix in ipairs(affixes) do
        local affixID = affix and affix.id
        local affixName
        if C_ChallengeMode and type(C_ChallengeMode.GetAffixInfo) == "function" and affixID then
            affixName = C_ChallengeMode.GetAffixInfo(affixID)
        end

        affixName = (type(affixName) == "string" and affixName ~= "") and affixName or ("Affix " .. tostring(affixID or i))

        local isActive = IsAffixActive(i, tonumber(keyLevel) or 0)
        local color = isActive and "22c55e" or "ff5555"
        lines[#lines + 1] = "|cff" .. color .. affixName .. "|r"
    end

    return lines
end

local function GetDB()
    Addon.db.mplus_rewards = type(Addon.db.mplus_rewards) == "table" and Addon.db.mplus_rewards or {}
    local db = Addon.db.mplus_rewards

    db.attachToPVE = db.attachToPVE ~= false
    local legacyX = tonumber(db.x) or 0
    local legacyY = tonumber(db.y) or -1
    db.attachedX = tonumber(db.attachedX)
    db.attachedY = tonumber(db.attachedY)
    db.detachedX = tonumber(db.detachedX)
    db.detachedY = tonumber(db.detachedY)
    if db.attachedX == nil then db.attachedX = legacyX end
    if db.attachedY == nil then db.attachedY = legacyY end
    if db.detachedX == nil then db.detachedX = legacyX end
    if db.detachedY == nil then db.detachedY = legacyY end
    db.x = nil
    db.y = nil
    db.point = NormalizePoint(db.point, "BOTTOMLEFT")
    db.relativePoint = NormalizePoint(db.relativePoint, "BOTTOMRIGHT")
    db.scale = Clamp(db.scale, 0.7, 2, 1)
    db.alpha = Clamp(db.alpha, 0.2, 1, 0.95)
    db.hideBackground = db.hideBackground and true or false
    db.hideBorder = db.hideBorder and true or false
    db.borderSize = Clamp(math.floor((tonumber(db.borderSize) or 1) + 0.5), 0, 8, 1)
    db.backgroundColor = NormalizeColor(db.backgroundColor, 0.08, 0.08, 0.08, 0.94)
    db.borderColor = NormalizeColor(db.borderColor, 0.31, 0.30, 0.30, 0.85)

    return db
end

function Module:GetRank(keyReward)
    local range = keyReward and keyReward.track and keyReward.track.range
    if type(range) ~= "table" then
        return 0
    end

    for i = 1, #range do
        if keyReward.value == range[i] then
            return i
        end
    end

    return 0
end

function Module:BuildRewardString()
    local rewardText = ""

    rewardText = rewardText .. "Key: " .. GetKeystoneDisplayText() .. "\n"
    rewardText = rewardText .. "Affixes:\n"
    for _, line in ipairs(GetAffixStatusLines()) do
        rewardText = rewardText .. "  - " .. line .. "\n"
    end
    rewardText = rewardText .. "\n"

    rewardText = rewardText .. string.format("%10s %12s %9s", "Loot", "Vault", "Crest")

    for key = 2, 12 do
        local keyReward = KEY_REWARDS[key]
        if keyReward then
            local lootRank = self:GetRank(keyReward.loot)
            local vaultRank = self:GetRank(keyReward.vault)

            local lootText = "|cff" .. keyReward.loot.track.color .. keyReward.loot.value .. " (" .. lootRank .. "/" .. #keyReward.loot.track.range .. ")|r"
            local vaultText = "|cff" .. keyReward.vault.track.color .. keyReward.vault.value .. " (" .. vaultRank .. "/" .. #keyReward.vault.track.range .. ")|r"
            local crestCountText = "|cff" .. keyReward.crests.track.color .. keyReward.crests.value .. " (" .. (keyReward.crests.value - 4) .. ")|r"

            rewardText = rewardText .. string.format("\n|cff%s%2d:|r %-18s | %-18s | %s", COLORS.base, key, lootText, vaultText, crestCountText)
        end
    end

    return rewardText
end

function Module:CreateFrame()
    if self.frame then
        return
    end

    local uiParent = rawget(_G, "UIParent")
    if not uiParent then
        return
    end

    local frame = CreateFrame("Frame", "ThisnthatQOL_MPlusRewardsFrame", uiParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(0.08, 0.08, 0.08, 0.94)
    frame:SetBackdropBorderColor(0.31, 0.30, 0.30, 0.85)

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetSpacing(2)

    local closeBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    closeBtn:SetSize(18, 18)
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    closeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    closeBtn:SetBackdropColor(0.31, 0.30, 0.30, 0.34)
    closeBtn:SetBackdropBorderColor(0.31, 0.30, 0.30, 0.75)

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeText:SetPoint("CENTER", 0, 0)
    closeText:SetText("X")
    closeText:SetTextColor(1, 1, 1, 0.92)

    closeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.78, 0.23, 0.30, 0.36)
        self:SetBackdropBorderColor(0.78, 0.23, 0.30, 0.95)
        closeText:SetTextColor(0.78, 0.23, 0.30, 1)
    end)

    closeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.31, 0.30, 0.30, 0.34)
        self:SetBackdropBorderColor(0.31, 0.30, 0.30, 0.75)
        closeText:SetTextColor(1, 1, 1, 0.92)
    end)

    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    self.frame = frame
    self.text = text
    self.closeBtn = closeBtn

    frame:SetScript("OnDragStart", function(selfFrame)
        local db = GetDB()
        if db.attachToPVE then
            return
        end
        selfFrame:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()

        local db = GetDB()
        if db.attachToPVE then
            return
        end

        local _, _, _, x, y = selfFrame:GetPoint(1)
        db.detachedX = tonumber(x) or db.detachedX or 0
        db.detachedY = tonumber(y) or db.detachedY or 0
    end)
end

function Module:UpdateStyle()
    if not self.frame or not self.text then
        return
    end

    local db = GetDB()
    local mediaCfg = GetModuleMedia()
    local fontPath = rawget(_G, "STANDARD_TEXT_FONT") or "Fonts\\FRIZQT__.TTF"
    local fontSize = mediaCfg.fontSize

    if mediaCfg.font and LSM and type(LSM.Fetch) == "function" then
        fontPath = LSM:Fetch("font", mediaCfg.font, true) or fontPath
    end

    self.text:SetFont(fontPath, fontSize, "")
    self.text:SetText(self:BuildRewardString())

    local bg = db.backgroundColor or { r = 0.08, g = 0.08, b = 0.08, a = 0.94 }
    local border = db.borderColor or { r = 0.31, g = 0.30, b = 0.30, a = 0.85 }
    local borderSize = Clamp(db.borderSize, 0, 8, 1)
    self.frame:SetBackdrop({
        bgFile = db.hideBackground and nil or "Interface\\Buttons\\WHITE8X8",
        edgeFile = db.hideBorder and nil or "Interface\\Buttons\\WHITE8X8",
        edgeSize = db.hideBorder and 0 or borderSize,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    self.frame:SetBackdropColor(bg.r, bg.g, bg.b, db.hideBackground and 0 or bg.a)
    self.frame:SetBackdropBorderColor(border.r, border.g, border.b, db.hideBorder and 0 or border.a)

    local width = math.max(self.text:GetStringWidth() + 16, 220)
    local height = math.max(self.text:GetStringHeight() + 14, 140)
    self.frame:SetSize(width, height)
    self.frame:SetScale(db.scale)
    self.frame:SetAlpha(db.alpha)
end

function Module:ApplyPosition()
    if not self.frame then
        return
    end

    local db = GetDB()
    local pveFrame = rawget(_G, "PVEFrame")
    local uiParent = rawget(_G, "UIParent")

    self.frame:ClearAllPoints()
    if db.attachToPVE and pveFrame then
        self.frame:SetFrameStrata(pveFrame:GetFrameStrata() or "MEDIUM")
        self.frame:SetFrameLevel((pveFrame:GetFrameLevel() or 1) + 1)
        self.frame:SetPoint(db.point, pveFrame, db.relativePoint, db.attachedX, db.attachedY)
        if self.closeBtn then
            self.closeBtn:Hide()
        end
    else
        self.frame:SetFrameStrata("DIALOG")
        self.frame:SetFrameLevel(20)
        self.frame:SetPoint("CENTER", uiParent, "CENTER", db.detachedX, db.detachedY)
        if self.closeBtn then
            self.closeBtn:Show()
        end
    end
end

local function OpenPVEWindow()
    local pveFrame = rawget(_G, "PVEFrame")
    if not pveFrame then
        local pveLoadUI = rawget(_G, "PVEFrame_LoadUI")
        if type(pveLoadUI) == "function" then
            pveLoadUI()
            pveFrame = rawget(_G, "PVEFrame")
        end
    end

    if pveFrame then
        local showUIPanel = rawget(_G, "ShowUIPanel")
        if type(showUIPanel) == "function" then
            showUIPanel(pveFrame)
            return true
        end
        pveFrame:Show()
        return true
    end

    return false
end

function Module:RefreshVisibility()
    if not self.frame then
        return
    end

    if not Addon:IsModuleEnabled("mplus_rewards") then
        self.frame:Hide()
        return
    end

    local db = GetDB()
    local pveFrame = rawget(_G, "PVEFrame")
    if db.attachToPVE and pveFrame and not pveFrame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function Module:Refresh()
    if not self.frame then
        self:CreateFrame()
    end
    if not self.frame then
        return
    end

    self:UpdateStyle()
    self:ApplyPosition()
    self:RefreshVisibility()
end

function Module:SetEnabled(enabled)
    Addon.db.modules.mplus_rewards.enabled = enabled and true or false
    self:Refresh()
end

function Module:OpenWindow()
    if not Addon:IsModuleEnabled("mplus_rewards") then
        Addon:Print("M+ Rewards module is disabled.")
        return
    end

    local db = GetDB()
    if db.attachToPVE then
        if not OpenPVEWindow() then
            Addon:Print("Unable to open PVE window.")
        end
        self:Refresh()
        return
    end

    self:Refresh()
    if self.frame then
        self.frame:Show()
    end
end

function Module:InstallPVEHooks()
    if self.pveHooksInstalled then
        return
    end

    local pveFrame = rawget(_G, "PVEFrame")
    if not pveFrame then
        return
    end

    pveFrame:HookScript("OnShow", function()
        Module:RefreshVisibility()
    end)
    pveFrame:HookScript("OnHide", function()
        Module:RefreshVisibility()
    end)

    self.pveHooksInstalled = true
end

function Module:OnInitialize()
    GetDB()
end

function Module:OnEnable()
    self:InstallPVEHooks()
    self:Refresh()

    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.eventFrame:SetScript("OnEvent", function()
            Module:InstallPVEHooks()
            Module:Refresh()
        end)
    end
end
