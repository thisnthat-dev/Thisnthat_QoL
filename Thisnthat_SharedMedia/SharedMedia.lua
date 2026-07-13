local ADDON_NAME = ...

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local MEDIA_ROOT = "Interface\\AddOns\\" .. ADDON_NAME .. "\\"

local SHARED_MEDIA = {
    fonts = {
        { name = "Thisnthat", file = "fonts\\Thisnthat.ttf" },
        { name = "FRIZQT", file = "fonts\\FRIZQT__.ttf" },
        { name = "Fira Mono Medium", file = "fonts\\FiraMono-Medium.ttf" },
        { name = "Expressway", file = "fonts\\Expressway.ttf" },
    },
    statusbars = {
        { name = "Thisnthat", file = "textures\\statusbar\\Thisnthat.tga" },
    },
    borders = {
        { name = "Thisnthat", file = "textures\\border\\thisnthat.tga" },
        { name = "Thisnthat Border 1px", file = "textures\\border\\thisnthat_1px.tga" },
        { name = "Thisnthat Border 2px", file = "textures\\border\\thisnthat_2px.tga" },
        { name = "Thisnthat Border White 2px", file = "textures\\border\\thisnthat_w_2px.tga" },
    },
    backgrounds = {
        { name = "Thisnthat Logo Wordmark", file = "textures\\logo_wordmark.png" },
        { name = "Thisnthat Logo Shield", file = "textures\\logo_shield.png" },
        { name = "Thisnthat Logo Icon", file = "textures\\logo_icon.png" },
        { name = "Thisnthat Kira Background 1", file = "textures\\Kira_background_1.png" },
        { name = "Thisnthat Ethric Arrow", file = "textures\\arrows\\EthricArrow.tga" },
        { name = "Thisnthat Ethric Arrow 2", file = "textures\\arrows\\EthricArrow2.tga" },
        { name = "Thisnthat Ethric Arrow 3", file = "textures\\arrows\\EthricArrow3.tga" },
        { name = "Thisnthat Ethric Arrow 4", file = "textures\\arrows\\EthricArrow4.tga" },
        { name = "Thisnthat Ethric Arrow 5", file = "textures\\arrows\\EthricArrow5.tga" },
        { name = "Thisnthat Ethric Arrow 6", file = "textures\\arrows\\EthricArrow6.tga" },
        { name = "Thisnthat Ethric Arrow 7", file = "textures\\arrows\\EthricArrow7.tga" },
        { name = "Thisnthat Ethric Arrow 8", file = "textures\\arrows\\EthricArrow8.tga" },
        { name = "Thisnthat Ethric Arrow 9", file = "textures\\arrows\\EthricArrow9.tga" },
        { name = "Thisnthat Ethric Arrow 10", file = "textures\\arrows\\EthricArrow10.tga" },
    },
    sounds = {
        { name = "Thisnthat - Add", file = "sounds\\add.ogg" },
        { name = "Thisnthat - Adds", file = "sounds\\adds.ogg" },
        { name = "Thisnthat - AoE", file = "sounds\\aoe.ogg" },
        { name = "Thisnthat - Apex", file = "sounds\\apex.ogg" },
        { name = "Thisnthat - Bait", file = "sounds\\bait.ogg" },
        { name = "Thisnthat - Battle Stance", file = "sounds\\battlestance.ogg" },
        { name = "Thisnthat - Bear Form", file = "sounds\\bearform.ogg" },
        { name = "Thisnthat - Bloodlust", file = "sounds\\bloodlust.ogg" },
        { name = "Thisnthat - Bubble", file = "sounds\\bubble.ogg" },
        { name = "Thisnthat - Bubble Out", file = "sounds\\bubbleout.ogg" },
        { name = "Thisnthat - Buff", file = "sounds\\buff.ogg" },
        { name = "Thisnthat - Cheat Death", file = "sounds\\cheatdeath.ogg" },
        { name = "Thisnthat - Cheat Death Back", file = "sounds\\cheatdeathback.ogg" },
        { name = "Thisnthat - Clean", file = "sounds\\clean.ogg" },
        { name = "Thisnthat - Damage Amp", file = "sounds\\damageamp.ogg" },
        { name = "Thisnthat - Dead", file = "sounds\\dead.ogg" },
        { name = "Thisnthat - Debuff", file = "sounds\\debuff.ogg" },
        { name = "Thisnthat - Debuffs", file = "sounds\\debuffs.ogg" },
        { name = "Thisnthat - Dispel", file = "sounds\\dispel.ogg" },
        { name = "Thisnthat - Dispell", file = "sounds\\dispell.ogg" },
        { name = "Thisnthat - Dodge", file = "sounds\\dodge.ogg" },
        { name = "Thisnthat - DRW", file = "sounds\\drw.ogg" },
        { name = "Thisnthat - Dwarf", file = "sounds\\dwarf.ogg" },
        { name = "Thisnthat - External", file = "sounds\\external.ogg" },
        { name = "Thisnthat - Fixate", file = "sounds\\fixate.ogg" },
        { name = "Thisnthat - Frontal", file = "sounds\\frontal.ogg" },
        { name = "Thisnthat - Heal", file = "sounds\\heal.ogg" },
        { name = "Thisnthat - Hide", file = "sounds\\hide.ogg" },
        { name = "Thisnthat - Intermission", file = "sounds\\intermission.ogg" },
        { name = "Thisnthat - Jump", file = "sounds\\jump.ogg" },
        { name = "Thisnthat - Kick", file = "sounds\\kick.ogg" },
        { name = "Thisnthat - Kite", file = "sounds\\kite.ogg" },
        { name = "Thisnthat - Knock", file = "sounds\\knock.ogg" },
        { name = "Thisnthat - Move", file = "sounds\\move.ogg" },
        { name = "Thisnthat - Noob", file = "sounds\\noob.ogg" },
        { name = "Thisnthat - On You", file = "sounds\\onyou.ogg" },
        { name = "Thisnthat - Potion", file = "sounds\\potion.ogg" },
        { name = "Thisnthat - Proc", file = "sounds\\proc.ogg" },
        { name = "Thisnthat - Ravage", file = "sounds\\ravage.ogg" },
        { name = "Thisnthat - Rebuff", file = "sounds\\rebuff.ogg" },
        { name = "Thisnthat - Remove", file = "sounds\\remove.ogg" },
        { name = "Thisnthat - Ress", file = "sounds\\ress.ogg" },
        { name = "Thisnthat - Run", file = "sounds\\run.ogg" },
        { name = "Thisnthat - Shields", file = "sounds\\shields.ogg" },
        { name = "Thisnthat - Soak", file = "sounds\\soak.ogg" },
        { name = "Thisnthat - Spellward", file = "sounds\\spellward.ogg" },
        { name = "Thisnthat - Spellward Out", file = "sounds\\spellwardout.ogg" },
        { name = "Thisnthat - Spread", file = "sounds\\spread.ogg" },
        { name = "Thisnthat - Tank Hit", file = "sounds\\tankhit.ogg" },
        { name = "Thisnthat - Targeted", file = "sounds\\targeted.ogg" },
        { name = "Thisnthat - Time Spiral", file = "sounds\\timespiral.ogg" },
        { name = "Thisnthat - Use", file = "sounds\\use.ogg" },
        { name = "Thisnthat - Watch", file = "sounds\\watch.ogg" },
        { name = "Thisnthat - Wings", file = "sounds\\wings.ogg" },
        { name = "Thisnthat - Wings Out", file = "sounds\\wingsout.ogg" },
    },
}

local function BuildSoundDisplayName(fallbackName)
    return "|cFF00FF00" .. fallbackName .. "|r"
end

local function RegisterMediaCollection(mediaType, collection)
    for _, media in ipairs(collection) do
        if media.name and media.file then
            local displayName = media.name
            if mediaType == "sound" then
                displayName = BuildSoundDisplayName(media.name)
            end

            LSM:Register(mediaType, displayName, MEDIA_ROOT .. media.file)
        end
    end
end

local function RegisterSharedMedia()
    if not LSM then
        local prefix = "|cff4ec9b0" .. ADDON_NAME .. "|r"
        print(prefix .. ": LibSharedMedia-3.0 was not found. Shared media was not registered.")
        return
    end

    RegisterMediaCollection("font", SHARED_MEDIA.fonts)
    RegisterMediaCollection("statusbar", SHARED_MEDIA.statusbars)
    RegisterMediaCollection("border", SHARED_MEDIA.borders)
    RegisterMediaCollection("background", SHARED_MEDIA.backgrounds)
    RegisterMediaCollection("sound", SHARED_MEDIA.sounds)

    LSM:Register("border", "1 Pixel", "Interface\\Buttons\\WHITE8X8")
end

local function RegisterElvUITags()
    local elvUI = rawget(_G, "ElvUI")
    local curveConstants = rawget(_G, "CurveConstants")
    if type(elvUI) ~= "table" then
        return
    end

    local E = unpack(elvUI)
    if not E or type(E.AddTag) ~= "function" then
        return
    end

    if not (C_CurveUtil and Enum and Enum.LuaCurveType and CreateColor and curveConstants and UnitHealthPercent) then
        return
    end

    local colorCurve = C_CurveUtil.CreateColorCurve()
    colorCurve:SetType(Enum.LuaCurveType.Linear)
    colorCurve:AddPoint(0.0, CreateColor(1, 0.3, 0.31))
    colorCurve:AddPoint(0.3, CreateColor(1, 0.3, 0.31))
    colorCurve:AddPoint(0.5, CreateColor(1, 0.93, 0.43))
    colorCurve:AddPoint(0.8, CreateColor(0.38, 0.87, 0.23))
    colorCurve:AddPoint(1.0, CreateColor(0.38, 0.87, 0.23))

    E:AddTag("health:percent-curvedcolor", "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH", function(unit)
        local color = UnitHealthPercent(unit, false, colorCurve)
        local value = UnitHealthPercent(unit, false, curveConstants.ScaleTo100)
        local text = string.format("%.0f", value)
        return color and color:WrapTextInColorCode(text) or text
    end)

    E:AddTag("healthcolor", "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH", function(unit)
        local color = UnitHealthPercent(unit, false, colorCurve)
        return color and color:GenerateHexColorMarkup() or ""
    end)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, loadedName)
    if loadedName ~= ADDON_NAME then
        return
    end

    RegisterSharedMedia()
    RegisterElvUITags()

    loader:UnregisterEvent("ADDON_LOADED")
end)