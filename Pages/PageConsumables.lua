local ADDON_NAME, ns = ...

local SECTION_ORDER = {
    "global",
    "healthPotion",
    "combatPotion",
    "flask",
    "oil",
    "food",
    "feast",
    "battleRes",
}

local SECTION_LABELS = {
    global = "Global Options",
    healthPotion = "Health Potions",
    combatPotion = "Combat Potions",
    flask = "Flasks",
    oil = "Oil",
    food = "Food",
    feast = "Feasts",
    battleRes = "Battle Rez",
}

local TRACKING_SECTIONS = {
    "healthPotion",
    "combatPotion",
    "flask",
    "oil",
    "food",
    "feast",
    "battleRes",
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

local GROW_ITEMS = {
    { value = "LEFT", label = "Left" },
    { value = "RIGHT", label = "Right" },
    { value = "UP", label = "Up" },
    { value = "DOWN", label = "Down" },
    { value = "CENTER_HORIZONTAL", label = "Center Horizontal" },
    { value = "CENTER_VERTICAL", label = "Center Vertical" },
}

local FLASK_ITEMS = {
    { value = "crit", label = "Crit" },
    { value = "haste", label = "Haste" },
    { value = "mastery", label = "Mastery" },
    { value = "versatility", label = "Versatility" },
}

local COMBAT_POTION_ITEMS = {
    { value = "lights_potential", label = "Light's Potential" },
    { value = "recklessness", label = "Recklessness" },
}

local ALERT_COUNT_SOURCE_ITEMS = {
    { value = "TOTAL", label = "Total Count" },
    { value = "HIGHEST_QUALITY", label = "Highest Quality Count" },
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

local function Trim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function NormalizePoint(value, fallback)
    if type(value) ~= "string" then
        return fallback
    end

    local upper = string.upper(value)
    for _, point in ipairs(POINT_ITEMS) do
        if upper == point.value then
            return point.value
        end
    end

    return fallback
end

local function CreateCard(parent, titleText, C, W, startOpen)
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
    label:SetText(titleText)
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

local function GetDefaultFontConfig(Addon)
    local fallbackFont = ""
    local fallbackSize = 12

    if Addon and type(Addon.GetResolvedMediaConfig) == "function" then
        local media = Addon:GetResolvedMediaConfig("databrokers") or {}
        fallbackFont = type(media.font) == "string" and media.font or ""
        fallbackSize = Clamp(media.fontSize, 6, 64, 12)
    elseif Addon and type(Addon.GetModuleMediaConfig) == "function" then
        local media = Addon:GetModuleMediaConfig("databrokers") or {}
        fallbackFont = type(media.font) == "string" and media.font or ""
        fallbackSize = Clamp(media.fontSize, 6, 64, 12)
    end

    return fallbackFont, fallbackSize
end

local function GetConsumablesConfig(Addon)
    Addon.db.Consumables = type(Addon.db.Consumables) == "table" and Addon.db.Consumables or {}
    local cfg = Addon.db.Consumables
    local fallbackFont, fallbackSize = GetDefaultFontConfig(Addon)

    cfg.enabled = cfg.enabled ~= false
    cfg.hideInCombat = cfg.hideInCombat and true or false
    cfg.hideInEncounter = cfg.hideInEncounter and true or false
    cfg.selectedSectionKey = type(cfg.selectedSectionKey) == "string" and cfg.selectedSectionKey or "global"
    if SECTION_LABELS[cfg.selectedSectionKey] == nil then
        cfg.selectedSectionKey = "global"
    end

    cfg.customAnchor = cfg.customAnchor and true or false
    cfg.anchorPanel = type(cfg.anchorPanel) == "string" and Trim(cfg.anchorPanel) or "UIParent"
    if cfg.anchorPanel == "" then
        cfg.anchorPanel = "UIParent"
    end
    if not cfg.customAnchor then
        cfg.anchorPanel = "UIParent"
    end
    cfg.point = NormalizePoint(cfg.point, "CENTER")
    cfg.relativePoint = NormalizePoint(cfg.relativePoint, "CENTER")
    cfg.x = Clamp(cfg.x, -4000, 4000, 0)
    cfg.y = Clamp(cfg.y, -4000, 4000, 0)
    cfg.font = type(cfg.font) == "string" and cfg.font or fallbackFont
    cfg.fontSize = Clamp(cfg.fontSize, 6, 64, fallbackSize)
    cfg.fontOutline = type(cfg.fontOutline) == "string" and string.upper(cfg.fontOutline) or "NONE"
    if cfg.fontOutline ~= "NONE" and cfg.fontOutline ~= "OUTLINE" and cfg.fontOutline ~= "THICKOUTLINE" and cfg.fontOutline ~= "MONOCHROME" then
        cfg.fontOutline = "NONE"
    end
    cfg.grow = type(cfg.grow) == "string" and string.upper(cfg.grow) or "RIGHT"
    if cfg.grow ~= "LEFT" and cfg.grow ~= "RIGHT" and cfg.grow ~= "UP" and cfg.grow ~= "DOWN" and cfg.grow ~= "CENTER_HORIZONTAL" and cfg.grow ~= "CENTER_VERTICAL" then
        cfg.grow = "RIGHT"
    end
    cfg.iconWidth = Clamp(cfg.iconWidth, 16, 128, 36)
    cfg.iconHeight = Clamp(cfg.iconHeight, 16, 128, 36)
    cfg.iconGap = Clamp(cfg.iconGap, 0, 32, 4)
    cfg.qualitySize = Clamp(cfg.qualitySize, 8, 48, 12)
    cfg.battleRes = type(cfg.battleRes) == "table" and cfg.battleRes or {}
    cfg.battleRes.disableIfClassHasSpell = cfg.battleRes.disableIfClassHasSpell and true or false
    cfg.tracking = type(cfg.tracking) == "table" and cfg.tracking or {}
    cfg.flask = type(cfg.flask) == "table" and cfg.flask or {}
    cfg.flask.defaultType = type(cfg.flask.defaultType) == "string" and string.lower(cfg.flask.defaultType) or "crit"
    cfg.flask.specOverrides = type(cfg.flask.specOverrides) == "table" and cfg.flask.specOverrides or {}

    local validFlask = {
        crit = true,
        haste = true,
        mastery = true,
        versatility = true,
    }

    if not validFlask[cfg.flask.defaultType] then
        cfg.flask.defaultType = "crit"
    end

    for specID, value in pairs(cfg.flask.specOverrides) do
        local v = type(value) == "string" and string.lower(value) or ""
        if not validFlask[v] then
            cfg.flask.specOverrides[specID] = nil
        else
            cfg.flask.specOverrides[specID] = v
        end
    end

    cfg.combatPotion = type(cfg.combatPotion) == "table" and cfg.combatPotion or {}
    cfg.combatPotion.defaultType = type(cfg.combatPotion.defaultType) == "string" and string.lower(cfg.combatPotion.defaultType) or "lights_potential"
    cfg.combatPotion.specOverrides = type(cfg.combatPotion.specOverrides) == "table" and cfg.combatPotion.specOverrides or {}

    local validCombatPotion = {
        lights_potential = true,
        recklessness = true,
    }

    if not validCombatPotion[cfg.combatPotion.defaultType] then
        cfg.combatPotion.defaultType = "lights_potential"
    end

    for specID, value in pairs(cfg.combatPotion.specOverrides) do
        local v = type(value) == "string" and string.lower(value) or ""
        if not validCombatPotion[v] then
            cfg.combatPotion.specOverrides[specID] = nil
        else
            cfg.combatPotion.specOverrides[specID] = v
        end
    end

    cfg.sectionCards = type(cfg.sectionCards) == "table" and cfg.sectionCards or {}

    for _, key in ipairs(TRACKING_SECTIONS) do
        if cfg.tracking[key] == nil then
            cfg.tracking[key] = true
        else
            cfg.tracking[key] = cfg.tracking[key] and true or false
        end
    end

    cfg.alerts = type(cfg.alerts) == "table" and cfg.alerts or {}
    for _, key in ipairs(TRACKING_SECTIONS) do
        cfg.alerts[key] = type(cfg.alerts[key]) == "table" and cfg.alerts[key] or {}
        local alert = cfg.alerts[key]

        if alert.enabled == nil then
            alert.enabled = true
        else
            alert.enabled = alert.enabled and true or false
        end
        alert.minCount = Clamp(alert.minCount, 0, 100000, 5)

        local source = type(alert.countSource) == "string" and string.upper(alert.countSource) or "TOTAL"
        if source ~= "TOTAL" and source ~= "HIGHEST_QUALITY" then
            source = "TOTAL"
        end
        if key == "food" or key == "feast" then
            source = "TOTAL"
        end
        alert.countSource = source
    end

    return cfg
end

local function ApplyFont(W, fontPath, fontSize, fontOutline, target)
    if not target then
        return
    end

    if W and W.ApplyFont then
        W.ApplyFont(target, 0)
    end

    if fontPath and type(target.SetFont) == "function" then
        target:SetFont(fontPath, fontSize or 12, fontOutline or "")
    end
end

local function MakePointItems()
    local items = {}
    for _, point in ipairs(POINT_ITEMS) do
        items[#items + 1] = { value = point.value, label = point.label }
    end
    return items
end

local function MakeFontItems(LSM)
    local items = { { value = "", label = "None" } }
    if LSM and type(LSM.List) == "function" then
        for _, name in ipairs(LSM:List("font") or {}) do
            items[#items + 1] = { value = name, label = name }
        end
    end
    return items
end

local function MakeSectionRows(module, cfg)
    local rows = {}
    for _, key in ipairs(SECTION_ORDER) do
        rows[#rows + 1] = {
            key = key,
            label = SECTION_LABELS[key],
            enabled = key == "global" or cfg.tracking[key] ~= false,
        }
    end
    return rows
end

function ns:InitConsumablesPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    local parent = ns.OptionsFrame.Content
    local W = ns.OptionsWidgets
    local C = ns.OptionsColors
    local Addon = (type(ns.GetAddon) == "function" and ns.GetAddon()) or ns.Addon
    local module = Addon and Addon.GetModule and Addon:GetModule("Consumables") or nil
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

    local function refreshModule()
        local refresh = module and module.Refresh
        if type(refresh) == "function" then
            refresh(module)
        end
    end

    if not Addon or not module then
        local b = W.Builder(parent)
        b:Header("Consumables")
        b:Desc("Track hard-coded consumable items and display them as icon rows.")
        b:Desc("|cffff7777Consumables module is unavailable.|r")
        b:Finalize()
        return
    end

    local cfg = GetConsumablesConfig(Addon)
    local selectedKey = cfg.selectedSectionKey or "global"

    local root = CreateFrame("Frame", nil, parent)
    root:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    root:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
    root:SetHeight(1)

    local title = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 2, -2)
    title:SetText("Consumables")
    title:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    ApplyFont(W, nil, nil, nil, title)

    local subtitle = root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetPoint("TOPRIGHT", root, "TOPRIGHT", -2, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWordWrap(true)
    subtitle:SetText("Use the left panel to pick a section. Global Options control icon display and each section contains its own configuration.")
    ApplyFont(W, nil, nil, nil, subtitle)

    local enableRow = CreateFrame("Frame", nil, root, "BackdropTemplate")
    enableRow:SetHeight(30)
    enableRow:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
    enableRow:SetPoint("TOPRIGHT", subtitle, "BOTTOMRIGHT", 0, -10)
    enableRow:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    enableRow:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.06)
    enableRow:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

    local enableLabel = enableRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    enableLabel:SetPoint("LEFT", enableRow, "LEFT", 10, 0)
    enableLabel:SetText("Enable Consumables")
    enableLabel:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
    ApplyFont(W, nil, nil, nil, enableLabel)

    local enableToggle = CreateFrame("CheckButton", nil, enableRow, "UICheckButtonTemplate")
    enableToggle:SetPoint("RIGHT", enableRow, "RIGHT", -8, 0)
    enableToggle:SetChecked(cfg.enabled)
    enableToggle:SetScript("OnClick", function(self)
        cfg.enabled = self:GetChecked() and true or false
        refreshModule()
    end)

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

    local leftCard, leftContent = CreateCard(leftPane, "Sections", C, W, true)
    leftCard:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 0, 0)
    leftCard:SetPoint("TOPRIGHT", leftPane, "TOPRIGHT", 0, 0)

    local sectionRows = MakeSectionRows(module, cfg)
    local rowRefs = {}

    local function updateRowStyles()
        for _, ref in ipairs(rowRefs) do
            if ref.key == selectedKey then
                ref.row:SetBackdropColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.2)
                ref.row:SetBackdropBorderColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.85)
                ref.text:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
            else
                ref.row:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.12)
                ref.row:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)
                if ref.key ~= "global" and cfg.tracking[ref.key] == false then
                    ref.text:SetTextColor(C.GRAY.r, C.GRAY.g, C.GRAY.b, 0.8)
                else
                    ref.text:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
                end
            end
        end
    end

    local function selectSection(sectionKey)
        selectedKey = sectionKey
        cfg.selectedSectionKey = sectionKey
        updateRowStyles()
        RefreshRightPane()
        refreshModule()
    end

    local function buildLeftRow(parentFrame, entry)
        local row = CreateFrame("Button", nil, parentFrame, "BackdropTemplate")
        row:SetHeight(30)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

        local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("LEFT", row, "LEFT", 10, 0)
        text:SetPoint("RIGHT", row, "RIGHT", -34, 0)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
        text:SetText(entry.label)
        ApplyFont(W, nil, nil, nil, text)

        local toggle
        if entry.key ~= "global" then
            toggle = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            toggle:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            toggle:SetChecked(entry.enabled ~= false)
            toggle:SetScript("OnClick", function(self)
                cfg.tracking[entry.key] = self:GetChecked() and true or false
                refreshModule()
                RefreshRightPane()
                updateRowStyles()
            end)
        end

        rowRefs[#rowRefs + 1] = {
            key = entry.key,
            row = row,
            text = text,
        }

        row:SetScript("OnClick", function()
            selectSection(entry.key)
        end)

        return row
    end

    local lastRow
    for _, entry in ipairs(sectionRows) do
        local row = buildLeftRow(leftContent, entry)
        if lastRow then
            row:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", 0, -2)
            row:SetPoint("TOPRIGHT", lastRow, "BOTTOMRIGHT", 0, -2)
        else
            row:SetPoint("TOPLEFT", leftContent, "TOPLEFT", 0, 0)
            row:SetPoint("TOPRIGHT", leftContent, "TOPRIGHT", 0, 0)
        end
        lastRow = row
    end

    leftCard:SetHeight(30 + (#sectionRows * 32) + 6)
    leftContent:SetHeight((#sectionRows * 32) + 2)

    local function BuildPositionSubpanel(b, panelCfg, applyNow)
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
        customCheck:SetChecked(panelCfg.customAnchor and true or false)

        local checkLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        checkLabel:SetPoint("LEFT", customCheck, "RIGHT", 2, 0)
        checkLabel:SetText("Custom Anchor")
        checkLabel:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        ApplyFont(W, nil, nil, nil, checkLabel)

        local anchorLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        anchorLabel:SetPoint("LEFT", checkLabel, "RIGHT", 14, 0)
        anchorLabel:SetText("Anchor Panel")
        anchorLabel:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        ApplyFont(W, nil, nil, nil, anchorLabel)

        local anchorEdit = CreateFrame("EditBox", nil, row, "BackdropTemplate")
        anchorEdit:SetHeight(22)
        anchorEdit:SetPoint("LEFT", anchorLabel, "RIGHT", 8, 0)
        anchorEdit:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        anchorEdit:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        anchorEdit:SetAutoFocus(false)
        anchorEdit:SetMaxLetters(64)
        anchorEdit:SetTextInsets(6, 6, 0, 0)
        ApplyFont(W, nil, nil, nil, anchorEdit)

        local warnRow = CreateFrame("Frame", nil, b.parent)
        warnRow:SetHeight(16)

        local warnText = warnRow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        warnText:SetPoint("TOPLEFT", warnRow, "TOPLEFT", 2, 0)
        warnText:SetPoint("TOPRIGHT", warnRow, "TOPRIGHT", -2, 0)
        warnText:SetJustifyH("LEFT")
        warnText:SetWordWrap(true)
        ApplyFont(W, nil, nil, nil, warnText)

        local function RefreshAnchorEdit()
            local custom = panelCfg.customAnchor and true or false
            if custom then
                anchorEdit:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
                anchorEdit:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.55)
                anchorEdit:SetTextColor(1, 1, 1, 0.9)
                anchorEdit:EnableMouse(true)
                anchorEdit:SetText(panelCfg.anchorPanel or "UIParent")

                if IsValidAnchorPanelName(panelCfg.anchorPanel) then
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
            panelCfg.customAnchor = self:GetChecked() and true or false
            if not panelCfg.customAnchor then
                panelCfg.anchorPanel = "UIParent"
            else
                panelCfg.anchorPanel = Trim(panelCfg.anchorPanel)
                if panelCfg.anchorPanel == "" then
                    panelCfg.anchorPanel = "UIParent"
                end
            end
            RefreshAnchorEdit()
            if applyNow then
                refreshModule()
            end
        end)

        anchorEdit:SetScript("OnEnterPressed", function(self)
            if panelCfg.customAnchor then
                local value = Trim(self:GetText())
                panelCfg.anchorPanel = (value ~= "") and value or "UIParent"
                if applyNow then
                    refreshModule()
                end
            else
                panelCfg.anchorPanel = "UIParent"
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
            function() return MakePointItems() end,
            function() return panelCfg.point or "CENTER" end,
            function(v)
                panelCfg.point = type(v) == "string" and string.upper(v) or "CENTER"
                if applyNow then
                    refreshModule()
                end
            end,
            0,
            180)

        b:Cycle("Relative Anchor",
            function() return MakePointItems() end,
            function() return panelCfg.relativePoint or "CENTER" end,
            function(v)
                panelCfg.relativePoint = type(v) == "string" and string.upper(v) or "CENTER"
                if applyNow then
                    refreshModule()
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
        ApplyFont(W, nil, nil, nil, xLabel)

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
        ApplyFont(W, nil, nil, nil, xEdit)

        local yLabel = offsetRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        yLabel:SetPoint("LEFT", xEdit, "RIGHT", 14, 0)
        yLabel:SetText("Y Offset")
        yLabel:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        ApplyFont(W, nil, nil, nil, yLabel)

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
        ApplyFont(W, nil, nil, nil, yEdit)

        local function RefreshOffsets()
            xEdit:SetText(tostring(panelCfg.x or 0))
            yEdit:SetText(tostring(panelCfg.y or 0))
        end

        xEdit:SetScript("OnEnterPressed", function(self)
            panelCfg.x = Clamp(self:GetText(), -4000, 4000, panelCfg.x or 0)
            RefreshOffsets()
            if applyNow then
                refreshModule()
            end
            self:ClearFocus()
        end)
        xEdit:SetScript("OnEscapePressed", function(self)
            RefreshOffsets()
            self:ClearFocus()
        end)

        yEdit:SetScript("OnEnterPressed", function(self)
            panelCfg.y = Clamp(self:GetText(), -4000, 4000, panelCfg.y or 0)
            RefreshOffsets()
            if applyNow then
                refreshModule()
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

    local function BuildVisibilitySubpanel(b, panelCfg, applyNow)
        b:Desc("When both options are enabled, encounter visibility takes priority over combat visibility.")

        b:Toggle("Hide in combat",
            function()
                return panelCfg.hideInCombat and true or false
            end,
            function(value)
                panelCfg.hideInCombat = value and true or false
                if applyNow then
                    refreshModule()
                end
            end)

        b:Toggle("Hide in encounter",
            function()
                return panelCfg.hideInEncounter and true or false
            end,
            function(value)
                panelCfg.hideInEncounter = value and true or false
                if applyNow then
                    refreshModule()
                end
            end)
    end

    local function BuildFontSubpanel(b, panelCfg, applyNow)
        local fontItems = MakeFontItems(LSM)

        b:Cycle("Font",
            function() return fontItems end,
            function() return panelCfg.font or "" end,
            function(v)
                panelCfg.font = v or ""
                if applyNow then
                    refreshModule()
                end
            end,
            0,
            260,
            true)

        b:Cycle("Font Outline",
            function() return OUTLINE_ITEMS end,
            function() return panelCfg.fontOutline or "NONE" end,
            function(v)
                panelCfg.fontOutline = type(v) == "string" and string.upper(v) or "NONE"
                if applyNow then
                    refreshModule()
                end
            end,
            0,
            200)

        b:Input("Size",
            function() return tostring(panelCfg.fontSize or 12) end,
            function(v)
                panelCfg.fontSize = Clamp(v, 6, 64, panelCfg.fontSize or 12)
                if applyNow then
                    refreshModule()
                end
            end)

        b:Input("Quality Size",
            function() return tostring(panelCfg.qualitySize or 12) end,
            function(v)
                panelCfg.qualitySize = Clamp(v, 8, 48, panelCfg.qualitySize or 12)
                if applyNow then
                    refreshModule()
                end
            end)
    end

    local function BuildGrowSubpanel(b, panelCfg, applyNow)
        b:Cycle("Grow",
            function() return GROW_ITEMS end,
            function() return panelCfg.grow or "RIGHT" end,
            function(v)
                panelCfg.grow = type(v) == "string" and string.upper(v) or "RIGHT"
                if panelCfg.grow ~= "LEFT" and panelCfg.grow ~= "RIGHT" and panelCfg.grow ~= "UP" and panelCfg.grow ~= "DOWN" and panelCfg.grow ~= "CENTER_HORIZONTAL" and panelCfg.grow ~= "CENTER_VERTICAL" then
                    panelCfg.grow = "RIGHT"
                end
                if applyNow then
                    refreshModule()
                end
            end,
            0,
            260)
    end

    local function BuildIconSizeSubpanel(b, panelCfg, applyNow)
        b:Input("Width",
            function() return tostring(panelCfg.iconWidth or 36) end,
            function(v)
                panelCfg.iconWidth = Clamp(v, 16, 128, panelCfg.iconWidth or 36)
                if applyNow then
                    refreshModule()
                end
            end)

        b:Input("Height",
            function() return tostring(panelCfg.iconHeight or 36) end,
            function(v)
                panelCfg.iconHeight = Clamp(v, 16, 128, panelCfg.iconHeight or 36)
                if applyNow then
                    refreshModule()
                end
            end)

        b:Input("Spacing",
            function() return tostring(panelCfg.iconGap or 4) end,
            function(v)
                panelCfg.iconGap = Clamp(v, 0, 32, panelCfg.iconGap or 4)
                if applyNow then
                    refreshModule()
                end
            end)
    end

    local function BuildFlaskDefaultSubpanel(b)
        b:Desc("Choose the default flask type used when a specialization is set to Default.")
        b:Cycle("Default Flask",
            function()
                if module and type(module.GetFlaskOptionItems) == "function" then
                    return module:GetFlaskOptionItems(false)
                end
                return FLASK_ITEMS
            end,
            function()
                if module and type(module.GetDefaultFlaskType) == "function" then
                    return module:GetDefaultFlaskType()
                end
                return cfg.flask.defaultType or "crit"
            end,
            function(value)
                if module and type(module.SetDefaultFlaskType) == "function" then
                    module:SetDefaultFlaskType(value)
                else
                    cfg.flask.defaultType = value
                    refreshModule()
                end
            end,
            0,
            260,
            true)
    end

    local function BuildFlaskSpecSubpanel(b)
        b:Desc("Set flask type by specialization. Default uses the value from the Default card.")

        if not module or type(module.GetSpecGroups) ~= "function" then
            b:Desc("Spec catalog unavailable.")
            return
        end

        local groups = module:GetSpecGroups()
        for _, classGroup in ipairs(groups) do
            b:Header(classGroup.className, 6)

            for _, specRow in ipairs(classGroup.specs or {}) do
                local specID = tonumber(specRow.specID) or 0
                local label = tostring(specRow.specName)

                b:Cycle(label,
                    function()
                        if module and type(module.GetFlaskOptionItems) == "function" then
                            return module:GetFlaskOptionItems(true)
                        end
                        local items = { { value = "default", label = "Default" } }
                        for _, row in ipairs(FLASK_ITEMS) do
                            items[#items + 1] = row
                        end
                        return items
                    end,
                    function()
                        if module and type(module.GetSpecFlaskOverride) == "function" then
                            return module:GetSpecFlaskOverride(specID)
                        end
                        local key = tostring(specID)
                        return cfg.flask.specOverrides[key] or "default"
                    end,
                    function(value)
                        if module and type(module.SetSpecFlaskOverride) == "function" then
                            module:SetSpecFlaskOverride(specID, value)
                        else
                            local key = tostring(specID)
                            if value == "default" then
                                cfg.flask.specOverrides[key] = nil
                            else
                                cfg.flask.specOverrides[key] = value
                            end
                            refreshModule()
                        end
                    end,
                    2,
                    260,
                    true)
            end
        end
    end

    local function BuildCombatPotionDefaultSubpanel(b)
        b:Desc("Choose the default combat potion type used when a specialization is set to Default.")
        b:Cycle("Default Combat Potion",
            function()
                if module and type(module.GetCombatPotionOptionItems) == "function" then
                    return module:GetCombatPotionOptionItems(false)
                end
                return COMBAT_POTION_ITEMS
            end,
            function()
                if module and type(module.GetDefaultCombatPotionType) == "function" then
                    return module:GetDefaultCombatPotionType()
                end
                return cfg.combatPotion.defaultType or "lights_potential"
            end,
            function(value)
                if module and type(module.SetDefaultCombatPotionType) == "function" then
                    module:SetDefaultCombatPotionType(value)
                else
                    cfg.combatPotion.defaultType = value
                    refreshModule()
                end
            end,
            0,
            260,
            true)
    end

    local function BuildCombatPotionSpecSubpanel(b)
        b:Desc("Set combat potion by specialization. Default uses the value from the Default card.")

        if not module or type(module.GetSpecGroups) ~= "function" then
            b:Desc("Spec catalog unavailable.")
            return
        end

        local groups = module:GetSpecGroups()
        for _, classGroup in ipairs(groups) do
            b:Header(classGroup.className, 6)

            for _, specRow in ipairs(classGroup.specs or {}) do
                local specID = tonumber(specRow.specID) or 0
                local label = tostring(specRow.specName)

                b:Cycle(label,
                    function()
                        if module and type(module.GetCombatPotionOptionItems) == "function" then
                            return module:GetCombatPotionOptionItems(true)
                        end
                        local items = { { value = "default", label = "Default" } }
                        for _, row in ipairs(COMBAT_POTION_ITEMS) do
                            items[#items + 1] = row
                        end
                        return items
                    end,
                    function()
                        if module and type(module.GetSpecCombatPotionOverride) == "function" then
                            return module:GetSpecCombatPotionOverride(specID)
                        end
                        local key = tostring(specID)
                        return cfg.combatPotion.specOverrides[key] or "default"
                    end,
                    function(value)
                        if module and type(module.SetSpecCombatPotionOverride) == "function" then
                            module:SetSpecCombatPotionOverride(specID, value)
                        else
                            local key = tostring(specID)
                            if value == "default" then
                                cfg.combatPotion.specOverrides[key] = nil
                            else
                                cfg.combatPotion.specOverrides[key] = value
                            end
                            refreshModule()
                        end
                    end,
                    2,
                    260,
                    true)
            end
        end
    end

    local function BuildAlertSubpanel(b, sectionKey)
        if not sectionKey or sectionKey == "global" then
            return
        end

        cfg.alerts = type(cfg.alerts) == "table" and cfg.alerts or {}
        cfg.alerts[sectionKey] = type(cfg.alerts[sectionKey]) == "table" and cfg.alerts[sectionKey] or {}
        local alert = cfg.alerts[sectionKey]

        b:Toggle("Disable Alert",
            function()
                return alert.enabled == false
            end,
            function(value)
                alert.enabled = not value
                refreshModule()
            end)

        b:Input("Min Number Before Glow",
            function()
                return tostring(alert.minCount or 5)
            end,
            function(v)
                alert.minCount = Clamp(v, 0, 100000, alert.minCount or 5)
                refreshModule()
            end)

        if sectionKey == "food" or sectionKey == "feast" then
            alert.countSource = "TOTAL"
            b:Desc("Count Source: Total Count")
        else
            b:Cycle("Count Source",
                function()
                    return ALERT_COUNT_SOURCE_ITEMS
                end,
                function()
                    return alert.countSource or "TOTAL"
                end,
                function(v)
                    local value = type(v) == "string" and string.upper(v) or "TOTAL"
                    if value ~= "TOTAL" and value ~= "HIGHEST_QUALITY" then
                        value = "TOTAL"
                    end
                    alert.countSource = value
                    refreshModule()
                end,
                0,
                260)
        end
    end

    local function BuildBattleResSubpanel(b)
        cfg.battleRes = type(cfg.battleRes) == "table" and cfg.battleRes or {}

        b:Toggle("Disable on classes that have a battle res spell",
            function()
                return cfg.battleRes.disableIfClassHasSpell and true or false
            end,
            function(value)
                cfg.battleRes.disableIfClassHasSpell = value and true or false
                refreshModule()
            end)

        b:Desc("When enabled, the Battle Res item icon is hidden for classes that already have a battle res spell.")
    end

    RefreshRightPane = function()
        for _, child in ipairs({ rightPane:GetChildren() }) do
            if child and child.Hide then
                child:Hide()
            end
        end
        for _, region in ipairs({ rightPane:GetRegions() }) do
            if region and region.Hide then
                region:Hide()
            end
        end

        local rightLast
        local rightTotal = 0

        local function AddSubPanel(sectionId, titleText, buildFn, defaultOpen)
            local cardState = cfg.sectionCards
            local isOpen = cardState[sectionId]
            if isOpen == nil then
                isOpen = defaultOpen ~= false
            end
            local card, content, head = CreateCard(rightPane, titleText, C, W, isOpen)
            if rightLast then
                card:SetPoint("TOPLEFT", rightLast, "BOTTOMLEFT", 0, -8)
                card:SetPoint("TOPRIGHT", rightLast, "BOTTOMRIGHT", 0, -8)
                rightTotal = rightTotal + 8
            else
                card:SetPoint("TOPLEFT", rightPane, "TOPLEFT", 0, 0)
                card:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", 0, 0)
            end

            head:SetScript("OnClick", function()
                card:SetOpen(not card.open)
                cfg.sectionCards[sectionId] = card.open and true or false
                RefreshRightPane()
            end)

            local builder = W.Builder(content, { startY = 8, padX = 8 })
            buildFn(builder)
            local innerHeight = builder:Finalize()
            content:SetHeight(innerHeight)

            local cardHeight = 30
            if card.open then
                cardHeight = cardHeight + innerHeight + 6
            end
            card:SetHeight(cardHeight)

            rightTotal = rightTotal + cardHeight
            rightLast = card
        end

        if selectedKey == "global" then
            AddSubPanel("position", "Position", function(b)
                BuildPositionSubpanel(b, cfg, true)
            end, true)

            AddSubPanel("visibility", "Visibility", function(b)
                BuildVisibilitySubpanel(b, cfg, true)
            end, true)

            AddSubPanel("font", "Font", function(b)
                BuildFontSubpanel(b, cfg, true)
            end, true)

            AddSubPanel("grow", "Grow", function(b)
                BuildGrowSubpanel(b, cfg, true)
            end, true)

            AddSubPanel("iconSize", "Icon Size", function(b)
                BuildIconSizeSubpanel(b, cfg, true)
            end, true)
        elseif selectedKey == "flask" then
            AddSubPanel("flaskAlert", "Alert", function(b)
                BuildAlertSubpanel(b, "flask")
            end, true)

            AddSubPanel("flaskDefault", "Default", function(b)
                BuildFlaskDefaultSubpanel(b)
            end, true)

            AddSubPanel("flaskSpecs", "Class and Spec", function(b)
                BuildFlaskSpecSubpanel(b)
            end, true)
        elseif selectedKey == "combatPotion" then
            AddSubPanel("combatPotionAlert", "Alert", function(b)
                BuildAlertSubpanel(b, "combatPotion")
            end, true)

            AddSubPanel("combatPotionDefault", "Default", function(b)
                BuildCombatPotionDefaultSubpanel(b)
            end, true)

            AddSubPanel("combatPotionSpecs", "Class and Spec", function(b)
                BuildCombatPotionSpecSubpanel(b)
            end, true)
        elseif selectedKey == "battleRes" then
            AddSubPanel("battleResAlert", "Alert", function(b)
                BuildAlertSubpanel(b, "battleRes")
            end, true)

            AddSubPanel("battleResClassRule", "Class Rule", function(b)
                BuildBattleResSubpanel(b)
            end, true)
        else
            AddSubPanel(selectedKey .. "Alert", "Alert", function(b)
                BuildAlertSubpanel(b, selectedKey)
            end, true)
        end

        rightPane:SetHeight(math.max(1, rightTotal))
        body:SetHeight(math.max(leftPane:GetHeight(), rightTotal))
        root:SetHeight(84 + body:GetHeight())
        parent:SetHeight(110 + body:GetHeight())
    end

    RefreshRightPane()
    updateRowStyles()

    ns.RefreshCurrentPage = function()
        GetConsumablesConfig(Addon)
        if type(module.Refresh) == "function" then
            module:Refresh()
        end
    end
end
