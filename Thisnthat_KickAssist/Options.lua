local ADDON_NAME, ns = ...

local Addon = ns.Addon
if not Addon then
    return
end

local UIDropDownMenu_Initialize = rawget(_G, "UIDropDownMenu_Initialize")
local UIDropDownMenu_CreateInfo = rawget(_G, "UIDropDownMenu_CreateInfo")
local UIDropDownMenu_AddButton = rawget(_G, "UIDropDownMenu_AddButton")
local UIDropDownMenu_SetSelectedValue = rawget(_G, "UIDropDownMenu_SetSelectedValue")
local UIDropDownMenu_SetText = rawget(_G, "UIDropDownMenu_SetText")
local UIDropDownMenu_SetWidth = rawget(_G, "UIDropDownMenu_SetWidth")

local COLORS = {
    bg = { r = 0.07, g = 0.09, b = 0.11, a = 0.97 },
    panel = { r = 0.11, g = 0.14, b = 0.17, a = 0.98 },
    border = { r = 0.18, g = 0.24, b = 0.30, a = 1 },
    accent = { r = 0.78, g = 0.23, b = 0.30, a = 1 },
    text = { r = 0.93, g = 0.94, b = 0.96, a = 1 },
    subtext = { r = 0.68, g = 0.70, b = 0.74, a = 1 },
}

local optionsFrame = nil
local copyDialog = nil
local controls = {}

local function ApplyBackdrop(frame, bgColor, borderColor)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    frame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
end

local function CreateLabel(parent, text, template, color, width)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    label:SetText(text or "")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    if width then
        label:SetWidth(width)
    end
    if color then
        label:SetTextColor(color.r, color.g, color.b, color.a)
    end
    return label
end

local function CreateEditBox(parent, width, height, multiLine)
    local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    ApplyBackdrop(edit, { r = 0.05, g = 0.05, b = 0.05, a = 0.95 }, { r = COLORS.border.r, g = COLORS.border.g, b = COLORS.border.b, a = 0.75 })
    edit:SetSize(width, height)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetTextColor(COLORS.text.r, COLORS.text.g, COLORS.text.b, COLORS.text.a)
    edit:SetTextInsets(8, 8, 8, 8)
    edit:SetMultiLine(multiLine and true or false)
    edit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    return edit
end

local function CreateReadOnlyEditBox(parent, width, height, multiLine)
    local edit = CreateEditBox(parent, width, height, multiLine)
    edit:EnableMouse(false)
    edit:ClearFocus()

    function edit:SetReadOnlyText(value)
        self._readOnlyText = value or ""
        self._settingReadOnlyText = true
        self:SetText(self._readOnlyText)
        self._settingReadOnlyText = false
        self:ClearFocus()
    end

    return edit
end

local function CreateActionButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    ApplyBackdrop(button, { r = 0.18, g = 0.24, b = 0.30, a = 0.9 }, { r = COLORS.border.r, g = COLORS.border.g, b = COLORS.border.b, a = 1 })
    button:SetSize(width or 160, height or 24)

    local label = CreateLabel(button, text, "GameFontNormalSmall", COLORS.text)
    label:SetPoint("CENTER")
    button.label = label

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(COLORS.accent.r, COLORS.accent.g, COLORS.accent.b, 0.35)
        self:SetBackdropBorderColor(COLORS.accent.r, COLORS.accent.g, COLORS.accent.b, 1)
        self.label:SetTextColor(COLORS.accent.r, COLORS.accent.g, COLORS.accent.b, 1)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.18, 0.24, 0.30, 0.9)
        self:SetBackdropBorderColor(COLORS.border.r, COLORS.border.g, COLORS.border.b, 1)
        self.label:SetTextColor(COLORS.text.r, COLORS.text.g, COLORS.text.b, COLORS.text.a)
    end)

    return button
end

local function CreateCheckButton(parent, text)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check.text = CreateLabel(parent, text, "GameFontNormalSmall", COLORS.text)
    check.text:SetPoint("LEFT", check, "RIGHT", 4, 0)
    return check
end

local function ShowCopyDialog(titleText, bodyText)
    if not copyDialog then
        copyDialog = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        copyDialog:SetSize(560, 220)
        copyDialog:SetPoint("CENTER")
        copyDialog:SetFrameStrata("FULLSCREEN_DIALOG")
        copyDialog:SetToplevel(true)
        copyDialog:SetMovable(true)
        copyDialog:EnableMouse(true)
        copyDialog:RegisterForDrag("LeftButton")
        copyDialog:SetScript("OnDragStart", copyDialog.StartMoving)
        copyDialog:SetScript("OnDragStop", copyDialog.StopMovingOrSizing)
        copyDialog:SetClampedToScreen(true)
        ApplyBackdrop(copyDialog, COLORS.bg, { r = COLORS.accent.r, g = COLORS.accent.g, b = COLORS.accent.b, a = 1 })

        copyDialog.title = CreateLabel(copyDialog, "", "GameFontNormal", COLORS.accent)
        copyDialog.title:SetPoint("TOPLEFT", copyDialog, "TOPLEFT", 12, -12)

        copyDialog.desc = CreateLabel(copyDialog, "Press Ctrl+C after the text is highlighted.", "GameFontDisableSmall", COLORS.subtext, 530)
        copyDialog.desc:SetPoint("TOPLEFT", copyDialog.title, "BOTTOMLEFT", 0, -6)

        copyDialog.edit = CreateEditBox(copyDialog, 536, 128, true)
        copyDialog.edit:SetPoint("TOPLEFT", copyDialog.desc, "BOTTOMLEFT", 0, -8)

        copyDialog.close = CreateActionButton(copyDialog, "Close", 88, 24)
        copyDialog.close:SetPoint("BOTTOMRIGHT", copyDialog, "BOTTOMRIGHT", -12, 12)
        copyDialog.close:SetScript("OnClick", function()
            copyDialog:Hide()
        end)

        copyDialog:SetScript("OnShow", function(self)
            self.edit:SetFocus()
            self.edit:HighlightText(0)
        end)
    end

    copyDialog.title:SetText(titleText or "Copy Macro")
    copyDialog.edit:SetText(bodyText or "")
    copyDialog:Raise()
    copyDialog:Show()
end

local function SetDropdownValue(dropdown, items, selectedValue, onSelect)
    if type(UIDropDownMenu_Initialize) ~= "function"
        or type(UIDropDownMenu_CreateInfo) ~= "function"
        or type(UIDropDownMenu_AddButton) ~= "function"
        or type(UIDropDownMenu_SetSelectedValue) ~= "function"
        or type(UIDropDownMenu_SetText) ~= "function" then
        return
    end

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        if level ~= 1 then
            return
        end

        for _, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.label
            info.value = item.value
            info.notCheckable = true
            info.func = function()
                UIDropDownMenu_SetSelectedValue(dropdown, item.value)
                UIDropDownMenu_SetText(dropdown, item.label)
                if onSelect then
                    onSelect(item.value)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    for _, item in ipairs(items) do
        if item.value == selectedValue then
            UIDropDownMenu_SetSelectedValue(dropdown, item.value)
            UIDropDownMenu_SetText(dropdown, item.label)
            if dropdown.Text then
                dropdown.Text:SetWidth(180)
            end
            return
        end
    end
end

local function BuildOptionsFrame()
    if optionsFrame then
        return optionsFrame
    end

    optionsFrame = CreateFrame("Frame", "ThisnthatKickAssistOptionsFrame", UIParent, "BackdropTemplate")
    optionsFrame:SetSize(680, 760)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetFrameStrata("DIALOG")
    optionsFrame:SetMovable(true)
    optionsFrame:EnableMouse(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
    optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
    ApplyBackdrop(optionsFrame, COLORS.bg, COLORS.border)
    optionsFrame:Hide()

    local title = CreateLabel(optionsFrame, "Thisnthat Kick Assist", "GameFontNormalLarge", COLORS.accent)
    title:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 16, -14)

    local subtitle = CreateLabel(optionsFrame, "Standalone kick coordination, macro helpers, and ready-check announcements.", "GameFontDisableSmall", COLORS.subtext, 640)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)

    local closeButton = CreateActionButton(optionsFrame, "Close", 88, 24)
    closeButton:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -14, -14)
    closeButton:SetScript("OnClick", function()
        optionsFrame:Hide()
    end)

    local content = CreateFrame("Frame", nil, optionsFrame)
    content:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -14)
    content:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -16, 16)

    local markerLabel = CreateLabel(content, "Kick Marker", "GameFontNormalSmall", COLORS.text)
    markerLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)

    local markerDropDown = CreateFrame("Frame", "ThisnthatKickAssistMarkerDropDown", content, "UIDropDownMenuTemplate")
    markerDropDown:SetPoint("TOPLEFT", markerLabel, "BOTTOMLEFT", -16, -2)
    if type(UIDropDownMenu_SetWidth) == "function" then
        UIDropDownMenu_SetWidth(markerDropDown, 200)
    end
    controls.markerDropDown = markerDropDown

    local interruptLabel = CreateLabel(content, "Interrupt Ability", "GameFontNormalSmall", COLORS.text)
    interruptLabel:SetPoint("TOPLEFT", markerDropDown, "BOTTOMLEFT", 16, -18)

    local interruptDropDown = CreateFrame("Frame", "ThisnthatKickAssistInterruptDropDown", content, "UIDropDownMenuTemplate")
    interruptDropDown:SetPoint("TOPLEFT", interruptLabel, "BOTTOMLEFT", -16, -2)
    if type(UIDropDownMenu_SetWidth) == "function" then
        UIDropDownMenu_SetWidth(interruptDropDown, 200)
    end
    controls.interruptDropDown = interruptDropDown

    local minimapLabel = CreateLabel(content, "Minimap Button", "GameFontNormalSmall", COLORS.text)
    minimapLabel:SetPoint("TOPLEFT", interruptDropDown, "BOTTOMLEFT", 16, -18)

    controls.minimapCheck = CreateCheckButton(content, "Show minimap button")
    controls.minimapCheck:SetPoint("TOPLEFT", minimapLabel, "BOTTOMLEFT", 0, -6)

    local kickLabel = CreateLabel(content, "Kick Macro", "GameFontNormal", COLORS.accent)
    kickLabel:SetPoint("TOPLEFT", controls.minimapCheck, "BOTTOMLEFT", 0, -22)

    controls.kickPreview = CreateReadOnlyEditBox(content, 640, 52, true)
    controls.kickPreview:SetPoint("TOPLEFT", kickLabel, "BOTTOMLEFT", 0, -8)

    controls.copyKickButton = CreateActionButton(content, "Copy Kick Macro Text", 200, 24)
    controls.copyKickButton:SetPoint("TOPLEFT", controls.kickPreview, "BOTTOMLEFT", 0, -8)

    controls.createKickButton = CreateActionButton(content, "Create TNT: Kick Macro", 200, 24)
    controls.createKickButton:SetPoint("LEFT", controls.copyKickButton, "RIGHT", 8, 0)

    local focusLabel = CreateLabel(content, "Focus + Mark Macro", "GameFontNormal", COLORS.accent)
    focusLabel:SetPoint("TOPLEFT", controls.copyKickButton, "BOTTOMLEFT", 0, -22)

    controls.focusPreview = CreateReadOnlyEditBox(content, 640, 52, true)
    controls.focusPreview:SetPoint("TOPLEFT", focusLabel, "BOTTOMLEFT", 0, -8)

    controls.copyFocusButton = CreateActionButton(content, "Copy Focus Macro Text", 200, 24)
    controls.copyFocusButton:SetPoint("TOPLEFT", controls.focusPreview, "BOTTOMLEFT", 0, -8)

    controls.createFocusButton = CreateActionButton(content, "Create TNT: Focus Macro", 200, 24)
    controls.createFocusButton:SetPoint("LEFT", controls.copyFocusButton, "RIGHT", 8, 0)

    controls.announceCheck = CreateCheckButton(content, "Announce kick target in party on ready check")
    controls.announceCheck:SetPoint("TOPLEFT", controls.copyFocusButton, "BOTTOMLEFT", -2, -24)

    local announceMessageLabel = CreateLabel(content, "Announcement Message", "GameFontNormalSmall", COLORS.text)
    announceMessageLabel:SetPoint("TOPLEFT", controls.announceCheck, "BOTTOMLEFT", 2, -18)

    controls.announceMessageEdit = CreateEditBox(content, 640, 28, false)
    controls.announceMessageEdit:SetPoint("TOPLEFT", announceMessageLabel, "BOTTOMLEFT", 0, -6)

    controls.announcePreview = CreateLabel(content, "", "GameFontDisableSmall", COLORS.subtext, 640)
    controls.announcePreview:SetPoint("TOPLEFT", controls.announceMessageEdit, "BOTTOMLEFT", 2, -8)

    local scopesLabel = CreateLabel(content, "Announce In", "GameFontNormalSmall", COLORS.text)
    scopesLabel:SetPoint("TOPLEFT", controls.announcePreview, "BOTTOMLEFT", -2, -18)

    controls.mplusCheck = CreateCheckButton(content, "M+")
    controls.mplusCheck:SetPoint("TOPLEFT", scopesLabel, "BOTTOMLEFT", 0, -6)

    controls.mythicCheck = CreateCheckButton(content, "Mythic Dungeons")
    controls.mythicCheck:SetPoint("LEFT", controls.mplusCheck, "LEFT", 220, 0)

    controls.heroicCheck = CreateCheckButton(content, "Heroic Dungeons")
    controls.heroicCheck:SetPoint("TOPLEFT", controls.mplusCheck, "BOTTOMLEFT", 0, -8)

    controls.normalCheck = CreateCheckButton(content, "Normal Dungeons")
    controls.normalCheck:SetPoint("LEFT", controls.heroicCheck, "LEFT", 220, 0)

    return optionsFrame
end

local function RefreshOptions()
    BuildOptionsFrame()
    local cfg = Addon:GetConfig()

    SetDropdownValue(controls.markerDropDown, (function()
        local items = {}
        for _, marker in ipairs(Addon:GetRaidMarkers()) do
            local icon = Addon:GetMarkerTextureTag(marker.index, 14)
            items[#items + 1] = {
                value = marker.index,
                label = (icon ~= "" and (icon .. " ") or "") .. marker.name,
            }
        end
        return items
    end)(), cfg.markerIndex, function(value)
        cfg.markerIndex = tonumber(value) or 0
        RefreshOptions()
    end)

    SetDropdownValue(controls.interruptDropDown, Addon:GetInterruptSpellChoices(), cfg.interruptSpell or "AUTO", function(value)
        cfg.interruptSpell = type(value) == "string" and value or "AUTO"
        RefreshOptions()
    end)

    controls.kickPreview:SetReadOnlyText(Addon:BuildKickMacro())
    controls.focusPreview:SetReadOnlyText(Addon:BuildFocusMacro())
    controls.announceCheck:SetChecked(cfg.announceOnReadyCheck)
    controls.announceMessageEdit:SetText(cfg.announceTemplate)
    controls.mplusCheck:SetChecked(cfg.announceInMythicPlus)
    controls.mythicCheck:SetChecked(cfg.announceInMythicDungeon)
    controls.heroicCheck:SetChecked(cfg.announceInHeroicDungeon)
    controls.normalCheck:SetChecked(cfg.announceInNormalDungeon)
    controls.minimapCheck:SetChecked(cfg.hideMinimapButton ~= true)

    local markerTexture = Addon:GetMarkerTextureTag(cfg.markerIndex, 14)
    if markerTexture == "" then
        controls.announcePreview:SetText("No ready check message will be sent while marker is set to None.")
    else
        controls.announcePreview:SetText("Preview: " .. string.gsub(cfg.announceTemplate, "{RAIDMARKER}", markerTexture))
    end
end

function ns:IsOptionsFrameShown()
    return optionsFrame and optionsFrame:IsShown() or false
end

function ns:HideOptionsFrame()
    if optionsFrame then
        optionsFrame:Hide()
    end
end

function ns:RefreshOptionsFrame()
    if optionsFrame and optionsFrame:IsShown() then
        RefreshOptions()
    end
end

function ns:OpenOptionsFrame()
    local frame = BuildOptionsFrame()

    controls.copyKickButton:SetScript("OnClick", function()
        ShowCopyDialog("Copy Kick Macro", Addon:BuildKickMacro())
    end)
    controls.createKickButton:SetScript("OnClick", function()
        Addon:CreateKickMacro()
    end)
    controls.copyFocusButton:SetScript("OnClick", function()
        ShowCopyDialog("Copy Focus Macro", Addon:BuildFocusMacro())
    end)
    controls.createFocusButton:SetScript("OnClick", function()
        Addon:CreateFocusMacro()
    end)

    controls.announceCheck:SetScript("OnClick", function(self)
        Addon:GetConfig().announceOnReadyCheck = self:GetChecked() and true or false
    end)
    controls.announceMessageEdit:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        if type(text) ~= "string" or text == "" then
            text = "My Kick target is {RAIDMARKER}"
        end
        Addon:GetConfig().announceTemplate = text
        RefreshOptions()
        self:ClearFocus()
    end)
    controls.announceMessageEdit:SetScript("OnEscapePressed", function(self)
        RefreshOptions()
        self:ClearFocus()
    end)

    controls.mplusCheck:SetScript("OnClick", function(self)
        Addon:GetConfig().announceInMythicPlus = self:GetChecked() and true or false
    end)
    controls.mythicCheck:SetScript("OnClick", function(self)
        Addon:GetConfig().announceInMythicDungeon = self:GetChecked() and true or false
    end)
    controls.heroicCheck:SetScript("OnClick", function(self)
        Addon:GetConfig().announceInHeroicDungeon = self:GetChecked() and true or false
    end)
    controls.normalCheck:SetScript("OnClick", function(self)
        Addon:GetConfig().announceInNormalDungeon = self:GetChecked() and true or false
    end)
    controls.minimapCheck:SetScript("OnClick", function(self)
        local cfg = Addon:GetConfig()
        cfg.hideMinimapButton = not self:GetChecked()
        if type(Addon.UpdateMinimapButton) == "function" then
            Addon:UpdateMinimapButton()
        end
    end)

    RefreshOptions()
    if frame and type(frame.Show) == "function" then
        frame:Show()
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, loadedName)
    if loadedName ~= ADDON_NAME then
        return
    end

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local panel = CreateFrame("Frame")
        panel.name = ADDON_NAME

        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText(ADDON_NAME)

        local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
        desc:SetText("Type /tntkick or click the button below to open Kick Assist options.")
        desc:SetTextColor(0.67, 0.67, 0.67, 1)

        local button = CreateActionButton(panel, "Open Kick Assist", 180, 24)
        button:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -14)
        button:SetScript("OnClick", function()
            ns:OpenOptionsFrame()
        end)

        local category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_NAME)
        Settings.RegisterAddOnCategory(category)
    end

    loader:UnregisterEvent("ADDON_LOADED")
end)