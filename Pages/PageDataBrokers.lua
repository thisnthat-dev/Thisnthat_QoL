local ADDON_NAME, ns = ...

local W
local C

local BROKER_DEFINITIONS = {
    {
        key = "clockBroker",
        name = "TNT: Clock",
        label = "Clock",
        description = "Configure the clock broker's time source and display format.",
    },
    {
        key = "durabilityColors",
        name = "TNT: Durability",
        label = "Durability",
        description = "Durability colors are fixed to red/yellow/green thresholds.",
    },
    {
        key = "systemBroker",
        name = "TNT: System",
        label = "System",
        description = "System colors are fixed to red/yellow/green thresholds.",
    },
    {
        key = "specializationBroker",
        name = "TNT: Specialization",
        label = "Specialization",
        description = "Configure specialization broker visibility and icon behavior.",
    },
    {
        key = "volumeBroker",
        name = "TNT: Volume",
        label = "Volume",
        description = "Configure volume broker visibility and label settings.",
    },
    {
        key = "audioDeviceBroker",
        name = "TNT: Audio Device",
        label = "Audio Device",
        description = "Configure audio device broker visibility and label settings.",
    },
}

local CLOCK_DEFAULTS = {
    useServerTime = false,
    use24Hour = false,
}

local function IsDatabrokersAddonLoaded()
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        return C_AddOns.IsAddOnLoaded("Thisnthat_Databrokers") and true or false
    end

    local isAddOnLoaded = rawget(_G, "IsAddOnLoaded")
    if type(isAddOnLoaded) == "function" then
        return isAddOnLoaded("Thisnthat_Databrokers") and true or false
    end

    return false
end

local function GetStandaloneAddon()
    return rawget(_G, "Thisnthat_Databrokers_Addon")
end

local function GetStandaloneDBRoot()
    Thisnthat_DatabrokersDB = type(Thisnthat_DatabrokersDB) == "table" and Thisnthat_DatabrokersDB or {}
    Thisnthat_DatabrokersDB.databrokers = type(Thisnthat_DatabrokersDB.databrokers) == "table" and Thisnthat_DatabrokersDB.databrokers or {}
    return Thisnthat_DatabrokersDB
end

local function SyncStandaloneAddonDB()
    local standaloneAddon = GetStandaloneAddon()
    if standaloneAddon then
        standaloneAddon.db = GetStandaloneDBRoot()
    end
end

local function NormalizeCustomLabel(value)
    if type(value) ~= "string" then
        return ""
    end

    local trimmed = string.match(value, "^%s*(.-)%s*$") or ""
    return trimmed
end

local function ResolveBrokerKey(value)
    if type(value) ~= "string" or value == "" then
        return nil
    end

    for _, def in ipairs(BROKER_DEFINITIONS) do
        if value == def.key or value == def.name then
            return def.key
        end
    end

    return nil
end

local function EnsureClockConfig(db)
    db.clockBroker = type(db.clockBroker) == "table" and db.clockBroker or {}
    db.clockBroker.enabled = db.clockBroker.enabled ~= false
    db.clockBroker.noLabel = db.clockBroker.noLabel and true or false
    db.clockBroker.customLabel = NormalizeCustomLabel(db.clockBroker.customLabel)
    db.clockBroker.useServerTime = db.clockBroker.useServerTime and true or false
    db.clockBroker.use24Hour = db.clockBroker.use24Hour and true or false
    return db.clockBroker
end

local function EnsureDurabilityConfig(db)
    db.durabilityColors = type(db.durabilityColors) == "table" and db.durabilityColors or {}
    db.durabilityColors.enabled = db.durabilityColors.enabled ~= false
    db.durabilityColors.noLabel = db.durabilityColors.noLabel and true or false
    db.durabilityColors.customLabel = NormalizeCustomLabel(db.durabilityColors.customLabel)
    db.durabilityColors.ok = nil
    db.durabilityColors.warning = nil
    db.durabilityColors.critical = nil
    return db.durabilityColors
end

local function EnsureSystemConfig(db)
    db.systemBroker = type(db.systemBroker) == "table" and db.systemBroker or {}
    db.systemBroker.enabled = db.systemBroker.enabled ~= false
    db.systemBroker.noLabel = db.systemBroker.noLabel and true or false
    db.systemBroker.customLabel = NormalizeCustomLabel(db.systemBroker.customLabel)
    db.systemBroker.fpsColors = nil
    db.systemBroker.latencyColors = nil
    return db.systemBroker
end

local function EnsureSpecializationConfig(db)
    db.specializationBroker = type(db.specializationBroker) == "table" and db.specializationBroker or {}
    db.specializationBroker.enabled = db.specializationBroker.enabled ~= false
    db.specializationBroker.noLabel = db.specializationBroker.noLabel and true or false
    db.specializationBroker.customLabel = NormalizeCustomLabel(db.specializationBroker.customLabel)
    if db.specializationBroker.hideLootIconWhenSame == nil then
        db.specializationBroker.hideLootIconWhenSame = true
    else
        db.specializationBroker.hideLootIconWhenSame = db.specializationBroker.hideLootIconWhenSame and true or false
    end
    return db.specializationBroker
end

local function EnsureVolumeConfig(db)
    db.volumeBroker = type(db.volumeBroker) == "table" and db.volumeBroker or {}
    db.volumeBroker.enabled = db.volumeBroker.enabled ~= false
    db.volumeBroker.noLabel = db.volumeBroker.noLabel and true or false
    db.volumeBroker.customLabel = NormalizeCustomLabel(db.volumeBroker.customLabel)
    return db.volumeBroker
end

local function EnsureAudioDeviceConfig(db)
    db.audioDeviceBroker = type(db.audioDeviceBroker) == "table" and db.audioDeviceBroker or {}
    db.audioDeviceBroker.enabled = db.audioDeviceBroker.enabled ~= false
    db.audioDeviceBroker.noLabel = db.audioDeviceBroker.noLabel and true or false
    db.audioDeviceBroker.customLabel = NormalizeCustomLabel(db.audioDeviceBroker.customLabel)
    return db.audioDeviceBroker
end

local function EnsureSelectionDB(Addon)
    local rootDB = GetStandaloneDBRoot()
    local db = rootDB.databrokers

    db.options = type(db.options) == "table" and db.options or {}
    db.options.sectionState = type(db.options.sectionState) == "table" and db.options.sectionState or {}

    local selectedKey = ResolveBrokerKey(db.options.selectedBrokerKey or db.options.selectedCustomBroker)
    if not selectedKey then
        selectedKey = BROKER_DEFINITIONS[1].key
    end

    db.options.selectedBrokerKey = selectedKey
    db.options.selectedCustomBroker = nil

    EnsureClockConfig(db)
    EnsureDurabilityConfig(db)
    EnsureSystemConfig(db)
    EnsureSpecializationConfig(db)
    EnsureVolumeConfig(db)
    EnsureAudioDeviceConfig(db)

    SyncStandaloneAddonDB()

    return db
end

local function GetBrokerDefinition(key)
    for _, def in ipairs(BROKER_DEFINITIONS) do
        if def.key == key then
            return def
        end
    end

    return BROKER_DEFINITIONS[1]
end

local function CreateCard(parent, title, startOpen)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    card:SetBackdropColor(0.02, 0.02, 0.02, 0.45)
    card:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

    local head = CreateFrame("Button", nil, card, "BackdropTemplate")
    head:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    head:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, -1)
    head:SetHeight(28)
    head:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    head:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.22)

    local icon = head:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    icon:SetPoint("LEFT", head, "LEFT", 8, 0)
    icon:SetText("-")
    icon:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    if W and W.ApplyFont then
        W.ApplyFont(icon, 0)
    end

    local label = head:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    label:SetText(title)
    label:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    if W and W.ApplyFont then
        W.ApplyFont(label, 0)
    end

    local content = CreateFrame("Frame", nil, card)
    content:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -2)
    content:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", 0, -2)

    card.head = head
    card.icon = icon
    card.content = content
    card.open = startOpen ~= false
    content:SetShown(card.open)
    icon:SetText(card.open and "-" or "+")

    function card:SetOpen(isOpen)
        self.open = isOpen and true or false
        self.content:SetShown(self.open)
        self.icon:SetText(self.open and "-" or "+")
    end

    return card, content, head
end

local function GetBrokerConfigForKey(db, key)
    if key == "clockBroker" then
        return db.clockBroker
    elseif key == "durabilityColors" then
        return db.durabilityColors
    elseif key == "systemBroker" then
        return db.systemBroker
    elseif key == "specializationBroker" then
        return db.specializationBroker
    elseif key == "volumeBroker" then
        return db.volumeBroker
    elseif key == "audioDeviceBroker" then
        return db.audioDeviceBroker
    end

    return nil
end

local function CreateScrollableSection(parentFrame, anchorFrame, sectionKey, titleText, entries, rowBuilder, emptyText, topOffset)
    local section = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    local offsetY = type(topOffset) == "number" and topOffset or -10
    if anchorFrame == parentFrame then
        section:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", 0, offsetY)
        section:SetPoint("TOPRIGHT", anchorFrame, "TOPRIGHT", 0, offsetY)
    else
        section:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, offsetY)
        section:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMRIGHT", 0, offsetY)
    end
    section:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    section:SetBackdropColor(0.02, 0.02, 0.02, 0.45)
    section:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

    local headerBtn = CreateFrame("Button", nil, section, "BackdropTemplate")
    headerBtn:SetPoint("TOPLEFT", section, "TOPLEFT", 1, -1)
    headerBtn:SetPoint("TOPRIGHT", section, "TOPRIGHT", -1, -1)
    headerBtn:SetHeight(28)
    headerBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    headerBtn:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.22)

    local icon = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    icon:SetPoint("LEFT", headerBtn, "LEFT", 8, 0)
    icon:SetText("-")
    icon:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    if W and W.ApplyFont then
        W.ApplyFont(icon, 0)
    end

    local hdrText = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdrText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    hdrText:SetText(titleText)
    hdrText:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    if W and W.ApplyFont then
        W.ApplyFont(hdrText, 0)
    end

    local content = CreateFrame("Frame", nil, section)
    content:SetPoint("TOPLEFT", headerBtn, "BOTTOMLEFT", 0, -4)
    content:SetPoint("TOPRIGHT", headerBtn, "BOTTOMRIGHT", 0, -4)

    local isOpen = true
    if sectionKey and type(sectionKey) == "string" then
        local rootDB = GetStandaloneDBRoot()
        rootDB.databrokers.options = type(rootDB.databrokers.options) == "table" and rootDB.databrokers.options or {}
        rootDB.databrokers.options.leftSectionState = type(rootDB.databrokers.options.leftSectionState) == "table" and rootDB.databrokers.options.leftSectionState or {}
        if rootDB.databrokers.options.leftSectionState[sectionKey] == nil then
            rootDB.databrokers.options.leftSectionState[sectionKey] = true
        end
        isOpen = rootDB.databrokers.options.leftSectionState[sectionKey] ~= false
    end
    icon:SetText(isOpen and "-" or "+")

    local function Rebuild(open)
        content:SetShown(open and true or false)
        if not open then
            section:SetHeight(30)
            return 30
        end

        local visibleRows = 8
        local rowHeight = 30
        local rowGap = 4
        local viewHeight = (visibleRows * rowHeight) + ((visibleRows - 1) * rowGap)

        local rowCount = #entries
        local useEmpty = rowCount == 0 and emptyText
        local fullRows = useEmpty and 1 or rowCount

        content:SetHeight(viewHeight)

        local scroll = CreateFrame("ScrollFrame", nil, content)
        scroll:SetPoint("TOPLEFT", content, "TOPLEFT", 6, 0)
        scroll:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -((fullRows > 8) and 20 or 6), 0)
        scroll:EnableMouseWheel(true)

        local child = CreateFrame("Frame", nil, scroll)
        child:SetWidth(10)
        local childHeight = math.max(viewHeight, (fullRows * rowHeight) + ((fullRows - 1) * rowGap))
        child:SetHeight(math.max(viewHeight, childHeight))
        scroll:SetScrollChild(child)

        local function UpdateChildWidth()
            local width = scroll:GetWidth() or 0
            if width < 10 then
                width = 10
            end
            child:SetWidth(width)
        end

        scroll:SetScript("OnSizeChanged", UpdateChildWidth)
        C_Timer.After(0, UpdateChildWidth)

        if useEmpty then
            local emptyRow = CreateFrame("Frame", nil, child, "BackdropTemplate")
            emptyRow:SetHeight(24)
            emptyRow:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
            emptyRow:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, 0)
            emptyRow:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            emptyRow:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.08)
            emptyRow:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.25)

            local emptyLabel = emptyRow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            emptyLabel:SetPoint("LEFT", emptyRow, "LEFT", 10, 0)
            emptyLabel:SetText(emptyText)
            emptyLabel:SetTextColor(C.GRAY.r, C.GRAY.g, C.GRAY.b, 0.9)
            if W and W.ApplyFont then
                W.ApplyFont(emptyLabel, -1)
            end
        else
            local lastRow
            for _, entry in ipairs(entries) do
                local row = rowBuilder(child, entry)
                if lastRow then
                    row:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", 0, -rowGap)
                    row:SetPoint("TOPRIGHT", lastRow, "BOTTOMRIGHT", 0, -rowGap)
                else
                    row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
                    row:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, 0)
                end
                lastRow = row
            end
        end

        local maxScroll = math.max(0, childHeight - viewHeight)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local nextScroll = self:GetVerticalScroll() - (delta * 24)
            nextScroll = math.max(0, math.min(nextScroll, maxScroll))
            self:SetVerticalScroll(nextScroll)
            if self._slider then
                self._slider:SetValue(nextScroll)
            end
        end)

        if fullRows > 8 then
            local slider = CreateFrame("Slider", nil, content, "BackdropTemplate")
            slider:SetOrientation("VERTICAL")
            slider:SetWidth(12)
            slider:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, 0)
            slider:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -4, 0)
            slider:SetMinMaxValues(0, maxScroll)
            slider:SetValue(0)
            slider:SetValueStep(1)

            slider:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            slider:SetBackdropColor(0.03, 0.03, 0.03, 0.95)
            slider:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

            local thumb = slider:CreateTexture(nil, "OVERLAY")
            thumb:SetSize(10, 18)
            thumb:SetColorTexture(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.85)
            slider:SetThumbTexture(thumb)

            slider:SetScript("OnValueChanged", function(self, value)
                scroll:SetVerticalScroll(value)
            end)

            scroll._slider = slider
        end

        local sectionHeight = 30 + 4 + viewHeight + 6
        section:SetHeight(sectionHeight)
        return sectionHeight
    end

    section.open = isOpen
    section.Rebuild = Rebuild
    Rebuild(section.open)

    headerBtn:SetScript("OnClick", function()
        section.open = not section.open
        if sectionKey and type(sectionKey) == "string" then
            local rootDB = GetStandaloneDBRoot()
            rootDB.databrokers.options.leftSectionState = type(rootDB.databrokers.options.leftSectionState) == "table" and rootDB.databrokers.options.leftSectionState or {}
            rootDB.databrokers.options.leftSectionState[sectionKey] = section.open and true or false
            SyncStandaloneAddonDB()
        end
        icon:SetText(section.open and "-" or "+")
        Rebuild(section.open)
    end)

    return section, section:GetHeight()
end

local function BuildBrokerSettingsPanel(builder, cfg, onChanged)
    local row = CreateFrame("Frame", nil, builder.parent, "BackdropTemplate")
    row:SetHeight(34)
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    row:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.14)
    row:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

    local noLabelCheck = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    noLabelCheck:SetSize(20, 20)
    noLabelCheck:SetPoint("LEFT", row, "LEFT", 8, 0)
    noLabelCheck:SetChecked(cfg.noLabel and true or false)
    noLabelCheck:SetScript("OnClick", function(self)
        cfg.noLabel = self:GetChecked() and true or false
        if onChanged then
            onChanged()
        end
    end)

    local noLabelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    noLabelText:SetPoint("LEFT", noLabelCheck, "RIGHT", 2, 0)
    noLabelText:SetText("No Label")
    noLabelText:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
    W.ApplyFont(noLabelText, -1)

    local customLabelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    customLabelText:SetPoint("LEFT", noLabelText, "RIGHT", 16, 0)
    customLabelText:SetText("Custom Label")
    customLabelText:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
    W.ApplyFont(customLabelText, -1)

    local edit = CreateFrame("EditBox", nil, row, "BackdropTemplate")
    edit:SetHeight(22)
    edit:SetPoint("LEFT", customLabelText, "RIGHT", 8, 0)
    edit:SetPoint("RIGHT", row, "RIGHT", -10, 0)
    edit:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    edit:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    edit:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.55)
    W.ApplyFont(edit, -1)
    edit:SetTextColor(1, 1, 1, 0.9)
    edit:SetTextInsets(6, 6, 0, 0)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(64)
    edit:SetText(cfg.customLabel or "")
    edit:SetScript("OnEnterPressed", function(self)
        cfg.customLabel = NormalizeCustomLabel(self:GetText())
        self:SetText(cfg.customLabel or "")
        self:ClearFocus()
        if onChanged then
            onChanged()
        end
    end)
    edit:SetScript("OnEscapePressed", function(self)
        self:SetText(cfg.customLabel or "")
        self:ClearFocus()
    end)
    row:SetScript("OnShow", function()
        noLabelCheck:SetChecked(cfg.noLabel and true or false)
        edit:SetText(cfg.customLabel or "")
    end)

    builder:_Attach(row, 34, 4)
end

local function BuildClockPanel(builder, cfg, onChanged)
    builder:Desc("These settings control the text formatting for the clock broker.")
    builder:Toggle("Use Server Time",
        function() return cfg.useServerTime end,
        function(v)
            cfg.useServerTime = v and true or false
            if onChanged then
                onChanged()
            end
        end)

    builder:Toggle("Use 24 Hour Format",
        function() return cfg.use24Hour end,
        function(v)
            cfg.use24Hour = v and true or false
            if onChanged then
                onChanged()
            end
        end)
end

local function BuildDurabilityPanel(builder, cfg, onChanged)
    builder:Desc("Durability colors are fixed in code:")
    builder:Desc("- Critical (<=20%): Red")
    builder:Desc("- Warning (<=50%): Yellow")
    builder:Desc("- OK (>50%): Green")
end

local function BuildSystemPanel(builder, cfg, onChanged)
    builder:Desc("System broker colors are fixed in code:")
    builder:Desc("- FPS < 20: Red")
    builder:Desc("- FPS < 60: Yellow")
    builder:Desc("- FPS >= 60: Green")
    builder:Desc("- Latency > 300ms: Red")
    builder:Desc("- Latency > 150ms: Yellow")
    builder:Desc("- Latency <= 150ms: Green")
end

local function BuildSpecializationPanel(builder)
    builder:Desc("Configure the specialization broker label and icon behavior.")
end

local function BuildVolumePanel(builder)
    builder:Desc("Volume controls are available directly from the broker menu.")
end

local function BuildAudioDevicePanel(builder)
    builder:Desc("Audio output device selection is available directly from the broker menu.")
end

function ns:InitDataBrokersPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    W = ns.OptionsWidgets
    C = ns.OptionsColors

    local parent = ns.OptionsFrame.Content
    local Addon = (type(ns.GetAddon) == "function" and ns.GetAddon()) or ns.Addon

    local function ApplyFont(target, offset)
        if W and W.ApplyFont then
            W.ApplyFont(target, offset)
        end
    end

    local root = CreateFrame("Frame", nil, parent)
    root:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    root:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
    root:SetHeight(1)

    local title = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 2, -2)
    title:SetText("DataBrokers")
    title:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    ApplyFont(title, 2)

    local subtitle = root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetPoint("TOPRIGHT", root, "TOPRIGHT", -2, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWordWrap(true)
    subtitle:SetText("Browse each broker defined in Thisnthat_Databrokers and adjust its stored settings on the right.")
    ApplyFont(subtitle, -1)

    local body = CreateFrame("Frame", nil, root)
    body:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
    body:SetPoint("TOPRIGHT", subtitle, "BOTTOMRIGHT", 0, -10)
    body:SetHeight(1)

    if not IsDatabrokersAddonLoaded() then
        local notice = W.Builder(body, { startY = 0, padX = 0 })
        notice:Desc("|cffff7777Thisnthat_Databrokers is not loaded.|r")
        local h = notice:Finalize()
        body:SetHeight(h)
        root:SetHeight(84 + h)
        parent:SetHeight(110 + h)
        return
    end

    if not Addon then
        local notice = W.Builder(body, { startY = 0, padX = 0 })
        notice:Desc("|cffff7777Addon context is unavailable.|r")
        local h = notice:Finalize()
        body:SetHeight(h)
        root:SetHeight(84 + h)
        parent:SetHeight(110 + h)
        return
    end

    local db = EnsureSelectionDB(Addon)
    local dbModule = rawget(_G, "Thisnthat_Databrokers_DataBrokers")
    local brokerEntries = {}
    for _, def in ipairs(BROKER_DEFINITIONS) do
        brokerEntries[#brokerEntries + 1] = {
            key = def.key,
            name = def.name,
            label = def.label,
            description = def.description,
        }
    end

    local selectedKey = ResolveBrokerKey(db.options.selectedBrokerKey) or BROKER_DEFINITIONS[1].key
    db.options.selectedBrokerKey = selectedKey

    local selectedEntry = GetBrokerDefinition(selectedKey)
    local clockCfg = db.clockBroker
    local durabilityCfg = db.durabilityColors
    local systemCfg = db.systemBroker
    local specializationCfg = db.specializationBroker
    local volumeCfg = db.volumeBroker
    local audioDeviceCfg = db.audioDeviceBroker

    local panelRowRefs = {}
    local RenderRightPane

    local function RefreshStandaloneBrokers()
        SyncStandaloneAddonDB()
        if dbModule and type(dbModule.RefreshCustomBrokers) == "function" then
            dbModule:RefreshCustomBrokers()
        end
    end

    local function ApplyRowVisual(ref, isSelected)
        if not ref or not ref.row or not ref.text then
            return
        end

        if isSelected then
            ref.row:SetBackdropColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.2)
            ref.row:SetBackdropBorderColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.85)
            ref.text:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
            return
        end

        ref.row:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.12)
        ref.row:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)
        if ref.brokerCfg and ref.brokerCfg.enabled == false then
            ref.text:SetTextColor(C.GRAY.r, C.GRAY.g, C.GRAY.b, 0.8)
        else
            ref.text:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        end
    end

    local function UpdateLeftSelectionVisuals()
        local current = db.options.selectedBrokerKey
        for _, ref in ipairs(panelRowRefs) do
            ApplyRowVisual(ref, ref.key == current)
        end
    end

    local function SelectBroker(key)
        local resolved = ResolveBrokerKey(key)
        if not resolved then
            return
        end

        db.options.selectedBrokerKey = resolved
        selectedEntry = GetBrokerDefinition(resolved)
        clockCfg = db.clockBroker
        durabilityCfg = db.durabilityColors
        systemCfg = db.systemBroker
        specializationCfg = db.specializationBroker
        volumeCfg = db.volumeBroker
        audioDeviceCfg = db.audioDeviceBroker

        UpdateLeftSelectionVisuals()
        if RenderRightPane then
            RenderRightPane()
        end
    end

    local function BuildBrokerRow(parentFrame, entry)
        local row = CreateFrame("Button", nil, parentFrame, "BackdropTemplate")
        row:SetHeight(30)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", row, "LEFT", 10, 0)
        text:SetPoint("RIGHT", row, "RIGHT", -34, 0)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
        text:SetText(entry.name)
        ApplyFont(text, -1)

        local brokerCfg = GetBrokerConfigForKey(db, entry.key)
        local toggle = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        toggle:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        toggle:SetChecked(brokerCfg and brokerCfg.enabled ~= false)
        toggle:SetScript("OnClick", function(self)
            if brokerCfg then
                brokerCfg.enabled = self:GetChecked() and true or false
                RefreshStandaloneBrokers()
                UpdateLeftSelectionVisuals()
            end
        end)

        panelRowRefs[#panelRowRefs + 1] = {
            kind = "broker",
            key = entry.key,
            row = row,
            text = text,
            brokerCfg = brokerCfg,
        }
        ApplyRowVisual(panelRowRefs[#panelRowRefs], entry.key == db.options.selectedBrokerKey)

        row:SetScript("OnClick", function()
            SelectBroker(entry.key)
        end)

        return row
    end

    local leftPane = CreateFrame("Frame", nil, body)
    leftPane:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    leftPane:SetPoint("LEFT", body, "LEFT", 0, 0)
    leftPane:SetWidth(340)

    local rightPane = CreateFrame("Frame", nil, body)
    rightPane:SetPoint("TOPLEFT", leftPane, "TOPRIGHT", 10, 0)
    rightPane:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)
    rightPane:SetHeight(1)

    local _, brokerSectionHeight = CreateScrollableSection(
        leftPane,
        leftPane,
        "brokers",
        "DataBrokers",
        brokerEntries,
        BuildBrokerRow,
        nil,
        0
    )

    leftPane:SetHeight(math.max(180, brokerSectionHeight))

    local function ClearFrameChildren(frame)
        for _, child in ipairs({ frame:GetChildren() }) do
            if child and child.Hide then
                child:Hide()
            end
        end
        for _, region in ipairs({ frame:GetRegions() }) do
            if region and region.Hide then
                region:Hide()
            end
        end
    end

    RenderRightPane = function()
        ClearFrameChildren(rightPane)

        local rightLast
        local rightTotal = 0
        local optionsState = db.options.sectionState

        local function AddCard(sectionId, titleText, buildFn, defaultOpen)
            local stateKey = tostring(selectedEntry.key) .. ":" .. tostring(sectionId)
            local isOpen = optionsState[stateKey]
            if isOpen == nil then
                isOpen = defaultOpen ~= false
            end

            local card, cardContent, head = CreateCard(rightPane, titleText, isOpen)
            if rightLast then
                card:SetPoint("TOPLEFT", rightLast, "BOTTOMLEFT", 0, -8)
                card:SetPoint("TOPRIGHT", rightLast, "BOTTOMRIGHT", 0, -8)
                rightTotal = rightTotal + 8
            else
                card:SetPoint("TOPLEFT", rightPane, "TOPLEFT", 0, 0)
                card:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", 0, 0)
            end

            head:SetScript("OnClick", function()
                optionsState[stateKey] = not card.open
                RenderRightPane()
            end)

            local builder = W.Builder(cardContent, { startY = 8, padX = 8 })
            buildFn(builder)
            local innerHeight = builder:Finalize()
            cardContent:SetHeight(innerHeight)

            local cardHeight = 30
            if card.open then
                cardHeight = cardHeight + innerHeight + 6
            end
            card:SetHeight(cardHeight)

            rightTotal = rightTotal + cardHeight
            rightLast = card
        end

        if selectedEntry.key == "clockBroker" then
            AddCard("broker_settings", "Broker", function(builder)
                BuildBrokerSettingsPanel(builder, clockCfg, RefreshStandaloneBrokers)
            end, true)
            AddCard("clock", "Clock", function(builder)
                BuildClockPanel(builder, clockCfg, RefreshStandaloneBrokers)
            end, true)
        elseif selectedEntry.key == "durabilityColors" then
            AddCard("broker_settings", "Broker", function(builder)
                BuildBrokerSettingsPanel(builder, durabilityCfg, RefreshStandaloneBrokers)
            end, true)
            AddCard("durability", "Durability", function(builder)
                BuildDurabilityPanel(builder, durabilityCfg, RefreshStandaloneBrokers)
            end, true)
        elseif selectedEntry.key == "systemBroker" then
            AddCard("broker_settings", "Broker", function(builder)
                BuildBrokerSettingsPanel(builder, systemCfg, RefreshStandaloneBrokers)
            end, true)
            AddCard("system", "System", function(builder)
                BuildSystemPanel(builder, systemCfg, RefreshStandaloneBrokers)
            end, true)
        elseif selectedEntry.key == "specializationBroker" then
            AddCard("broker_settings", "Broker", function(builder)
                BuildBrokerSettingsPanel(builder, specializationCfg, RefreshStandaloneBrokers)
            end, true)
            AddCard("specialization", "Specialization", function(builder)
                BuildSpecializationPanel(builder)
                builder:Toggle("Hide loot icon when talent and loot specialization match",
                    function()
                        return specializationCfg.hideLootIconWhenSame ~= false
                    end,
                    function(value)
                        specializationCfg.hideLootIconWhenSame = value and true or false
                        RefreshStandaloneBrokers()
                    end)
            end, true)
        elseif selectedEntry.key == "volumeBroker" then
            AddCard("broker_settings", "Broker", function(builder)
                BuildBrokerSettingsPanel(builder, volumeCfg, RefreshStandaloneBrokers)
            end, true)
            AddCard("volume", "Volume", function(builder)
                BuildVolumePanel(builder)
            end, true)
        elseif selectedEntry.key == "audioDeviceBroker" then
            AddCard("broker_settings", "Broker", function(builder)
                BuildBrokerSettingsPanel(builder, audioDeviceCfg, RefreshStandaloneBrokers)
            end, true)
            AddCard("audio_device", "Audio Device", function(builder)
                BuildAudioDevicePanel(builder)
            end, true)
        end

        rightPane:SetHeight(math.max(1, rightTotal))
        local bodyHeight = math.max(leftPane:GetHeight(), rightTotal)
        body:SetHeight(math.max(180, bodyHeight))
        root:SetHeight(84 + body:GetHeight())
        parent:SetHeight(110 + body:GetHeight())
    end

    UpdateLeftSelectionVisuals()
    RenderRightPane()
end
