local ADDON_NAME, ns = ...

local brokerName = "TNT: Audio Device"
local dataObject = nil
local addonRef = nil
local moduleRef = nil
local refreshFrame = nil
local menuFrame = nil
local clickCatcher = nil

local format = string.format
local tonumber = tonumber
local tostring = tostring
local type = type
local GetCVar = GetCVar
local SetCVar = SetCVar

local Sound_GameSystem_GetNumOutputDrivers = Sound_GameSystem_GetNumOutputDrivers
local Sound_GameSystem_GetOutputDriverNameByIndex = Sound_GameSystem_GetOutputDriverNameByIndex
local Sound_GameSystem_RestartSoundSystem = Sound_GameSystem_RestartSoundSystem

local ICON_OUTPUT = "Interface\\COMMON\\VOICECHAT-SPEAKER"

local deviceButtons = {}

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

local function GetAudioDeviceBrokerConfig()
    local databrokers = addonRef and addonRef.db and addonRef.db.databrokers
    local cfg = databrokers and databrokers.audioDeviceBroker
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

local function GetCurrentOutputIndex()
    return tonumber(GetCVar("Sound_OutputDriverIndex") or "0") or 0
end

local function GetOutputDevices()
    local devices = {}

    if type(Sound_GameSystem_GetNumOutputDrivers) == "function" and type(Sound_GameSystem_GetOutputDriverNameByIndex) == "function" then
        local numDevices = tonumber(Sound_GameSystem_GetNumOutputDrivers()) or 0
        for i = 0, numDevices - 1 do
            local name = Sound_GameSystem_GetOutputDriverNameByIndex(i)
            if type(name) ~= "string" or name == "" then
                name = format("Output %d", i + 1)
            end

            devices[#devices + 1] = {
                index = i,
                name = name,
            }
        end
    end

    if #devices == 0 then
        local currentIndex = GetCurrentOutputIndex()
        devices[1] = {
            index = currentIndex,
            name = format("Output %d", currentIndex + 1),
        }
    end

    return devices
end

local function GetCurrentOutputName()
    local currentIndex = GetCurrentOutputIndex()
    local devices = GetOutputDevices()

    for _, device in ipairs(devices) do
        if device.index == currentIndex then
            return device.name
        end
    end

    if devices[1] then
        return devices[1].name
    end

    return "No Output Device"
end

local function BuildText()
    return GetCurrentOutputName()
end

local function RefreshDataObject()
    if not dataObject then
        return
    end

    local cfg = GetAudioDeviceBrokerConfig()
    dataObject.label = ResolveBrokerLabel(cfg.noLabel, cfg.customLabel, "Audio Device")

    if cfg.enabled == false then
        dataObject.text = ""
        dataObject.icon = nil
        if moduleRef and type(moduleRef.RefreshBars) == "function" then
            moduleRef:RefreshBars()
        end
        return
    end

    dataObject.text = BuildText()
    dataObject.icon = ICON_OUTPUT

    if moduleRef and type(moduleRef.RefreshBars) == "function" then
        moduleRef:RefreshBars()
    end
end

local function HideMenu()
    if menuFrame and menuFrame:IsShown() then
        menuFrame:Hide()
    end
end

local function SetOutputDevice(deviceIndex)
    local currentIndex = GetCurrentOutputIndex()
    if currentIndex == deviceIndex then
        return
    end

    SetCVar("Sound_OutputDriverIndex", deviceIndex)

    if type(Sound_GameSystem_RestartSoundSystem) == "function" then
        pcall(Sound_GameSystem_RestartSoundSystem)
    end

    RefreshDataObject()
end

local function CreateDeviceButton(parent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetHeight(24)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.text:SetPoint("LEFT", button, "LEFT", 8, 0)
    button.text:SetPoint("RIGHT", button, "RIGHT", -36, 0)
    button.text:SetJustifyH("LEFT")
    button.text:SetWordWrap(false)

    button.check = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.check:SetPoint("RIGHT", button, "RIGHT", -8, 0)
    button.check:SetText("[ ]")

    button:SetScript("OnClick", function(self)
        if not self.device then
            return
        end

        SetOutputDevice(self.device.index)
        if menuFrame and menuFrame.Rebuild then
            menuFrame:Rebuild()
        end
    end)

    return button
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

    menuFrame = CreateFrame("Frame", ADDON_NAME .. "AudioDeviceBrokerMenu", UIParent, "BackdropTemplate")
    menuFrame:SetSize(320, 120)
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
    menuFrame.title:SetText("Audio Output Device")

    menuFrame.hint = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    menuFrame.hint:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -12, -12)
    menuFrame.hint:SetText("Click a device")

    menuFrame.emptyText = menuFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    menuFrame.emptyText:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 12, -36)
    menuFrame.emptyText:SetText("No output devices found")
    menuFrame.emptyText:Hide()

    function menuFrame:Rebuild()
        local devices = GetOutputDevices()
        local currentIndex = GetCurrentOutputIndex()

        for i = 1, #deviceButtons do
            deviceButtons[i]:Hide()
        end

        if #devices == 0 then
            self.emptyText:Show()
            self:SetHeight(88)
            return
        end

        self.emptyText:Hide()

        local yOffset = -34
        for i, device in ipairs(devices) do
            local button = deviceButtons[i]
            if not button then
                button = CreateDeviceButton(self)
                deviceButtons[i] = button
            end

            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", self, "TOPLEFT", 10, yOffset)
            button:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10, yOffset)
            button.device = device
            button.text:SetText(device.name)

            local isSelected = (device.index == currentIndex)
            if isSelected then
                button.check:SetText("[x]")
                button.text:SetTextColor(0.13, 0.77, 0.37, 1)
                button:SetBackdropColor(0.13, 0.77, 0.37, 0.15)
                button:SetBackdropBorderColor(0.13, 0.77, 0.37, 0.5)
            else
                button.check:SetText("[ ]")
                button.text:SetTextColor(1, 1, 1, 0.9)
                button:SetBackdropColor(0.08, 0.08, 0.08, 0.55)
                button:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.5)
            end

            button:Show()
            yOffset = yOffset - 26
        end

        self:SetHeight(44 + (#devices * 26))
    end

    menuFrame:SetScript("OnShow", function(self)
        clickCatcher:Show()
        clickCatcher:Raise()
        self:Raise()
        self:Rebuild()
    end)

    menuFrame:SetScript("OnHide", function()
        if clickCatcher then
            clickCatcher:Hide()
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

    tooltip:AddLine("Audio Device")
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine("Current Output", GetCurrentOutputName(), 0.8, 0.8, 0.8, 1, 1, 1)
    tooltip:AddLine(" ")
    tooltip:AddLine("Left-click: Open/close device menu", 0.8, 0.8, 0.8)
    tooltip:AddLine("Right-click: Open/close device menu", 0.8, 0.8, 0.8)
end

local function InitializeBroker(addon, module, ldb)
    if dataObject or not (ldb and type(ldb.NewDataObject) == "function") then
        return brokerName
    end

    addonRef = addon
    moduleRef = module

    dataObject = ldb:NewDataObject(brokerName, {
        type = "data source",
        label = "Audio Device",
        text = "",
        icon = ICON_OUTPUT,
        OnClick = function(self, button)
            if button == "LeftButton" or button == "RightButton" then
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
