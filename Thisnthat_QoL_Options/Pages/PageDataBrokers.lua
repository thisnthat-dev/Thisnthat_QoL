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
        description = "Tune the durability threshold colors used by the broker.",
    },
    {
        key = "systemBroker",
        name = "TNT: System",
        label = "System",
        description = "Adjust the FPS and latency palette used by the system broker.",
    },
    {
        key = "specializationBroker",
        name = "TNT: Specialization",
        label = "Specialization",
        description = "Configure specialization broker visibility and icon behavior.",
    },
}

local CLOCK_DEFAULTS = {
    useServerTime = false,
    use24Hour = false,
}

local DURABILITY_DEFAULTS = {
    ok = { r = 0, g = 1, b = 0, a = 1 },
    warning = { r = 1, g = 1, b = 0, a = 1 },
    critical = { r = 1, g = 0, b = 0, a = 1 },
}

local SYSTEM_DEFAULTS = {
    fpsColors = {
        critical = { r = 1, g = 0, b = 0, a = 1 },
        warning = { r = 1, g = 1, b = 0, a = 1 },
        ok = { r = 0, g = 1, b = 0, a = 1 },
    },
    latencyColors = {
        critical = { r = 1, g = 0, b = 0, a = 1 },
        warning = { r = 1, g = 1, b = 0, a = 1 },
        ok = { r = 0, g = 1, b = 0, a = 1 },
    },
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

local function EnsureColor(colorValue, defaultColor)
    local color = type(colorValue) == "table" and colorValue or {}
    return {
        r = Clamp(color.r, 0, 1, defaultColor.r),
        g = Clamp(color.g, 0, 1, defaultColor.g),
        b = Clamp(color.b, 0, 1, defaultColor.b),
        a = Clamp(color.a, 0, 1, defaultColor.a),
    }
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
    db.clockBroker.useServerTime = db.clockBroker.useServerTime and true or false
    db.clockBroker.use24Hour = db.clockBroker.use24Hour and true or false
    return db.clockBroker
end

local function EnsureDurabilityConfig(db)
    db.durabilityColors = type(db.durabilityColors) == "table" and db.durabilityColors or {}
    db.durabilityColors.enabled = db.durabilityColors.enabled ~= false
    db.durabilityColors.ok = EnsureColor(db.durabilityColors.ok, DURABILITY_DEFAULTS.ok)
    db.durabilityColors.warning = EnsureColor(db.durabilityColors.warning, DURABILITY_DEFAULTS.warning)
    db.durabilityColors.critical = EnsureColor(db.durabilityColors.critical, DURABILITY_DEFAULTS.critical)
    return db.durabilityColors
end

local function EnsureSystemConfig(db)
    db.systemBroker = type(db.systemBroker) == "table" and db.systemBroker or {}
    db.systemBroker.enabled = db.systemBroker.enabled ~= false
    db.systemBroker.fpsColors = type(db.systemBroker.fpsColors) == "table" and db.systemBroker.fpsColors or {}
    db.systemBroker.latencyColors = type(db.systemBroker.latencyColors) == "table" and db.systemBroker.latencyColors or {}
    db.systemBroker.fpsColors.critical = EnsureColor(db.systemBroker.fpsColors.critical, SYSTEM_DEFAULTS.fpsColors.critical)
    db.systemBroker.fpsColors.warning = EnsureColor(db.systemBroker.fpsColors.warning, SYSTEM_DEFAULTS.fpsColors.warning)
    db.systemBroker.fpsColors.ok = EnsureColor(db.systemBroker.fpsColors.ok, SYSTEM_DEFAULTS.fpsColors.ok)
    db.systemBroker.latencyColors.critical = EnsureColor(db.systemBroker.latencyColors.critical, SYSTEM_DEFAULTS.latencyColors.critical)
    db.systemBroker.latencyColors.warning = EnsureColor(db.systemBroker.latencyColors.warning, SYSTEM_DEFAULTS.latencyColors.warning)
    db.systemBroker.latencyColors.ok = EnsureColor(db.systemBroker.latencyColors.ok, SYSTEM_DEFAULTS.latencyColors.ok)
    return db.systemBroker
end

local function EnsureSpecializationConfig(db)
    db.specializationBroker = type(db.specializationBroker) == "table" and db.specializationBroker or {}
    db.specializationBroker.enabled = db.specializationBroker.enabled ~= false
    if db.specializationBroker.hideLootIconWhenSame == nil then
        db.specializationBroker.hideLootIconWhenSame = true
    else
        db.specializationBroker.hideLootIconWhenSame = db.specializationBroker.hideLootIconWhenSame and true or false
    end
    return db.specializationBroker
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
    end

    return nil
end

local function GetDatabrokersModule(Addon)
    if Addon and type(Addon.GetModule) == "function" then
        return Addon:GetModule("databrokers")
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

    local function Rebuild(open)
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

    section.open = true
    section.Rebuild = Rebuild
    Rebuild(true)

    headerBtn:SetScript("OnClick", function()
        section.open = not section.open
        icon:SetText(section.open and "-" or "+")
        Rebuild(section.open)
    end)

    return section, section:GetHeight()
end

local function SetPaletteColor(target, key, defaultColor, r, g, b, a)
    target[key] = {
        r = Clamp(r, 0, 1, defaultColor.r),
        g = Clamp(g, 0, 1, defaultColor.g),
        b = Clamp(b, 0, 1, defaultColor.b),
        a = Clamp(a, 0, 1, defaultColor.a),
    }
end

local function BuildPaletteControls(builder, palette, entries)
    for _, entry in ipairs(entries) do
        builder:Color(entry.label,
            function()
                local c = palette[entry.key] or entry.default
                return c.r, c.g, c.b, c.a
            end,
            function(r, g, b, a)
                SetPaletteColor(palette, entry.key, entry.default, r, g, b, a)
            end,
            true)
    end
end

local function BuildClockPanel(builder, cfg)
    builder:Desc("These settings control the text formatting for the clock broker.")
    builder:Toggle("Use Server Time",
        function() return cfg.useServerTime end,
        function(v)
            cfg.useServerTime = v and true or false
        end)

    builder:Toggle("Use 24 Hour Format",
        function() return cfg.use24Hour end,
        function(v)
            cfg.use24Hour = v and true or false
        end)
end

local function BuildDurabilityPanel(builder, cfg)
    builder:Desc("Durability colors are used at 20%, 50%, and above 50% durability.")
    BuildPaletteControls(builder, cfg, {
        { key = "critical", label = "Critical", default = DURABILITY_DEFAULTS.critical },
        { key = "warning", label = "Warning", default = DURABILITY_DEFAULTS.warning },
        { key = "ok", label = "OK", default = DURABILITY_DEFAULTS.ok },
    })
end

local function BuildSystemPanel(builder, cfg)
    builder:Desc("These colors control the system broker's FPS and latency value presentation.")
    builder:Header("FPS Colors")
    BuildPaletteControls(builder, cfg.fpsColors, {
        { key = "critical", label = "Critical", default = SYSTEM_DEFAULTS.fpsColors.critical },
        { key = "warning", label = "Warning", default = SYSTEM_DEFAULTS.fpsColors.warning },
        { key = "ok", label = "OK", default = SYSTEM_DEFAULTS.fpsColors.ok },
    })

    builder:Header("Latency Colors")
    BuildPaletteControls(builder, cfg.latencyColors, {
        { key = "critical", label = "Critical", default = SYSTEM_DEFAULTS.latencyColors.critical },
        { key = "warning", label = "Warning", default = SYSTEM_DEFAULTS.latencyColors.warning },
        { key = "ok", label = "OK", default = SYSTEM_DEFAULTS.latencyColors.ok },
    })
end

local function BuildSpecializationPanel(builder)
    builder:Desc("This broker currently uses live specialization state and has no broker-specific settings yet.")
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
    local standaloneAddon = GetStandaloneAddon()
    local dbModule = standaloneAddon and standaloneAddon.GetModule and standaloneAddon:GetModule("databrokers") or nil
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

    local panelRowRefs = {}
    local RenderRightPane

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
                SyncStandaloneAddonDB()
                UpdateLeftSelectionVisuals()
                if dbModule and type(dbModule.RefreshCustomBrokers) == "function" then
                    dbModule:RefreshCustomBrokers()
                end
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
            AddCard("clock", "Clock Settings", function(builder)
                BuildClockPanel(builder, clockCfg)
            end, true)
        elseif selectedEntry.key == "durabilityColors" then
            AddCard("durability", "Durability Colors", function(builder)
                BuildDurabilityPanel(builder, durabilityCfg)
            end, true)
        elseif selectedEntry.key == "systemBroker" then
            AddCard("fps", "FPS Colors", function(builder)
                builder:Desc("Color thresholds used for the FPS part of the broker text.")
                BuildPaletteControls(builder, systemCfg.fpsColors, {
                    { key = "critical", label = "Critical", default = SYSTEM_DEFAULTS.fpsColors.critical },
                    { key = "warning", label = "Warning", default = SYSTEM_DEFAULTS.fpsColors.warning },
                    { key = "ok", label = "OK", default = SYSTEM_DEFAULTS.fpsColors.ok },
                })
            end, true)

            AddCard("latency", "Latency Colors", function(builder)
                builder:Desc("Color thresholds used for the home latency part of the broker text.")
                BuildPaletteControls(builder, systemCfg.latencyColors, {
                    { key = "critical", label = "Critical", default = SYSTEM_DEFAULTS.latencyColors.critical },
                    { key = "warning", label = "Warning", default = SYSTEM_DEFAULTS.latencyColors.warning },
                    { key = "ok", label = "OK", default = SYSTEM_DEFAULTS.latencyColors.ok },
                })
            end, true)
        elseif selectedEntry.key == "specializationBroker" then
            AddCard("specialization", "Specialization", function(builder)
                BuildSpecializationPanel(builder)
                builder:Toggle("Hide loot icon when talent and loot specs match",
                    function()
                        return specializationCfg.hideLootIconWhenSame ~= false
                    end,
                    function(value)
                        specializationCfg.hideLootIconWhenSame = value and true or false
                        SyncStandaloneAddonDB()
                        if dbModule and type(dbModule.RefreshCustomBrokers) == "function" then
                            dbModule:RefreshCustomBrokers()
                        end
                    end)
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
