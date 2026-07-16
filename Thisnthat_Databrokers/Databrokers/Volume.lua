local ADDON_NAME, ns = ...

local brokerName = "TNT: Volume"
local dataObject = nil
local addonRef = nil
local moduleRef = nil
local refreshFrame = nil
local menuFrame = nil
local clickCatcher = nil

local floor = math.floor
local format = string.format
local min = math.min
local max = math.max
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local GetCVar = GetCVar
local SetCVar = SetCVar

local CHANNELS = {
    { key = "master", label = "Master", cvar = "Sound_MasterVolume" },
    { key = "effects", label = "Effects", cvar = "Sound_SFXVolume" },
    { key = "music", label = "Music", cvar = "Sound_MusicVolume" },
    { key = "ambience", label = "Ambience", cvar = "Sound_AmbienceVolume" },
    { key = "dialog", label = "Dialog", cvar = "Sound_DialogVolume" },
}

local rowsByKey = {}
local COLOR_GREEN = "|cff00ff00"
local COLOR_WHITE = "|cffffffff"
local COLOR_RED = "|cffff2020"
local COLOR_RESET = "|r"
local ICON_VOLUME = "Interface\\COMMON\\VOICECHAT-SPEAKER"
local ICON_MUTED = "Interface\\COMMON\\VOICECHAT-MUTED"

local function ResolveBrokerLabel(noLabel, customLabel, fallback)
    if noLabel then
        return ""
    end

    local label = type(customLabel) == "string" and string.match(customLabel, "^%s*(.-)%s*$") or ""
    if label == "" then
        return fallback
    end

    return label
end

local function ClampPercent(value)
    local numberValue = tonumber(value)
    if not numberValue then
        return 0
    end

    numberValue = floor(numberValue + 0.5)
    return min(100, max(0, numberValue))
end

local function GetVolumeBrokerConfig()
    local databrokers = addonRef and addonRef.db and addonRef.db.databrokers
    local cfg = databrokers and databrokers.volumeBroker
    if type(cfg) ~= "table" then
        return {
            enabled = true,
            noLabel = false,
            customLabel = "",
        }
    end

    return {
        enabled = cfg.enabled ~= false,
        noLabel = cfg.noLabel and true or false,
        customLabel = type(cfg.customLabel) == "string" and cfg.customLabel or "",
    }
end

local function IsMuted()
    return tostring(GetCVar("Sound_EnableAllSound") or "1") == "0"
end

local function ToggleMute()
    if IsMuted() then
        SetCVar("Sound_EnableAllSound", "1")
    else
        SetCVar("Sound_EnableAllSound", "0")
    end
end

local function GetVolumePercent(cvarName)
    local rawValue = tonumber(GetCVar(cvarName) or "0") or 0
    return ClampPercent(rawValue * 100)
end

local function SetVolumePercent(cvarName, percent)
    local clamped = ClampPercent(percent)
    SetCVar(cvarName, clamped / 100)
    return clamped
end

local function BuildText()
    if IsMuted() then
        return COLOR_RED .. "Muted" .. COLOR_RESET
    end

    local master = GetVolumePercent("Sound_MasterVolume")
    return COLOR_GREEN .. format("%d", master) .. COLOR_RESET .. COLOR_WHITE .. "%" .. COLOR_RESET
end

local function RefreshDataObject()
    if not dataObject then
        return
    end

    local cfg = GetVolumeBrokerConfig()
    dataObject.label = ResolveBrokerLabel(cfg.noLabel, cfg.customLabel, "Volume")
    if cfg.enabled == false then
        dataObject.text = ""
        dataObject.icon = nil
        if moduleRef and type(moduleRef.RefreshBars) == "function" then
            moduleRef:RefreshBars()
        end
        return
    end

    dataObject.text = BuildText()
    dataObject.icon = IsMuted() and ICON_MUTED or ICON_VOLUME

    if moduleRef and type(moduleRef.RefreshBars) == "function" then
        moduleRef:RefreshBars()
    end
end

local function HideMenu()
    if menuFrame and menuFrame:IsShown() then
        menuFrame:Hide()
    end
end

local function SyncRowsFromCVars()
    for _, channel in ipairs(CHANNELS) do
        local row = rowsByKey[channel.key]
        if row then
            local value = GetVolumePercent(channel.cvar)
            row.isSyncing = true
            row.slider:SetValue(value)
            row.editBox:SetText(tostring(value))
            row.isSyncing = false
        end
    end
end

local function ApplyRowValue(row, rawValue)
    if not row then
        return
    end

    local value = ClampPercent(rawValue)
    row.isSyncing = true
    row.slider:SetValue(value)
    row.editBox:SetText(tostring(value))
    row.isSyncing = false

    SetVolumePercent(row.channel.cvar, value)
    if row.channel.key == "master" then
        RefreshDataObject()
    end
end

local function CreateVolumeRow(parent, channel, yOffset)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(260, 42)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    row.channel = channel

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.label:SetText(channel.label)

    row.slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
    row.slider:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -14)
    row.slider:SetSize(182, 18)
    row.slider:SetMinMaxValues(0, 100)
    row.slider:SetValueStep(1)
    row.slider:SetObeyStepOnDrag(true)
    row.slider:EnableMouseWheel(true)

    row.editBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    row.editBox:SetPoint("LEFT", row.slider, "RIGHT", 10, 0)
    row.editBox:SetSize(42, 20)
    row.editBox:SetAutoFocus(false)
    row.editBox:SetNumeric(true)
    row.editBox:SetMaxLetters(3)

    row.percentLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.percentLabel:SetPoint("LEFT", row.editBox, "RIGHT", 4, 0)
    row.percentLabel:SetText("%")

    row.slider:SetScript("OnValueChanged", function(self, value)
        if row.isSyncing then
            return
        end

        ApplyRowValue(row, value)
    end)

    row.slider:SetScript("OnMouseWheel", function(self, delta)
        local current = ClampPercent(self:GetValue())
        if delta > 0 then
            ApplyRowValue(row, current + 1)
        else
            ApplyRowValue(row, current - 1)
        end
    end)

    local function CommitEditBoxValue()
        ApplyRowValue(row, row.editBox:GetText())
        row.editBox:ClearFocus()
    end

    row.editBox:SetScript("OnEnterPressed", CommitEditBoxValue)
    row.editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        row.editBox:SetText(tostring(GetVolumePercent(channel.cvar)))
    end)
    row.editBox:SetScript("OnEditFocusLost", CommitEditBoxValue)

    rowsByKey[channel.key] = row
    return row
end

local function EnsureMenuFrame()
    if menuFrame then
        return
    end

    clickCatcher = CreateFrame("Frame", nil, UIParent)
    clickCatcher:SetAllPoints(UIParent)
    clickCatcher:SetFrameStrata("TOOLTIP")
    clickCatcher:SetFrameLevel(9)
    clickCatcher:EnableMouse(true)
    clickCatcher:Hide()
    clickCatcher:SetScript("OnMouseDown", function()
        HideMenu()
    end)

    menuFrame = CreateFrame("Frame", ADDON_NAME .. "VolumeBrokerMenu", UIParent, "BackdropTemplate")
    menuFrame:SetSize(280, 42 + (#CHANNELS * 44))
    menuFrame:SetFrameStrata("TOOLTIP")
    menuFrame:SetFrameLevel(10)
    menuFrame:SetClampedToScreen(true)
    menuFrame:EnableMouse(true)
    menuFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    menuFrame:SetBackdropColor(0, 0, 0, 0.95)
    menuFrame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    menuFrame:Hide()

    menuFrame.title = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    menuFrame.title:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 12, -10)
    menuFrame.title:SetText("Volume")

    menuFrame.hint = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    menuFrame.hint:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -12, -12)
    menuFrame.hint:SetText("Right-click to close")

    local y = -30
    for _, channel in ipairs(CHANNELS) do
        CreateVolumeRow(menuFrame, channel, y)
        y = y - 44
    end

    menuFrame:SetScript("OnShow", function(self)
        clickCatcher:Show()
        clickCatcher:Raise()
        self:Raise()
        SyncRowsFromCVars()
    end)

    menuFrame:SetScript("OnHide", function()
        if clickCatcher then
            clickCatcher:Hide()
        end

        for _, row in pairs(rowsByKey) do
            row.editBox:ClearFocus()
        end
    end)

    local specialFrames = rawget(_G, "UISpecialFrames")
    if type(specialFrames) == "table" then
        specialFrames[#specialFrames + 1] = menuFrame:GetName()
    end
end

local function ToggleMenu(anchor)
    EnsureMenuFrame()
    if not menuFrame then
        return
    end

    if menuFrame:IsShown() then
        HideMenu()
        return
    end

    menuFrame:ClearAllPoints()
    menuFrame:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -6)
    menuFrame:Show()
end

local function EnsureRefreshFrame()
    if refreshFrame then
        return
    end

    refreshFrame = CreateFrame("Frame")
    refreshFrame.elapsed = 0
    refreshFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.5 then
            return
        end

        self.elapsed = 0
        RefreshDataObject()
    end)
end

local function BuildTooltip(tooltip)
    if not tooltip then
        return
    end

    tooltip:AddLine("Volume")
    tooltip:AddLine(" ")

    if IsMuted() then
        tooltip:AddLine("All sound is muted", 1, 0.25, 0.25)
    else
        for _, channel in ipairs(CHANNELS) do
            tooltip:AddDoubleLine(channel.label, format("%d%%", GetVolumePercent(channel.cvar)), 0.8, 0.8, 0.8, 1, 1, 1)
        end
    end

    tooltip:AddLine(" ")
    tooltip:AddLine("Left-click: Toggle mute", 0.8, 0.8, 0.8)
    tooltip:AddLine("Right-click: Open/close volume menu", 0.8, 0.8, 0.8)
end

local function InitializeBroker(addon, module, ldb)
    if dataObject or not (ldb and type(ldb.NewDataObject) == "function") then
        return brokerName
    end

    addonRef = addon
    moduleRef = module

    dataObject = ldb:NewDataObject(brokerName, {
        type = "data source",
        label = "Volume",
        text = "",
        icon = nil,
        OnClick = function(self, button)
            if button == "LeftButton" then
                ToggleMute()
                HideMenu()
                RefreshDataObject()
                return
            end

            if button == "RightButton" then
                ToggleMenu(self)
                RefreshDataObject()
            end
        end,
        OnTooltipShow = function(tooltip)
            BuildTooltip(tooltip)
        end,
    })

    EnsureMenuFrame()
    EnsureRefreshFrame()
    RefreshDataObject()

    if moduleRef and type(moduleRef.RegisterBrokerRefresher) == "function" then
        moduleRef:RegisterBrokerRefresher(RefreshDataObject)
    end

    return brokerName
end

local databrokersRegistry = type(ns) == "table" and ns.DataBrokers or nil
if databrokersRegistry and type(databrokersRegistry.RegisterBroker) == "function" then
    databrokersRegistry:RegisterBroker(InitializeBroker)
end
