local ADDON_NAME, ns = ...

local JUSTIFY_ITEMS = {
    { value = "LEFT", label = "Left" },
    { value = "CENTER", label = "Center" },
    { value = "RIGHT", label = "Right" },
}

local OUTLINE_ITEMS = {
    { value = "NONE", label = "None" },
    { value = "OUTLINE", label = "Outline" },
    { value = "THICKOUTLINE", label = "Thick Outline" },
    { value = "MONOCHROME", label = "Monochrome" },
}

local STRATA_ITEMS = {
    { value = "BACKGROUND", label = "Background" },
    { value = "LOW", label = "Low" },
    { value = "MEDIUM", label = "Medium" },
    { value = "HIGH", label = "High" },
    { value = "DIALOG", label = "Dialog" },
    { value = "FULLSCREEN", label = "Fullscreen" },
    { value = "FULLSCREEN_DIALOG", label = "Fullscreen Dialog" },
    { value = "TOOLTIP", label = "Tooltip" },
}

local POINT_ITEMS = {
    { value = "TOPLEFT", label = "TOPLEFT" },
    { value = "TOP", label = "TOP" },
    { value = "TOPRIGHT", label = "TOPRIGHT" },
    { value = "LEFT", label = "LEFT" },
    { value = "CENTER", label = "CENTER" },
    { value = "RIGHT", label = "RIGHT" },
    { value = "BOTTOMLEFT", label = "BOTTOMLEFT" },
    { value = "BOTTOM", label = "BOTTOM" },
    { value = "BOTTOMRIGHT", label = "BOTTOMRIGHT" },
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

local function Trim(value)
    local s = tostring(value or "")
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function EnsureDraftConfig(db)
    db.newPanelDraft = type(db.newPanelDraft) == "table" and db.newPanelDraft or {}
    local draft = db.newPanelDraft

    draft.name = type(draft.name) == "string" and draft.name or ""
    draft.maxBrokers = Clamp(draft.maxBrokers, 1, 10, 8)
    draft.enabled = draft.enabled ~= false
    draft.customAnchor = draft.customAnchor and true or false
    draft.anchorPanel = type(draft.anchorPanel) == "string" and Trim(draft.anchorPanel) or "UIParent"
    if draft.anchorPanel == "" then
        draft.anchorPanel = "UIParent"
    end
    draft.point = type(draft.point) == "string" and string.upper(draft.point) or "CENTER"
    draft.relativePoint = type(draft.relativePoint) == "string" and string.upper(draft.relativePoint) or "CENTER"
    draft.x = Clamp(draft.x, -4000, 4000, 0)
    draft.y = Clamp(draft.y, -4000, 4000, 0)
    draft.width = Clamp(draft.width, 120, 2400, 560)
    draft.height = Clamp(draft.height, 12, 128, 24)
    draft.textJustify = type(draft.textJustify) == "string" and string.upper(draft.textJustify) or "CENTER"
    if draft.textJustify ~= "LEFT" and draft.textJustify ~= "CENTER" and draft.textJustify ~= "RIGHT" then
        draft.textJustify = "CENTER"
    end

    draft.fontOverride = draft.fontOverride and true or false
    draft.font = type(draft.font) == "string" and draft.font or ""
    draft.fontSize = Clamp(draft.fontSize, 6, 64, 12)
    draft.fontOutline = type(draft.fontOutline) == "string" and string.upper(draft.fontOutline) or "NONE"
    if draft.fontOutline ~= "NONE" and draft.fontOutline ~= "OUTLINE" and draft.fontOutline ~= "THICKOUTLINE" and draft.fontOutline ~= "MONOCHROME" then
        draft.fontOutline = "NONE"
    end

    draft.showBackdrop = draft.showBackdrop ~= false
    draft.showBorder = draft.showBorder ~= false

    draft.frameStrata = type(draft.frameStrata) == "string" and string.upper(draft.frameStrata) or "LOW"
    draft.frameLevel = Clamp(draft.frameLevel, 1, 10, 1)

    return draft
end

local function EnsurePanelConfig(cfg, index)
    cfg = type(cfg) == "table" and cfg or {}

    cfg.name = type(cfg.name) == "string" and cfg.name or ("Panel " .. tostring(index or 1))
    cfg.maxBrokers = Clamp(cfg.maxBrokers, 1, 10, 8)
    cfg.enabled = cfg.enabled ~= false
    cfg.customAnchor = cfg.customAnchor and true or false
    cfg.anchorPanel = type(cfg.anchorPanel) == "string" and Trim(cfg.anchorPanel) or "UIParent"
    if cfg.anchorPanel == "" then
        cfg.anchorPanel = "UIParent"
    end
    cfg.point = type(cfg.point) == "string" and string.upper(cfg.point) or "CENTER"
    cfg.relativePoint = type(cfg.relativePoint) == "string" and string.upper(cfg.relativePoint) or "CENTER"
    cfg.x = Clamp(cfg.x, -4000, 4000, 0)
    cfg.y = Clamp(cfg.y, -4000, 4000, 0)
    cfg.width = Clamp(cfg.width, 120, 2400, 560)
    cfg.height = Clamp(cfg.height, 12, 128, 24)
    cfg.textJustify = type(cfg.textJustify) == "string" and string.upper(cfg.textJustify) or "CENTER"
    if cfg.textJustify ~= "LEFT" and cfg.textJustify ~= "CENTER" and cfg.textJustify ~= "RIGHT" then
        cfg.textJustify = "CENTER"
    end

    cfg.fontOverride = cfg.fontOverride and true or false
    cfg.font = type(cfg.font) == "string" and cfg.font or ""
    cfg.fontSize = Clamp(cfg.fontSize, 6, 64, 12)
    cfg.fontOutline = type(cfg.fontOutline) == "string" and string.upper(cfg.fontOutline) or "NONE"
    if cfg.fontOutline ~= "NONE" and cfg.fontOutline ~= "OUTLINE" and cfg.fontOutline ~= "THICKOUTLINE" and cfg.fontOutline ~= "MONOCHROME" then
        cfg.fontOutline = "NONE"
    end

    cfg.showBackdrop = cfg.showBackdrop ~= false
    cfg.showBorder = cfg.showBorder ~= false

    cfg.frameStrata = type(cfg.frameStrata) == "string" and string.upper(cfg.frameStrata) or "LOW"
    cfg.frameLevel = Clamp(cfg.frameLevel, 1, 10, 1)

    cfg.brokers = type(cfg.brokers) == "table" and cfg.brokers or {}

    return cfg
end

local function GetDataBrokerDB(Addon)
    Addon.db.databrokers = Addon.db.databrokers or {}
    local db = Addon.db.databrokers

    db.unlocked = db.unlocked and true or false
    db.bars = type(db.bars) == "table" and db.bars or {}
    db.availableBrokerCache = type(db.availableBrokerCache) == "table" and db.availableBrokerCache or {}
    db.selectedPanelKey = type(db.selectedPanelKey) == "string" and db.selectedPanelKey or "new"
    db.selectedEntityKey = type(db.selectedEntityKey) == "string" and db.selectedEntityKey or db.selectedPanelKey
    db.leftSectionState = type(db.leftSectionState) == "table" and db.leftSectionState or {}
    if db.leftSectionState.panels == nil then
        db.leftSectionState.panels = true
    end
    if db.leftSectionState.databrokers == nil then
        db.leftSectionState.databrokers = true
    end
    db.panelSectionState = type(db.panelSectionState) == "table" and db.panelSectionState or {}

    EnsureDraftConfig(db)

    return db
end

local function BuildFontItems(LSM)
    local items = { { value = "", label = "None" } }
    if LSM and type(LSM.List) == "function" then
        for _, name in ipairs(LSM:List("font") or {}) do
            items[#items + 1] = { value = name, label = name }
        end
    end
    return items
end

local function CreateCard(parent, title, C, W, startOpen)
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

function ns:InitDataBrokerPanelsPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    local parent = ns.OptionsFrame.Content
    local W = ns.OptionsWidgets
    local C = ns.OptionsColors
    local Addon = (type(ns.GetAddon) == "function" and ns.GetAddon()) or ns.Addon
    local dbModule = Addon and Addon.GetModule and Addon:GetModule("DatabrokerPanels") or nil
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

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
    title:SetText("DataBroker Panels")
    title:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    ApplyFont(title, 2)

    local subtitle = root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetPoint("TOPRIGHT", root, "TOPRIGHT", -2, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWordWrap(true)
    subtitle:SetText("Select a panel on the left. Configure its data brokers and look on the right.")
    ApplyFont(subtitle, -1)

    local enableRow = CreateFrame("Frame", nil, root, "BackdropTemplate")
    enableRow:SetHeight(30)
    enableRow:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
    enableRow:SetPoint("TOPRIGHT", subtitle, "BOTTOMRIGHT", 0, -10)
    enableRow:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    enableRow:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.06)
    enableRow:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

    local enableLabel = enableRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    enableLabel:SetPoint("LEFT", enableRow, "LEFT", 10, 0)
    enableLabel:SetText("Enable DataBroker Panels")
    enableLabel:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
    ApplyFont(enableLabel, -1)

    local enableToggle = CreateFrame("CheckButton", nil, enableRow, "UICheckButtonTemplate")
    enableToggle:SetPoint("RIGHT", enableRow, "RIGHT", -8, 0)
    enableToggle:SetChecked(Addon and Addon.IsModuleEnabled and Addon:IsModuleEnabled("DatabrokerPanels") or false)

    local body = CreateFrame("Frame", nil, root)
    body:SetPoint("TOPLEFT", enableRow, "BOTTOMLEFT", 0, -10)
    body:SetPoint("TOPRIGHT", enableRow, "BOTTOMRIGHT", 0, -10)
    body:SetHeight(1)

    local leftPaneWidth = 340

    local leftPane = CreateFrame("Frame", nil, body)
    leftPane:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
    leftPane:SetPoint("LEFT", body, "LEFT", 0, 0)
    leftPane:SetWidth(leftPaneWidth)

    local rightPane = CreateFrame("Frame", nil, body)
    rightPane:SetPoint("TOPLEFT", leftPane, "TOPRIGHT", 10, 0)
    rightPane:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)
    rightPane:SetHeight(1)

    local builderWhenUnavailable = W.Builder(rightPane, { startY = 0, padX = 0 })

    if not Addon or not dbModule then
        builderWhenUnavailable:Desc("|cffff7777DataBroker Panels module is unavailable.|r")
        local rightH = builderWhenUnavailable:Finalize()
        leftPane:SetHeight(math.max(80, rightH))
        body:SetHeight(math.max(80, rightH))
        root:SetHeight(84 + body:GetHeight())
        parent:SetHeight(110 + body:GetHeight())
        return
    end

    local db = GetDataBrokerDB(Addon)

    local function applyPanels()
        if type(dbModule.ApplySettings) == "function" then
            dbModule:ApplySettings()
        elseif type(dbModule.RefreshBars) == "function" then
            dbModule:RefreshBars()
        end
    end

    local function refreshPage()
        ns:InitDataBrokerPanelsPage()
    end

    local function GetCustomBrokerNames()
        local getter = rawget(_G, "Thisnthat_Databrokers_GetCustomBrokerNames")
        if type(getter) ~= "function" then
            return {}
        end

        local ok, names = pcall(getter)
        if ok and type(names) == "table" then
            return names
        end

        return {}
    end

    enableToggle:SetScript("OnClick", function(self)
        Addon.db.modules.DatabrokerPanels = Addon.db.modules.DatabrokerPanels or {}
        Addon.db.modules.DatabrokerPanels.enabled = self:GetChecked() and true or false
        if type(dbModule.SetEnabled) == "function" then
            dbModule:SetEnabled(self:GetChecked())
        end
        applyPanels()
        if ns.RefreshCurrentPage then
            ns.RefreshCurrentPage()
        end
    end)

    local availableBrokerNames = type(dbModule.GetAvailableBrokerNames) == "function" and (dbModule:GetAvailableBrokerNames() or {}) or {}
    if #availableBrokerNames == 0 then
        availableBrokerNames = GetCustomBrokerNames()
    end

    if #availableBrokerNames > 0 then
        wipe(db.availableBrokerCache)
        for _, brokerName in ipairs(availableBrokerNames) do
            db.availableBrokerCache[#db.availableBrokerCache + 1] = brokerName
        end
    elseif #db.availableBrokerCache > 0 then
        availableBrokerNames = {}
        for _, brokerName in ipairs(db.availableBrokerCache) do
            availableBrokerNames[#availableBrokerNames + 1] = brokerName
        end
    end

    local panelEntries = {
        { key = "new", label = "New Panel" },
    }

    for i, cfg in ipairs(db.bars) do
        local panelCfg = EnsurePanelConfig(cfg, i)
        db.bars[i] = panelCfg
        local panelName = Trim(panelCfg.name)
        if panelName == "" then
            panelName = "Panel " .. tostring(i)
        end
        panelEntries[#panelEntries + 1] = {
            key = "panel:" .. tostring(i),
            index = i,
            label = panelName,
        }
    end

    local brokerEntries = {}
    for _, brokerName in ipairs(availableBrokerNames) do
        brokerEntries[#brokerEntries + 1] = {
            key = "broker:" .. tostring(brokerName),
            brokerName = tostring(brokerName),
            label = tostring(brokerName),
        }
    end

    local selectedKey = db.selectedEntityKey
    if type(selectedKey) ~= "string" or selectedKey == "" then
        selectedKey = db.selectedPanelKey
    end
    local found = false
    for _, entry in ipairs(panelEntries) do
        if entry.key == selectedKey then
            found = true
            break
        end
    end
    if not found then
        for _, entry in ipairs(brokerEntries) do
            if entry.key == selectedKey then
                found = true
                break
            end
        end
    end
    if not found then
        selectedKey = "new"
        db.selectedPanelKey = "new"
    end
    db.selectedEntityKey = selectedKey

    local panelRowRefs = {}
    local brokerRowRefs = {}
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

        if ref.kind == "panel" and ref.panelCfg and ref.panelCfg.enabled == false then
            ref.text:SetTextColor(C.GRAY.r, C.GRAY.g, C.GRAY.b, 0.8)
        else
            ref.text:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        end
    end

    local function UpdateLeftSelectionVisuals()
        local current = db.selectedEntityKey
        for _, ref in ipairs(panelRowRefs) do
            ApplyRowVisual(ref, ref.key == current)
        end
        for _, ref in ipairs(brokerRowRefs) do
            ApplyRowVisual(ref, ref.key == current)
        end
    end

    local function SelectEntity(entityKey, panelKey)
        db.selectedEntityKey = entityKey
        if panelKey then
            db.selectedPanelKey = panelKey
        end
        selectedKey = entityKey
        UpdateLeftSelectionVisuals()
        if RenderRightPane then
            RenderRightPane()
        end
    end

    local function CreateScrollableSection(parentFrame, anchorFrame, sectionKey, titleText, entries, rowBuilder, emptyText, topOffset)
        local section = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
        local offsetY = type(topOffset) == "number" and topOffset or -10
        section:SetPoint("TOPLEFT", anchorFrame, anchorFrame == parentFrame and "TOPLEFT" or "BOTTOMLEFT", 0, offsetY)
        section:SetPoint("TOPRIGHT", anchorFrame, anchorFrame == parentFrame and "TOPRIGHT" or "BOTTOMRIGHT", 0, offsetY)
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
        icon:SetText(db.leftSectionState[sectionKey] and "-" or "+")
        icon:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        ApplyFont(icon, 0)

        local hdrText = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hdrText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        hdrText:SetText(titleText)
        hdrText:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        ApplyFont(hdrText, 0)

        headerBtn:SetScript("OnClick", function()
            db.leftSectionState[sectionKey] = not db.leftSectionState[sectionKey]
            refreshPage()
        end)

        if not db.leftSectionState[sectionKey] then
            section:SetHeight(30)
            return section, 30
        end

        local content = CreateFrame("Frame", nil, section)
        content:SetPoint("TOPLEFT", headerBtn, "BOTTOMLEFT", 0, -4)
        content:SetPoint("TOPRIGHT", headerBtn, "BOTTOMRIGHT", 0, -4)

        local rowCount = #entries
        local useEmpty = rowCount == 0 and emptyText
        local fullRows = useEmpty and 1 or rowCount
        local visibleRows = 8
        local rowHeight = 30
        local rowGap = 4
        local viewHeight = (visibleRows * rowHeight) + ((visibleRows - 1) * rowGap)
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
            ApplyFont(emptyLabel, -1)
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
        return section, sectionHeight
    end

    local function BuildPanelRow(parentFrame, entry)
        local row = CreateFrame("Button", nil, parentFrame, "BackdropTemplate")
        row:SetHeight(30)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", row, "LEFT", 10, 0)
        text:SetPoint("RIGHT", row, "RIGHT", -34, 0)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
        text:SetText(entry.label)
        ApplyFont(text, -1)

        local panelCfg = nil
        if entry.index then
            panelCfg = db.bars[entry.index]
            local toggle = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            toggle:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            toggle:SetChecked(panelCfg and panelCfg.enabled ~= false)
            toggle:SetScript("OnClick", function(self)
                if panelCfg then
                    panelCfg.enabled = self:GetChecked() and true or false
                    applyPanels()
                    UpdateLeftSelectionVisuals()
                end
            end)
        end

        panelRowRefs[#panelRowRefs + 1] = {
            kind = "panel",
            key = entry.key,
            row = row,
            text = text,
            panelCfg = panelCfg,
        }
        ApplyRowVisual(panelRowRefs[#panelRowRefs], entry.key == db.selectedEntityKey)

        row:SetScript("OnClick", function()
            SelectEntity(entry.key, entry.key)
        end)

        return row
    end

    local function BuildBrokerRow(parentFrame, entry)
        local row = CreateFrame("Button", nil, parentFrame, "BackdropTemplate")
        row:SetHeight(30)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", row, "LEFT", 10, 0)
        text:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
        text:SetText(entry.label)
        ApplyFont(text, -1)

        brokerRowRefs[#brokerRowRefs + 1] = {
            kind = "broker",
            key = entry.key,
            row = row,
            text = text,
        }
        ApplyRowVisual(brokerRowRefs[#brokerRowRefs], entry.key == db.selectedEntityKey)

        row:SetScript("OnClick", function()
            SelectEntity(entry.key, nil)
        end)

        return row
    end

    local panelsSection, panelsSectionHeight = CreateScrollableSection(
        leftPane,
        leftPane,
        "panels",
        "Panels",
        panelEntries,
        BuildPanelRow,
        nil,
        0
    )

    local _, brokersSectionHeight = CreateScrollableSection(
        leftPane,
        panelsSection,
        "databrokers",
        "DataBrokers",
        brokerEntries,
        BuildBrokerRow,
        "No DataBrokers found"
    )

    local listHeight = 28 + 10 + panelsSectionHeight + 10 + brokersSectionHeight + 8
    leftPane:SetHeight(math.max(180, listHeight))

    local draftCfg = EnsureDraftConfig(db)

    local brokerItems = { { value = "", label = "None" } }
    for _, name in ipairs(availableBrokerNames) do
        brokerItems[#brokerItems + 1] = { value = name, label = name }
    end

    local fontItems = BuildFontItems(LSM)
    local BuildSizeSubpanel
    local BuildPositionSubpanel
    local BuildFontSubpanel
    local BuildBackgroundSubpanel
    local BuildStrataSubpanel

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

        local currentKey = db.selectedEntityKey or "new"
        local selectedIndex = nil
        if currentKey ~= "new" then
            selectedIndex = tonumber(string.match(currentKey, "^panel:(%d+)$"))
        end

        local selectedBrokerName = string.match(currentKey, "^broker:(.+)$")
        local selectedCfg = nil
        if selectedIndex and db.bars[selectedIndex] then
            selectedCfg = EnsurePanelConfig(db.bars[selectedIndex], selectedIndex)
            db.bars[selectedIndex] = selectedCfg
        end

        local rightLast
        local rightTotal = 0

        local function AddSubPanel(sectionId, titleText, buildFn, defaultOpen)
            local stateKey = tostring(currentKey) .. ":" .. tostring(sectionId)
            local isOpen = db.panelSectionState[stateKey]
            if isOpen == nil then
                isOpen = defaultOpen ~= false
            end

            local card, cardContent, head = CreateCard(rightPane, titleText, C, W, isOpen)
            if rightLast then
                card:SetPoint("TOPLEFT", rightLast, "BOTTOMLEFT", 0, -8)
                card:SetPoint("TOPRIGHT", rightLast, "BOTTOMRIGHT", 0, -8)
                rightTotal = rightTotal + 8
            else
                card:SetPoint("TOPLEFT", rightPane, "TOPLEFT", 0, 0)
                card:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", 0, 0)
            end

            head:SetScript("OnClick", function()
                db.panelSectionState[stateKey] = not card.open
                RenderRightPane()
            end)

            local b = W.Builder(cardContent, { startY = 8, padX = 8 })
            buildFn(b)
            local innerHeight = b:Finalize()
            cardContent:SetHeight(innerHeight)

            local cardHeight = 30
            if card.open then
                cardHeight = cardHeight + innerHeight + 6
            end
            card:SetHeight(cardHeight)

            rightTotal = rightTotal + cardHeight
            rightLast = card
        end

        if currentKey == "new" then
            AddSubPanel("newPanel", "New Panel", function(b)
                b:Input("Name",
                    function() return draftCfg.name or "" end,
                    function(v)
                        draftCfg.name = tostring(v or "")
                    end)

                b:Button("Add", function()
                    local createName = Trim(draftCfg.name)
                    local newIndex = nil
                    if type(dbModule.CreateNamedBar) == "function" then
                        newIndex = dbModule:CreateNamedBar(createName, draftCfg.maxBrokers, draftCfg)
                    end
                    if newIndex then
                        db.selectedPanelKey = "panel:" .. tostring(newIndex)
                        db.selectedEntityKey = db.selectedPanelKey
                        selectedKey = db.selectedEntityKey
                        applyPanels()
                        refreshPage()
                    end
                end)
            end, true)

            AddSubPanel("size", "Size", function(b)
                BuildSizeSubpanel(b, draftCfg, false)
            end, true)

            AddSubPanel("font", "Font", function(b)
                BuildFontSubpanel(b, draftCfg, false)
            end, true)

            AddSubPanel("background", "Background", function(b)
                BuildBackgroundSubpanel(b, draftCfg, false)
            end, true)

            AddSubPanel("strata", "Strata", function(b)
                BuildStrataSubpanel(b, draftCfg, false)
            end, true)
        elseif selectedCfg then
            AddSubPanel("databrokers", "DataBrokers", function(b)
                for slot = 1, selectedCfg.maxBrokers do
                    b:Cycle("DataBroker " .. tostring(slot),
                        function() return brokerItems end,
                        function() return selectedCfg.brokers[slot] or "" end,
                        function(v)
                            if v == "" then
                                selectedCfg.brokers[slot] = nil
                            else
                                selectedCfg.brokers[slot] = v
                            end
                            applyPanels()
                        end,
                        0,
                        300,
                        true)
                end
            end, true)

            AddSubPanel("position", "Position", function(b)
                BuildPositionSubpanel(b, selectedCfg, true)
            end, true)

            AddSubPanel("size", "Size", function(b)
                BuildSizeSubpanel(b, selectedCfg, true)
            end, true)

            AddSubPanel("font", "Font", function(b)
                BuildFontSubpanel(b, selectedCfg, true)
            end, true)

            AddSubPanel("background", "Background", function(b)
                BuildBackgroundSubpanel(b, selectedCfg, true)
            end, true)

            AddSubPanel("strata", "Strata", function(b)
                BuildStrataSubpanel(b, selectedCfg, true)
            end, true)
        elseif selectedBrokerName then
            local brokerCfg = type(dbModule.GetBrokerDisplayConfig) == "function" and dbModule:GetBrokerDisplayConfig(selectedBrokerName) or nil
            if brokerCfg then
                AddSubPanel("display", "Display: " .. selectedBrokerName, function(b)
                    b:Toggle("Show Icon",
                        function() return brokerCfg.showIcon ~= false end,
                        function(v)
                            brokerCfg.showIcon = v and true or false
                            applyPanels()
                        end)

                    b:Toggle("Show Label",
                        function() return brokerCfg.showLabel ~= false end,
                        function(v)
                            brokerCfg.showLabel = v and true or false
                            applyPanels()
                        end)

                    b:Toggle("Show Text",
                        function() return brokerCfg.showText ~= false end,
                        function(v)
                            brokerCfg.showText = v and true or false
                            applyPanels()
                        end)
                end, true)
            end
        end

        rightPane:SetHeight(math.max(1, rightTotal))

        local bodyHeight = math.max(leftPane:GetHeight(), rightTotal)
        body:SetHeight(math.max(180, bodyHeight))

        root:SetHeight(84 + body:GetHeight())
        parent:SetHeight(110 + body:GetHeight())
    end

    BuildSizeSubpanel = function(b, cfg, applyNow)
        b:Range("Number of DataBrokers", 1, 10, 1,
            function()
                return cfg.maxBrokers
            end,
            function(v)
                cfg.maxBrokers = Clamp(v, 1, 10, cfg.maxBrokers)
                if #cfg.brokers > cfg.maxBrokers then
                    for i = cfg.maxBrokers + 1, #cfg.brokers do
                        cfg.brokers[i] = nil
                    end
                end
                if applyNow then
                    applyPanels()
                end
                refreshPage()
            end)

        b:Input("Width",
            function() return tostring(cfg.width) end,
            function(v)
                cfg.width = Clamp(v, 120, 2400, cfg.width)
                if applyNow then
                    applyPanels()
                end
            end)

        b:Input("Height",
            function() return tostring(cfg.height) end,
            function(v)
                cfg.height = Clamp(v, 12, 128, cfg.height)
                if applyNow then
                    applyPanels()
                end
            end)

        b:Cycle("Text Justification",
            function() return JUSTIFY_ITEMS end,
            function() return cfg.textJustify end,
            function(v)
                local value = type(v) == "string" and string.upper(v) or "CENTER"
                if value ~= "LEFT" and value ~= "CENTER" and value ~= "RIGHT" then
                    value = "CENTER"
                end
                cfg.textJustify = value
                if applyNow then
                    applyPanels()
                end
            end,
            0,
            180)
    end

    BuildPositionSubpanel = function(b, cfg, applyNow)
        local function IsValidAnchorPanelName(name)
            if type(name) ~= "string" or name == "" or name == "UIParent" then
                return true
            end
            local anchorObject = rawget(_G, name)
            return anchorObject and type(anchorObject.GetObjectType) == "function"
        end

        local row = CreateFrame("Frame", nil, b.parent, "BackdropTemplate")
        row:SetHeight(34)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        row:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.14)
        row:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

        local customCheck = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        customCheck:SetPoint("LEFT", row, "LEFT", 8, 0)
        customCheck:SetChecked(cfg.customAnchor and true or false)

        local checkLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        checkLabel:SetPoint("LEFT", customCheck, "RIGHT", 2, 0)
        checkLabel:SetText("Custom Anchor")
        checkLabel:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        ApplyFont(checkLabel, -1)

        local anchorLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        anchorLabel:SetPoint("LEFT", checkLabel, "RIGHT", 14, 0)
        anchorLabel:SetText("Anchor Panel")
        anchorLabel:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        ApplyFont(anchorLabel, -1)

        local anchorEdit = CreateFrame("EditBox", nil, row, "BackdropTemplate")
        anchorEdit:SetHeight(22)
        anchorEdit:SetPoint("LEFT", anchorLabel, "RIGHT", 8, 0)
        anchorEdit:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        anchorEdit:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        anchorEdit:SetAutoFocus(false)
        anchorEdit:SetMaxLetters(64)
        anchorEdit:SetTextInsets(6, 6, 0, 0)
        ApplyFont(anchorEdit, -1)

        local warnRow = CreateFrame("Frame", nil, b.parent)
        warnRow:SetHeight(16)

        local warnText = warnRow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        warnText:SetPoint("TOPLEFT", warnRow, "TOPLEFT", 2, 0)
        warnText:SetPoint("TOPRIGHT", warnRow, "TOPRIGHT", -2, 0)
        warnText:SetJustifyH("LEFT")
        warnText:SetWordWrap(true)
        ApplyFont(warnText, -1)

        local function RefreshAnchorEdit()
            local custom = cfg.customAnchor and true or false
            if custom then
                anchorEdit:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
                anchorEdit:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.55)
                anchorEdit:SetTextColor(1, 1, 1, 0.9)
                anchorEdit:EnableMouse(true)
                anchorEdit:SetText(cfg.anchorPanel or "UIParent")

                if IsValidAnchorPanelName(cfg.anchorPanel) then
                    warnText:SetText("")
                else
                    warnText:SetText("|cffffc777Anchor frame not found. Falling back to UIParent.|r")
                end
            else
                anchorEdit:SetBackdropColor(0.03, 0.03, 0.03, 0.8)
                anchorEdit:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.25)
                anchorEdit:SetTextColor(C.GRAY.r, C.GRAY.g, C.GRAY.b, 0.9)
                anchorEdit:EnableMouse(false)
                anchorEdit:SetText("UIParent")
                warnText:SetText("")
            end
        end

        customCheck:SetScript("OnClick", function(self)
            cfg.customAnchor = self:GetChecked() and true or false
            if not cfg.customAnchor then
                cfg.anchorPanel = "UIParent"
            else
                cfg.anchorPanel = Trim(cfg.anchorPanel)
                if cfg.anchorPanel == "" then
                    cfg.anchorPanel = "UIParent"
                end
            end
            RefreshAnchorEdit()
            if applyNow then
                applyPanels()
            end
        end)

        anchorEdit:SetScript("OnEnterPressed", function(self)
            if cfg.customAnchor then
                local value = Trim(self:GetText())
                cfg.anchorPanel = (value ~= "") and value or "UIParent"
                if applyNow then
                    applyPanels()
                end
            else
                cfg.anchorPanel = "UIParent"
            end
            RefreshAnchorEdit()
            self:ClearFocus()
        end)

        anchorEdit:SetScript("OnEscapePressed", function(self)
            RefreshAnchorEdit()
            self:ClearFocus()
        end)

        RefreshAnchorEdit()
        b:_Attach(row, 34, 4)
        b:_Attach(warnRow, 16, 2)

        b:Cycle("Panel Anchor",
            function() return POINT_ITEMS end,
            function() return cfg.point or "CENTER" end,
            function(v)
                cfg.point = type(v) == "string" and string.upper(v) or "CENTER"
                if applyNow then
                    applyPanels()
                end
            end,
            0,
            180)

        b:Cycle("Relative Anchor",
            function() return POINT_ITEMS end,
            function() return cfg.relativePoint or "CENTER" end,
            function(v)
                cfg.relativePoint = type(v) == "string" and string.upper(v) or "CENTER"
                if applyNow then
                    applyPanels()
                end
            end,
            0,
            180)

        local offsetRow = CreateFrame("Frame", nil, b.parent, "BackdropTemplate")
        offsetRow:SetHeight(34)
        offsetRow:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        offsetRow:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.14)
        offsetRow:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

        local xLabel = offsetRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        xLabel:SetPoint("LEFT", offsetRow, "LEFT", 10, 0)
        xLabel:SetText("X Offset")
        xLabel:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        ApplyFont(xLabel, -1)

        local xEdit = CreateFrame("EditBox", nil, offsetRow, "BackdropTemplate")
        xEdit:SetHeight(22)
        xEdit:SetPoint("LEFT", xLabel, "RIGHT", 8, 0)
        xEdit:SetWidth(90)
        xEdit:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        xEdit:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        xEdit:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.55)
        xEdit:SetAutoFocus(false)
        xEdit:SetMaxLetters(8)
        xEdit:SetTextInsets(6, 6, 0, 0)
        ApplyFont(xEdit, -1)

        local yLabel = offsetRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        yLabel:SetPoint("LEFT", xEdit, "RIGHT", 14, 0)
        yLabel:SetText("Y Offset")
        yLabel:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        ApplyFont(yLabel, -1)

        local yEdit = CreateFrame("EditBox", nil, offsetRow, "BackdropTemplate")
        yEdit:SetHeight(22)
        yEdit:SetPoint("LEFT", yLabel, "RIGHT", 8, 0)
        yEdit:SetWidth(90)
        yEdit:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        yEdit:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        yEdit:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.55)
        yEdit:SetAutoFocus(false)
        yEdit:SetMaxLetters(8)
        yEdit:SetTextInsets(6, 6, 0, 0)
        ApplyFont(yEdit, -1)

        local function RefreshOffsets()
            xEdit:SetText(tostring(cfg.x or 0))
            yEdit:SetText(tostring(cfg.y or 0))
        end

        xEdit:SetScript("OnEnterPressed", function(self)
            cfg.x = Clamp(self:GetText(), -4000, 4000, cfg.x or 0)
            RefreshOffsets()
            if applyNow then
                applyPanels()
            end
            self:ClearFocus()
        end)
        xEdit:SetScript("OnEscapePressed", function(self)
            RefreshOffsets()
            self:ClearFocus()
        end)

        yEdit:SetScript("OnEnterPressed", function(self)
            cfg.y = Clamp(self:GetText(), -4000, 4000, cfg.y or 0)
            RefreshOffsets()
            if applyNow then
                applyPanels()
            end
            self:ClearFocus()
        end)
        yEdit:SetScript("OnEscapePressed", function(self)
            RefreshOffsets()
            self:ClearFocus()
        end)

        RefreshOffsets()
        b:_Attach(offsetRow, 34, 4)
    end

    BuildFontSubpanel = function(b, cfg, applyNow)
        b:Toggle("Override",
            function() return cfg.fontOverride end,
            function(v)
                cfg.fontOverride = v and true or false
                if applyNow then
                    applyPanels()
                end
            end)

        b:Cycle("Font",
            function() return fontItems end,
            function() return cfg.font or "" end,
            function(v)
                cfg.font = v or ""
                if applyNow then
                    applyPanels()
                end
            end,
            0,
            260,
            true)

        b:Cycle("Font Outline",
            function() return OUTLINE_ITEMS end,
            function() return cfg.fontOutline or "NONE" end,
            function(v)
                cfg.fontOutline = type(v) == "string" and string.upper(v) or "NONE"
                if applyNow then
                    applyPanels()
                end
            end,
            0,
            200)

        b:Input("Size",
            function() return tostring(cfg.fontSize or 12) end,
            function(v)
                cfg.fontSize = Clamp(v, 6, 64, cfg.fontSize or 12)
                if applyNow then
                    applyPanels()
                end
            end)
    end

    BuildBackgroundSubpanel = function(b, cfg, applyNow)
        b:Toggle("Show Background",
            function() return cfg.showBackdrop end,
            function(v)
                cfg.showBackdrop = v and true or false
                if applyNow then
                    applyPanels()
                end
            end)

        b:Toggle("Show Border",
            function() return cfg.showBorder end,
            function(v)
                cfg.showBorder = v and true or false
                if applyNow then
                    applyPanels()
                end
            end)
    end

    BuildStrataSubpanel = function(b, cfg, applyNow)
        b:Cycle("Frame Strata",
            function() return STRATA_ITEMS end,
            function() return cfg.frameStrata or "LOW" end,
            function(v)
                cfg.frameStrata = type(v) == "string" and string.upper(v) or "LOW"
                if applyNow then
                    applyPanels()
                end
            end,
            0,
            220)

        b:Range("Frame Level", 1, 10, 1,
            function() return cfg.frameLevel or 1 end,
            function(v)
                cfg.frameLevel = Clamp(v, 1, 10, cfg.frameLevel or 1)
                if applyNow then
                    applyPanels()
                end
            end)
    end

    UpdateLeftSelectionVisuals()
    RenderRightPane()

    ns.RefreshCurrentPage = refreshPage
end
