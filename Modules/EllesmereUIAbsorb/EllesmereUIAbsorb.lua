local _, ns = ...

local Addon = ns.Addon
local Module = {}

Addon:RegisterModule("EllesmereUIAbsorb", Module)

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local ABSORB_MEDIA_ROOT = "Interface\\AddOns\\Thisnthat_QoL\\Modules\\EllesmereUIAbsorb\\Media\\shields\\"
local BUILTIN_SHIELD_MEDIA = {
    { name = "Thisnthat Shield", file = "shield.tga" },
    { name = "Thisnthat Striped Shield", file = "striped3.tga" },
    { name = "Thisnthat Striped Shield Reversed", file = "striped-5-reversed.png" },
    { name = "Thisnthat Blizzard Shield", file = "blizzard.tga" },
    { name = "Thisnthat Large Shield Stripes", file = "large-absorb-left.png" },
    { name = "Thisnthat Large Shield Stripes Reversed", file = "large-absorb-right.png" },
    { name = "Thisnthat Large HealAbsorb Stripes", file = "large-habsorb-left.png" },
    { name = "Thisnthat Large HealAbsorb Stripes Reversed", file = "large-habsorb-right.png" },
}
local SHIELD_TEXTURE = "Thisnthat Shield"
local BUILTIN_TEXTURE_BY_NAME = {}
local BUILTIN_TEXTURE_NAMES = {}
local didRegisterBuiltinMedia = false
local TILED_TEXTURE_NAME_SET = {
    ["thisnthat striped shield reversed"] = true,
    ["thisnthat large shield stripes"] = true,
    ["thisnthat large shield stripes reversed"] = true,
    ["thisnthat large healabsorb stripes"] = true,
    ["thisnthat large healabsorb stripes reversed"] = true,
}
local BAR_POINTS = {
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

do
    for _, media in ipairs(BUILTIN_SHIELD_MEDIA) do
        BUILTIN_TEXTURE_BY_NAME[media.name] = ABSORB_MEDIA_ROOT .. media.file
        BUILTIN_TEXTURE_NAMES[#BUILTIN_TEXTURE_NAMES + 1] = media.name
    end
end

local function EnsureBuiltinMediaRegistered()
    if didRegisterBuiltinMedia or not LSM or type(LSM.Register) ~= "function" then
        return
    end

    for _, media in ipairs(BUILTIN_SHIELD_MEDIA) do
        LSM:Register("statusbar", media.name, ABSORB_MEDIA_ROOT .. media.file)
    end

    didRegisterBuiltinMedia = true
end

local function GetDB()
    Addon.db.EllesmereUIAbsorb = type(Addon.db.EllesmereUIAbsorb) == "table" and Addon.db.EllesmereUIAbsorb or {}
    local db = Addon.db.EllesmereUIAbsorb

    db.enabled = db.enabled ~= false
    db.absorbColor = type(db.absorbColor) == "table" and db.absorbColor or { r = 1, g = 1, b = 1, a = 0.8 }
    db.healAbsorbColor = type(db.healAbsorbColor) == "table" and db.healAbsorbColor or { r = 0.8, g = 0.15, b = 0.15, a = 0.65 }
    db.absorbTexture = type(db.absorbTexture) == "string" and db.absorbTexture or SHIELD_TEXTURE
    db.healAbsorbTexture = type(db.healAbsorbTexture) == "string" and db.healAbsorbTexture or SHIELD_TEXTURE
    db.previewHealth = Clamp(db.previewHealth, 1, 100, 62)
    db.previewAbsorb = Clamp(db.previewAbsorb, 0, 100, 22)
    db.previewHealAbsorb = Clamp(db.previewHealAbsorb, 0, 100, 16)

    return db
end

local function GetTexturePath()
    EnsureBuiltinMediaRegistered()

    if LSM and type(LSM.Fetch) == "function" then
        return LSM:Fetch("statusbar", SHIELD_TEXTURE, true) or "Interface\\Buttons\\WHITE8X8"
    end

    return BUILTIN_TEXTURE_BY_NAME[SHIELD_TEXTURE] or "Interface\\Buttons\\WHITE8X8"
end

local function ResolveTexture(textureName)
    EnsureBuiltinMediaRegistered()

    if type(textureName) == "string" and textureName ~= "" and BUILTIN_TEXTURE_BY_NAME[textureName] then
        return BUILTIN_TEXTURE_BY_NAME[textureName]
    end

    if type(textureName) == "string" and textureName ~= "" and LSM and type(LSM.Fetch) == "function" then
        return LSM:Fetch("statusbar", textureName, true) or GetTexturePath()
    end

    return GetTexturePath()
end

local function IsTiledAbsorbTexture(textureName, texturePath)
    local normalizedName = type(textureName) == "string" and string.lower(textureName) or ""
    if TILED_TEXTURE_NAME_SET[normalizedName] then
        return true
    end

    if type(texturePath) ~= "string" or texturePath == "" then
        return false
    end

    local lowerPath = string.lower(texturePath)
    if string.find(lowerPath, "striped%-5%-reversed%.png", 1, false)
        or string.find(lowerPath, "large%-absorb%-left%.png", 1, false)
        or string.find(lowerPath, "large%-absorb%-right%.png", 1, false)
        or string.find(lowerPath, "large%-habsorb%-left%.png", 1, false)
        or string.find(lowerPath, "large%-habsorb%-right%.png", 1, false) then
        return true
    end

    return false
end

local function ApplyTextureTiling(statusBar, tiled)
    if not statusBar then
        return
    end

    local fill = statusBar:GetStatusBarTexture()
    if not fill then
        return
    end

    fill:SetDrawLayer("ARTWORK", 1)
    fill:SetHorizTile(tiled and true or false)
    fill:SetVertTile(tiled and true or false)
end

local function ApplyColor(texture, color)
    if not texture then
        return
    end

    local c = type(color) == "table" and color or {}
    texture:SetVertexColor(
        Clamp(c.r, 0, 1, 1),
        Clamp(c.g, 0, 1, 1),
        Clamp(c.b, 0, 1, 1),
        Clamp(c.a, 0, 1, 1)
    )
end

local function SecureUnitNumber(apiFn, unitToken)
    if type(apiFn) ~= "function" then
        return nil
    end

    local value
    if type(securecallfunction) == "function" then
        value = securecallfunction(apiFn, unitToken)
    else
        local ok, result = pcall(apiFn, unitToken)
        if ok then
            value = result
        end
    end

    if type(value) ~= "number" then
        return nil
    end

    return value
end

local function EnsureOverlay()
    if Module.overlayFrame and Module.absorbBar and Module.healAbsorbBar then
        return true
    end

    local bar = rawget(_G, "ERB_HealthBar")
    if not bar then
        return false
    end

    local fillParent = bar._sb or bar
    if not fillParent then
        return false
    end

    local overlayFrame = CreateFrame("Frame", nil, bar)
    overlayFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, -1)
    overlayFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -1, 1)
    overlayFrame:SetFrameStrata(bar:GetFrameStrata() or "MEDIUM")
    overlayFrame:SetFrameLevel((bar:GetFrameLevel() or 1) + 30)
    overlayFrame:EnableMouse(false)

    local absorbBar = CreateFrame("StatusBar", nil, overlayFrame)
    absorbBar:SetAllPoints(overlayFrame)
    absorbBar:SetStatusBarTexture(GetTexturePath())
    absorbBar:SetReverseFill(false)
    absorbBar:SetMinMaxValues(0, 1)
    absorbBar:SetValue(0)
    absorbBar:Hide()

    local healAbsorbBar = CreateFrame("StatusBar", nil, overlayFrame)
    healAbsorbBar:SetAllPoints(overlayFrame)
    healAbsorbBar:SetStatusBarTexture(GetTexturePath())
    healAbsorbBar:SetReverseFill(true)
    healAbsorbBar:SetMinMaxValues(0, 1)
    healAbsorbBar:SetValue(0)
    healAbsorbBar:Hide()

    Module.overlayFrame = overlayFrame
    Module.absorbBar = absorbBar
    Module.healAbsorbBar = healAbsorbBar

    return true
end

local function UpdateOverlay()
    if not Addon.db then
        if Module.overlayFrame then
            Module.overlayFrame:Hide()
        end
        return
    end

    local moduleEnabled = true
    if Addon.db.modules and Addon.db.modules.EllesmereUIAbsorb and Addon.db.modules.EllesmereUIAbsorb.enabled == false then
        moduleEnabled = false
    end

    local settingsEnabled = true
    if Addon.db.EllesmereUIAbsorb and Addon.db.EllesmereUIAbsorb.enabled == false then
        settingsEnabled = false
    end

    if not moduleEnabled or not settingsEnabled then
        if Module.overlayFrame then
            Module.overlayFrame:Hide()
        end
        return
    end

    if not IsAddOnLoadedByName("EllesmereUIResourceBars") then
        if Module.overlayFrame then
            Module.overlayFrame:Hide()
        end
        return
    end

    if not EnsureOverlay() then
        return
    end

    local db = GetDB()
    local maxHealth = SecureUnitNumber(UnitHealthMax, "player") or 1
    local absorbAmount = SecureUnitNumber(UnitGetTotalAbsorbs, "player") or 0
    local healAbsorbAmount = SecureUnitNumber(UnitGetTotalHealAbsorbs, "player") or 0

    local overlayFrame = Module.overlayFrame
    local absorbBar = Module.absorbBar
    local healAbsorbBar = Module.healAbsorbBar
    local absorbTexture = ResolveTexture(db.absorbTexture)
    local healAbsorbTexture = ResolveTexture(db.healAbsorbTexture)
    local absorbTiled = IsTiledAbsorbTexture(db.absorbTexture, absorbTexture)
    local healAbsorbTiled = IsTiledAbsorbTexture(db.healAbsorbTexture, healAbsorbTexture)

    overlayFrame:Show()
    absorbBar:SetStatusBarTexture(absorbTexture)
    healAbsorbBar:SetStatusBarTexture(healAbsorbTexture)
    ApplyTextureTiling(absorbBar, absorbTiled)
    ApplyTextureTiling(healAbsorbBar, healAbsorbTiled)

    ApplyColor(absorbBar:GetStatusBarTexture(), db.absorbColor)
    ApplyColor(healAbsorbBar:GetStatusBarTexture(), db.healAbsorbColor)

    absorbBar:SetMinMaxValues(0, maxHealth)
    healAbsorbBar:SetMinMaxValues(0, maxHealth)
    absorbBar:SetValue(absorbAmount or 0)
    healAbsorbBar:SetValue(healAbsorbAmount or 0)

    absorbBar:SetShown(true)
    healAbsorbBar:SetShown(true)
end

function Module:GetTexturePath()
    return GetTexturePath()
end

function Module:GetBuiltInTextureNames()
    return BUILTIN_TEXTURE_NAMES
end

function Module:IsTiledAbsorbTexture(textureName, texturePath)
    return IsTiledAbsorbTexture(textureName, texturePath)
end

function Module:GetAbsorbTexturePath()
    return ResolveTexture(GetDB().absorbTexture)
end

function Module:GetHealAbsorbTexturePath()
    return ResolveTexture(GetDB().healAbsorbTexture)
end

function Module:GetSettings()
    return GetDB()
end

function Module:SetEnabled(enabled)
    GetDB().enabled = enabled and true or false
    UpdateOverlay()
end

function Module:ApplySettings()
    UpdateOverlay()
end

function Module:OnInitialize()
    EnsureBuiltinMediaRegistered()

    if not IsAddOnLoadedByName("EllesmereUIResourceBars") then
        GetDB().enabled = false
        return
    end

    GetDB()
end

function Module:OnEnable()
    UpdateOverlay()
end

function Module:OnEvent(event, unit)
    if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD"
    or event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" or event == "UNIT_AURA"
    or event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        if unit and unit ~= "player" then
            return
        end
        UpdateOverlay()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "player")
eventFrame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "player")
eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
eventFrame:RegisterUnitEvent("UNIT_HEALTH", "player")
eventFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
eventFrame:SetScript("OnEvent", function(_, event, unit)
    Module:OnEvent(event, unit)
end)