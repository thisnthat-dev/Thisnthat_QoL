local ADDON_NAME, ns = ...

local brokerName = ADDON_NAME .. " Specialization"
local menuFrame = nil
local fallbackMenuFrame = nil
local fallbackMenuCloseCatcher = nil
local fallbackMenuButtons = {}
local dataObject = nil
local addonRef = nil
local moduleRef = nil
local eventFrame = nil
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local function GetCurrentSpecializationIndex()
    local getSpecialization = rawget(_G, "GetSpecialization")
    local specIndex = type(getSpecialization) == "function" and getSpecialization() or nil
    if type(specIndex) ~= "number" or specIndex < 1 then
        return nil
    end

    return specIndex
end

local function GetCurrentSpecializationID()
    local specIndex = GetCurrentSpecializationIndex()
    if not specIndex then
        return nil
    end

    local getSpecializationInfo = rawget(_G, "GetSpecializationInfo")
    if type(getSpecializationInfo) ~= "function" then
        return nil
    end

    local specID = getSpecializationInfo(specIndex)
    if type(specID) ~= "number" then
        return nil
    end

    return specID
end

local function GetSpecializationInfoByIndex(specIndex)
    if type(specIndex) ~= "number" then
        return nil
    end

    local getSpecializationInfo = rawget(_G, "GetSpecializationInfo")
    if type(getSpecializationInfo) ~= "function" then
        return nil
    end

    local specID, specName, _, specIcon = getSpecializationInfo(specIndex)
    if not specID then
        return nil
    end

    return {
        index = specIndex,
        id = specID,
        name = specName,
        icon = specIcon,
    }
end

local function GetClassSpecializations()
    local specializations = {}
    local getNumSpecializations = rawget(_G, "GetNumSpecializations")
    local specCount = type(getNumSpecializations) == "function" and getNumSpecializations() or 0

    for specIndex = 1, specCount do
        local specInfo = GetSpecializationInfoByIndex(specIndex)
        if specInfo then
            specializations[#specializations + 1] = specInfo
        end
    end

    return specializations
end

local function GetLootSpecializationID()
    local getLootSpecialization = rawget(_G, "GetLootSpecialization")
    local lootSpecID = type(getLootSpecialization) == "function" and getLootSpecialization() or 0
    if type(lootSpecID) ~= "number" then
        return 0
    end

    return lootSpecID
end

local function IsTalentLoadoutManagerLoaded()
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        return C_AddOns.IsAddOnLoaded("TalentLoadoutManager") and true or false
    end

    local isAddOnLoaded = rawget(_G, "IsAddOnLoaded")
    return type(isAddOnLoaded) == "function" and isAddOnLoaded("TalentLoadoutManager") or false
end

local function GetTalentLoadoutManagerProvider()
    local tlm = rawget(_G, "TLM")
    if type(tlm) == "table" then
        return tlm
    end

    local provider = rawget(_G, "TalentLoadoutManager")
    if type(provider) == "table" then
        return provider
    end

    return nil
end

local function GetCurrentSpecializationName()
    local specIndex = GetCurrentSpecializationIndex()
    if not specIndex then
        return nil
    end

    local specInfo = GetSpecializationInfoByIndex(specIndex)
    return specInfo and specInfo.name or nil
end

local function IsUsefulLoadoutName(value)
    return type(value) == "string" and value ~= ""
end

local function TryGetLoadoutNameFromTable(tableValue)
    if type(tableValue) ~= "table" then
        return nil
    end

    local currentSpecName = GetCurrentSpecializationName()
    local preferredKeys = {
        "activeLoadoutName",
        "currentLoadoutName",
        "selectedLoadoutName",
        "activeProfileName",
        "currentProfileName",
        "selectedProfileName",
        "activeBuildName",
        "currentBuildName",
        "selectedBuildName",
    }

    for _, key in ipairs(preferredKeys) do
        local value = tableValue[key]
        if IsUsefulLoadoutName(value) and value ~= currentSpecName then
            return value
        end
    end

    for _, nestedValue in pairs(tableValue) do
        if type(nestedValue) == "table" then
            for _, key in ipairs(preferredKeys) do
                local value = nestedValue[key]
                if IsUsefulLoadoutName(value) and value ~= currentSpecName then
                    return value
                end
            end
        end
    end

    return nil
end

local function GetTalentLoadoutNameFromTalentLoadoutManager()
    if not IsTalentLoadoutManagerLoaded() then
        return nil
    end

    local provider = GetTalentLoadoutManagerProvider()
    local activeLoadoutID = nil

    local globalGetActiveLoadoutID = rawget(_G, "GetActiveLoadoutID")
    if type(globalGetActiveLoadoutID) == "function" then
        local okActive, valueActive = pcall(globalGetActiveLoadoutID)
        if okActive and (type(valueActive) == "string" or type(valueActive) == "number") then
            activeLoadoutID = valueActive
        end
    end

    if not activeLoadoutID and type(provider) == "table" and type(provider.GetActiveLoadoutID) == "function" then
        local okActiveMethod, valueActiveMethod = pcall(provider.GetActiveLoadoutID, provider)
        if okActiveMethod and (type(valueActiveMethod) == "string" or type(valueActiveMethod) == "number") then
            activeLoadoutID = valueActiveMethod
        else
            local okActiveStatic, valueActiveStatic = pcall(provider.GetActiveLoadoutID)
            if okActiveStatic and (type(valueActiveStatic) == "string" or type(valueActiveStatic) == "number") then
                activeLoadoutID = valueActiveStatic
            end
        end
    end

    if activeLoadoutID ~= nil then
        local loadoutInfo = nil

        if type(provider) == "table" and type(provider.GetLoadoutByID) == "function" then
            local okLoadoutMethod, valueLoadoutMethod = pcall(provider.GetLoadoutByID, provider, activeLoadoutID)
            if okLoadoutMethod and type(valueLoadoutMethod) == "table" then
                loadoutInfo = valueLoadoutMethod
            else
                local okLoadoutRaw, valueLoadoutRaw = pcall(provider.GetLoadoutByID, provider, activeLoadoutID, false)
                if okLoadoutRaw and type(valueLoadoutRaw) == "table" then
                    loadoutInfo = valueLoadoutRaw
                else
                    local okLoadoutStatic, valueLoadoutStatic = pcall(provider.GetLoadoutByID, activeLoadoutID)
                    if okLoadoutStatic and type(valueLoadoutStatic) == "table" then
                        loadoutInfo = valueLoadoutStatic
                    end
                end
            end
        end

        if not loadoutInfo then
            local globalGetLoadoutByID = rawget(_G, "GetLoadoutByID")
            if type(globalGetLoadoutByID) == "function" then
                local okGlobalLoadout, valueGlobalLoadout = pcall(globalGetLoadoutByID, activeLoadoutID)
                if okGlobalLoadout and type(valueGlobalLoadout) == "table" then
                    loadoutInfo = valueGlobalLoadout
                else
                    local okGlobalLoadoutRaw, valueGlobalLoadoutRaw = pcall(globalGetLoadoutByID, activeLoadoutID, false)
                    if okGlobalLoadoutRaw and type(valueGlobalLoadoutRaw) == "table" then
                        loadoutInfo = valueGlobalLoadoutRaw
                    end
                end
            end
        end

        if type(loadoutInfo) == "table" and IsUsefulLoadoutName(loadoutInfo.displayName) then
            return loadoutInfo.displayName
        end
    end

    if type(provider) == "table" then
        local currentSpecID = GetCurrentSpecializationID()
        local currentSpecIndex = GetCurrentSpecializationIndex()
        local providerMethods = {
            "GetCurrentLoadoutName",
            "GetActiveLoadoutName",
            "GetSelectedLoadoutName",
            "GetCurrentProfileName",
            "GetActiveProfileName",
            "GetSelectedProfileName",
            "GetCurrentBuildName",
            "GetActiveBuildName",
            "GetSelectedBuildName",
        }

        for _, methodName in ipairs(providerMethods) do
            local method = provider[methodName]
            if type(method) == "function" then
                local ok, value = pcall(method, provider)
                if ok and type(value) == "string" and value ~= "" then
                    return value
                end

                if type(currentSpecID) == "number" then
                    local okSpecID, valueSpecID = pcall(method, provider, currentSpecID)
                    if okSpecID and IsUsefulLoadoutName(valueSpecID) then
                        return valueSpecID
                    end
                end

                if type(currentSpecIndex) == "number" then
                    local okSpecIndex, valueSpecIndex = pcall(method, provider, currentSpecIndex)
                    if okSpecIndex and IsUsefulLoadoutName(valueSpecIndex) then
                        return valueSpecIndex
                    end
                end
            end
        end

        local tableResolvedName = TryGetLoadoutNameFromTable(provider)
        if tableResolvedName then
            return tableResolvedName
        end
    end

    local globalFunctions = {
        "TalentLoadoutManager_GetCurrentLoadoutName",
        "TalentLoadoutManager_GetActiveLoadoutName",
        "TalentLoadoutManager_GetSelectedLoadoutName",
        "TalentLoadoutManager_GetCurrentProfileName",
        "TalentLoadoutManager_GetActiveProfileName",
        "TalentLoadoutManager_GetCurrentBuildName",
        "TalentLoadoutManager_GetActiveBuildName",
    }

    local currentSpecID = GetCurrentSpecializationID()
    local currentSpecIndex = GetCurrentSpecializationIndex()

    for _, functionName in ipairs(globalFunctions) do
        local fn = rawget(_G, functionName)
        if type(fn) == "function" then
            local ok, value = pcall(fn)
            if ok and type(value) == "string" and value ~= "" then
                return value
            end

            if type(currentSpecID) == "number" then
                local okSpecID, valueSpecID = pcall(fn, currentSpecID)
                if okSpecID and IsUsefulLoadoutName(valueSpecID) then
                    return valueSpecID
                end
            end

            if type(currentSpecIndex) == "number" then
                local okSpecIndex, valueSpecIndex = pcall(fn, currentSpecIndex)
                if okSpecIndex and IsUsefulLoadoutName(valueSpecIndex) then
                    return valueSpecIndex
                end
            end
        end
    end

    local settingsCandidates = {
        rawget(_G, "TalentLoadoutManagerDB"),
        rawget(_G, "TalentLoadoutManager_DB"),
        rawget(_G, "TalentLoadoutManagerSettings"),
        rawget(_G, "TalentLoadoutManager_Settings"),
    }

    for _, settingsTable in ipairs(settingsCandidates) do
        local resolvedName = TryGetLoadoutNameFromTable(settingsTable)
        if resolvedName then
            return resolvedName
        end
    end

    return nil
end

local function GetTalentLoadoutNameFromBlizzardAPI()
    if not C_ClassTalents then
        return nil
    end

    if C_ClassTalents.GetLastSelectedSavedConfigID then
        local specID = GetCurrentSpecializationID()
        if type(specID) == "number" then
            local selectedConfigID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
            if type(selectedConfigID) == "number" and C_Traits and type(C_Traits.GetConfigInfo) == "function" then
                local selectedConfigInfo = C_Traits.GetConfigInfo(selectedConfigID)
                if type(selectedConfigInfo) == "table" and type(selectedConfigInfo.name) == "string" and selectedConfigInfo.name ~= "" then
                    return selectedConfigInfo.name
                end
            end
        end
    end

    if not (type(C_ClassTalents.GetActiveConfigID) == "function") then
        return nil
    end

    local configID = C_ClassTalents.GetActiveConfigID()
    if type(configID) ~= "number" then
        return nil
    end

    if not (C_Traits and type(C_Traits.GetConfigInfo) == "function") then
        return nil
    end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if type(configInfo) == "table" and type(configInfo.name) == "string" and configInfo.name ~= "" then
        return configInfo.name
    end

    return nil
end

local function GetCurrentLoadoutName()
    if IsTalentLoadoutManagerLoaded() then
        return GetTalentLoadoutNameFromTalentLoadoutManager() or "Unknown"
    end

    return GetTalentLoadoutNameFromBlizzardAPI() or "Unknown"
end

local function TrySetSpecialization(specIndex, specID)
    if type(specIndex) ~= "number" then
        return false
    end

    local inCombatLockdown = rawget(_G, "InCombatLockdown")
    if type(inCombatLockdown) == "function" and inCombatLockdown() then
        return false
    end

    local globalSetSpecialization = rawget(_G, "SetSpecialization")
    if type(globalSetSpecialization) == "function" then
        local ok = pcall(globalSetSpecialization, specIndex)
        if ok then
            return true
        end
    end

    if C_SpecializationInfo and type(C_SpecializationInfo.SetSpecialization) == "function" then
        local okIndex, resultIndex = pcall(C_SpecializationInfo.SetSpecialization, specIndex)
        if okIndex and (resultIndex == nil or resultIndex == true) then
            return true
        end

        if type(specID) == "number" then
            local okID, resultID = pcall(C_SpecializationInfo.SetSpecialization, specID)
            if okID and (resultID == nil or resultID == true) then
                return true
            end
        end
    end

    return false
end

local function GetSetLootSpecializationFunction()
    return rawget(_G, "SetLootSpecialization")
end

local function GetEasyMenuFunction()
    local easyMenu = rawget(_G, "EasyMenu")
    if type(easyMenu) == "function" then
        return easyMenu
    end

    if C_AddOns and type(C_AddOns.LoadAddOn) == "function" then
        pcall(C_AddOns.LoadAddOn, "Blizzard_UIDropDownMenu")
    else
        local loadAddOn = rawget(_G, "LoadAddOn")
        if type(loadAddOn) == "function" then
            pcall(loadAddOn, "Blizzard_UIDropDownMenu")
        end
    end

    easyMenu = rawget(_G, "EasyMenu")
    if type(easyMenu) == "function" then
        return easyMenu
    end

    return nil
end

local function IsRightMouseButton(mouseButton)
    return mouseButton == "RightButton" or mouseButton == "RightButtonUp" or mouseButton == "Button2"
end

local function GetMenuFontInfo()
    local fontSize = 12
    local fontPath = nil

    if addonRef and type(addonRef.GetGlobalMediaConfig) == "function" then
        local cfg = addonRef:GetGlobalMediaConfig() or {}
        if type(cfg.fontSize) == "number" then
            fontSize = cfg.fontSize
        end
        if LSM and type(cfg.font) == "string" and cfg.font ~= "" then
            fontPath = LSM:Fetch("font", cfg.font, true)
        end
    end

    fontPath = fontPath or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    return fontPath, fontSize
end

local function ApplyFallbackMenuFont()
    if not fallbackMenuFrame then
        return
    end

    local fontPath, fontSize = GetMenuFontInfo()
    if fallbackMenuFrame.title then
        fallbackMenuFrame.title:SetFont(fontPath, fontSize)
    end

    for _, button in ipairs(fallbackMenuButtons) do
        if button and button.text then
            button.text:SetFont(fontPath, fontSize)
        end
    end
end

local function EnsureFallbackMenuFrame()
    if fallbackMenuFrame then
        return
    end

    fallbackMenuFrame = CreateFrame("Frame", ADDON_NAME .. "SpecFallbackMenu", UIParent, "BackdropTemplate")
    fallbackMenuFrame:SetFrameStrata("DIALOG")
    fallbackMenuFrame:SetClampedToScreen(true)
    fallbackMenuFrame:SetToplevel(true)
    fallbackMenuFrame:EnableMouse(true)
    fallbackMenuFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    fallbackMenuFrame:SetBackdropColor(0, 0, 0, 0.95)
    fallbackMenuFrame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)

    fallbackMenuFrame.title = fallbackMenuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fallbackMenuFrame.title:SetPoint("TOPLEFT", 10, -10)
    fallbackMenuFrame.title:SetPoint("TOPRIGHT", -10, -10)
    fallbackMenuFrame.title:SetJustifyH("LEFT")

    fallbackMenuFrame:SetScript("OnMouseDown", function(self, mouseButton)
        if IsRightMouseButton(mouseButton) then
            self:Hide()
        end
    end)

    fallbackMenuFrame:SetScript("OnHide", function()
        if fallbackMenuCloseCatcher then
            fallbackMenuCloseCatcher:Hide()
        end
    end)

    fallbackMenuCloseCatcher = CreateFrame("Button", ADDON_NAME .. "SpecFallbackMenuCloseCatcher", UIParent)
    fallbackMenuCloseCatcher:SetFrameStrata("HIGH")
    fallbackMenuCloseCatcher:SetAllPoints(UIParent)
    fallbackMenuCloseCatcher:RegisterForClicks("AnyUp")
    fallbackMenuCloseCatcher:SetScript("OnClick", function()
        if fallbackMenuFrame then
            fallbackMenuFrame:Hide()
        end
    end)
    fallbackMenuCloseCatcher:Hide()

    ApplyFallbackMenuFont()
end

local function EnsureFallbackMenuButton(index)
    EnsureFallbackMenuFrame()

    if fallbackMenuButtons[index] then
        return fallbackMenuButtons[index]
    end

    local button = CreateFrame("Button", nil, fallbackMenuFrame, "BackdropTemplate")
    button:SetHeight(20)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    button:SetBackdropColor(0, 0, 0, 0)
    button:SetBackdropBorderColor(0, 0, 0, 0)
    button:RegisterForClicks("AnyUp")

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.text:SetPoint("LEFT", 8, 0)
    button.text:SetPoint("RIGHT", -8, 0)
    button.text:SetJustifyH("LEFT")

    local fontPath, fontSize = GetMenuFontInfo()
    button.text:SetFont(fontPath, fontSize)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.4, 0.7, 0.35)
    end)

    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0, 0, 0, 0)
    end)

    button:SetScript("OnClick", function(self)
        if fallbackMenuFrame then
            fallbackMenuFrame:Hide()
        end
        if type(self.onClick) == "function" then
            self.onClick()
        end
    end)

    fallbackMenuButtons[index] = button
    return button
end

local function ShowFallbackMenu(title, entries)
    EnsureFallbackMenuFrame()
    local frame = fallbackMenuFrame
    if not frame or not frame.title then
        return
    end

    ApplyFallbackMenuFont()

    frame.title:SetText(title or "Specialization")

    local width = 230
    local topOffset = -30
    local rowHeight = 22

    for index, entry in ipairs(entries) do
        local button = EnsureFallbackMenuButton(index)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, topOffset - ((index - 1) * rowHeight))
        button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, topOffset - ((index - 1) * rowHeight))
        button.onClick = entry.func
        local checkedIcon = "|TInterface\\Buttons\\UI-CheckBox-Check:14:14:0:0|t"
        local uncheckedIcon = "|TInterface\\Buttons\\UI-CheckBox-Up:14:14:0:0|t"
        button.text:SetText((entry.checked and checkedIcon or uncheckedIcon) .. " " .. tostring(entry.text or ""))
        button:Show()
    end

    for index = #entries + 1, #fallbackMenuButtons do
        fallbackMenuButtons[index]:Hide()
    end

    local height = math.max(46, 36 + (#entries * rowHeight))
    frame:SetSize(width, height)

    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local x = cursorX / scale
    local y = cursorY / scale

    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + 8, y - 8)
    if fallbackMenuCloseCatcher then
        fallbackMenuCloseCatcher:Show()
    end
    frame:Show()
end

local function GetDisplayInfo()
    local specIndex = GetCurrentSpecializationIndex()
    local specInfo = specIndex and GetSpecializationInfoByIndex(specIndex) or nil

    local talentSpecID = specInfo and specInfo.id or nil
    local talentSpecIcon = specInfo and specInfo.icon or nil
    local lootSpecID = GetLootSpecializationID()
    local effectiveLootSpecID = lootSpecID
    if effectiveLootSpecID == 0 then
        effectiveLootSpecID = talentSpecID
    end

    local lootIcon
    local getSpecializationInfoByID = rawget(_G, "GetSpecializationInfoByID")
    if effectiveLootSpecID and effectiveLootSpecID ~= talentSpecID and type(getSpecializationInfoByID) == "function" then
        local _, _, _, iconTexture = getSpecializationInfoByID(effectiveLootSpecID)
        lootIcon = iconTexture
    end

    local loadoutName = GetCurrentLoadoutName()
    local textParts = {}

    if talentSpecIcon then
        textParts[#textParts + 1] = "|T" .. tostring(talentSpecIcon) .. ":0|t"
    end

    if lootIcon then
        textParts[#textParts + 1] = "|T" .. tostring(lootIcon) .. ":0|t"
    end

    textParts[#textParts + 1] = loadoutName

    return {
        talentSpecID = talentSpecID,
        talentSpecIndex = specIndex,
        effectiveLootSpecID = effectiveLootSpecID,
        text = table.concat(textParts, " "),
    }
end

local function RefreshDataObject()
    if not dataObject then
        return
    end

    local info = GetDisplayInfo()
    dataObject.icon = nil
    dataObject.text = info.text

    if moduleRef and type(moduleRef.RefreshBars) == "function" then
        moduleRef:RefreshBars()
    end
end

local function ShowTalentSpecializationMenu()
    local specializations = GetClassSpecializations()
    if #specializations == 0 then
        return
    end

    menuFrame = menuFrame or CreateFrame("Frame", ADDON_NAME .. "SpecTalentMenu", UIParent, "UIDropDownMenuTemplate")
    local currentSpecIndex = GetCurrentSpecializationIndex()

    local menu = {
        {
            text = "Specialization",
            isTitle = true,
            notCheckable = true,
        },
    }
    local fallbackEntries = {}

    for _, spec in ipairs(specializations) do
        local entry = {
            text = (spec.icon and ("|T" .. tostring(spec.icon) .. ":0|t ") or "") .. tostring(spec.name),
            checked = spec.index == currentSpecIndex,
            isNotRadio = true,
            func = function()
                local getSpecialization = rawget(_G, "GetSpecialization")
                local canReadCurrentSpec = type(getSpecialization) == "function"
                local shouldSwitch = not canReadCurrentSpec or getSpecialization() ~= spec.index

                if shouldSwitch then
                    local switched = TrySetSpecialization(spec.index, spec.id)
                    if not switched and addonRef then
                        addonRef:Print("Could not switch specialization right now.")
                    end
                end

                C_Timer.After(0.25, function()
                    RefreshDataObject()
                    if canReadCurrentSpec and getSpecialization() ~= spec.index and addonRef then
                        addonRef:Print("Specialization did not change. Make sure you are out of combat and allowed to switch specs.")
                    end
                end)
            end,
        }
        menu[#menu + 1] = entry
        fallbackEntries[#fallbackEntries + 1] = entry
    end

    local easyMenu = GetEasyMenuFunction()
    if easyMenu then
        easyMenu(menu, menuFrame, "cursor", 0, 0, "MENU", 2)
    else
        ShowFallbackMenu("Specialization", fallbackEntries)
    end
end

local function ShowLootSpecializationMenu()
    local specializations = GetClassSpecializations()
    if #specializations == 0 then
        return
    end

    menuFrame = menuFrame or CreateFrame("Frame", ADDON_NAME .. "SpecTalentMenu", UIParent, "UIDropDownMenuTemplate")
    local lootSpecID = GetLootSpecializationID()
    local currentSpecIndex = GetCurrentSpecializationIndex()
    local currentSpecInfo = currentSpecIndex and GetSpecializationInfoByIndex(currentSpecIndex) or nil
    local effectiveLootSpecID = lootSpecID
    if effectiveLootSpecID == 0 and currentSpecInfo then
        effectiveLootSpecID = currentSpecInfo.id
    end

    local menu = {
        {
            text = "Specialization",
            isTitle = true,
            notCheckable = true,
        },
    }
    local fallbackEntries = {}

    for _, spec in ipairs(specializations) do
        local entry = {
            text = (spec.icon and ("|T" .. tostring(spec.icon) .. ":0|t ") or "") .. tostring(spec.name),
            checked = spec.id == effectiveLootSpecID,
            isNotRadio = true,
            func = function()
                local setLootSpecialization = GetSetLootSpecializationFunction()
                local getLootSpecialization = rawget(_G, "GetLootSpecialization")
                if type(setLootSpecialization) == "function" and type(getLootSpecialization) == "function" and getLootSpecialization() ~= spec.id then
                    setLootSpecialization(spec.id)
                end
                C_Timer.After(0.1, RefreshDataObject)
            end,
        }
        menu[#menu + 1] = entry
        fallbackEntries[#fallbackEntries + 1] = entry
    end

    local easyMenu = GetEasyMenuFunction()
    if easyMenu then
        easyMenu(menu, menuFrame, "cursor", 0, 0, "MENU", 2)
    else
        ShowFallbackMenu("Specialization", fallbackEntries)
    end
end

local function RegisterEvents()
    if eventFrame then
        return
    end

    local frame = CreateFrame("Frame")
    eventFrame = frame

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED")
    frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    frame:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")
    frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    frame:RegisterEvent("ADDON_LOADED")

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "ADDON_LOADED" then
            local loadedName = ...
            if loadedName ~= "TalentLoadoutManager" and loadedName ~= ADDON_NAME then
                return
            end
        end

        RefreshDataObject()
    end)
end

local function InitializeBroker(addon, module, ldb)
    if dataObject or not (ldb and type(ldb.NewDataObject) == "function") then
        return brokerName
    end

    addonRef = addon
    moduleRef = module

    dataObject = ldb:NewDataObject(brokerName, {
        type = "data source",
        label = "Specialization",
        text = "",
        icon = nil,
        OnClick = function(_, mouseButton)
            if IsRightMouseButton(mouseButton) then
                ShowLootSpecializationMenu()
            else
                ShowTalentSpecializationMenu()
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip then
                return
            end

            local info = GetDisplayInfo()
            tooltip:AddLine("Specialization")

            local getSpecializationInfoByID = rawget(_G, "GetSpecializationInfoByID")
            if info.talentSpecID and type(getSpecializationInfoByID) == "function" then
                local _, talentSpecName = getSpecializationInfoByID(info.talentSpecID)
                tooltip:AddDoubleLine("Talent", talentSpecName or "Unknown", 0.7, 0.7, 0.7, 1, 1, 1)
            end

            if info.effectiveLootSpecID and type(getSpecializationInfoByID) == "function" then
                local _, lootSpecName = getSpecializationInfoByID(info.effectiveLootSpecID)
                tooltip:AddDoubleLine("Loot", lootSpecName or "Unknown", 0.7, 0.7, 0.7, 1, 1, 1)
            end

            tooltip:AddDoubleLine("Loadout", tostring(GetCurrentLoadoutName()), 0.7, 0.7, 0.7, 1, 1, 1)
            tooltip:AddLine(" ")
            tooltip:AddLine("Left-click: Talent specialization", 0.8, 0.8, 0.8)
            tooltip:AddLine("Right-click: Loot specialization", 0.8, 0.8, 0.8)
        end,
    })

    RegisterEvents()
    RefreshDataObject()

    return brokerName
end

local databrokersModule = addonRef and addonRef:GetModule("databrokers") or (ns.Addon and ns.Addon:GetModule("databrokers"))
if databrokersModule and type(databrokersModule.RegisterCustomBroker) == "function" then
    databrokersModule:RegisterCustomBroker(InitializeBroker)
end
