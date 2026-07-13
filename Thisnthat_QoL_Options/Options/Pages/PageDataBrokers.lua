local ADDON_NAME, ns = ...

function ns:InitDataBrokerBarsPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    local parent = ns.OptionsFrame.Content
    local W      = ns.OptionsWidgets
    local Addon  = (type(ns.GetAddon) == "function" and ns.GetAddon()) or ns.Addon
    local C      = ns.OptionsColors
    local LSM    = LibStub and LibStub("LibSharedMedia-3.0", true)

    local function ApplyFont(target, offset)
        if W and W.ApplyFont then
            W.ApplyFont(target, offset)
        end
    end

    local dbModule = Addon:GetModule("databroker_bars")
    local newBarCount = 3
    local pendingDeleteBar
    local popupDialogs = rawget(_G, "StaticPopupDialogs")
    local popupShow = rawget(_G, "StaticPopup_Show")

    if popupDialogs and not popupDialogs.THISNTHAT_QOL_CONFIRM_DELETE_BAR then
        popupDialogs.THISNTHAT_QOL_CONFIRM_DELETE_BAR = {
            text = "Delete databroker bar '%s'?",
            button1 = "Delete",
            button2 = "Cancel",
            OnAccept = function()
                if type(pendingDeleteBar) == "function" then
                    pendingDeleteBar()
                end
                pendingDeleteBar = nil
            end,
            OnCancel = function()
                pendingDeleteBar = nil
            end,
            OnHide = function()
                pendingDeleteBar = nil
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    local function lsmItems(mediaType, withNone)
        local items = withNone and { { value = "", label = "None" } } or {}
        if LSM and type(LSM.List) == "function" then
            for _, name in ipairs(LSM:List(mediaType) or {}) do
                items[#items + 1] = { value = name, label = name }
            end
        end
        return items
    end

    local function db()
        Addon.db.databrokers = Addon.db.databrokers or {}
        local d = Addon.db.databrokers
        d.bars             = type(d.bars) == "table" and d.bars or {}
        d.unlocked         = d.unlocked and true or false
        return d
    end

    local ANCHOR_POINTS = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }

    local function applyModule()
        if dbModule and type(dbModule.ApplySettings) == "function" then
            dbModule:ApplySettings()
        end
    end

    local function ensureBar(index)
        local d = db()
        d.bars[index] = type(d.bars[index]) == "table" and d.bars[index] or {}
        local cfg = d.bars[index]
        local defaultY = -120 - ((index - 1) * 30)
        cfg.name        = type(cfg.name) == "string" and cfg.name or ("Bar " .. index)
        cfg.width       = tonumber(cfg.width)  or 560
        cfg.height      = tonumber(cfg.height) or 24
        cfg.maxBrokers  = tonumber(cfg.maxBrokers) or 8
        cfg.point       = type(cfg.point) == "string" and cfg.point or "TOP"
        cfg.relativePoint = type(cfg.relativePoint) == "string" and cfg.relativePoint or cfg.point
        cfg.x           = tonumber(cfg.x) or 0
        cfg.y           = tonumber(cfg.y) or defaultY
        cfg.brokers     = type(cfg.brokers) == "table" and cfg.brokers or {}
        cfg.showBackdrop = cfg.showBackdrop ~= false
        cfg.showBorder = cfg.showBorder ~= false
        return cfg
    end

    local function CreateSection(parentFrame, titleText, startOpen, onToggle)
        local wrap = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
        wrap:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        wrap:SetBackdropColor(0.02, 0.02, 0.02, 0.45)
        wrap:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

        local head = CreateFrame("Button", nil, wrap, "BackdropTemplate")
        head:SetPoint("TOPLEFT", wrap, "TOPLEFT", 1, -1)
        head:SetPoint("TOPRIGHT", wrap, "TOPRIGHT", -1, -1)
        head:SetHeight(28)
        head:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        head:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.22)

        local icon = head:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        icon:SetPoint("LEFT", head, "LEFT", 8, 0)
        icon:SetText((startOpen == false) and "+" or "-")
        icon:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        ApplyFont(icon, 0)

        local label = head:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        label:SetText(titleText)
        label:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        ApplyFont(label, 0)

        local content = CreateFrame("Frame", nil, wrap)
        content:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -2)
        content:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", 0, -2)

        wrap.open = startOpen ~= false
        content:SetShown(wrap.open)
        wrap.content = content

        function wrap:RecalcHeight()
            local h = 30
            if self.open then
                h = h + (self.content:GetHeight() or 1) + 2
            end
            self:SetHeight(h)
        end

        head:SetScript("OnClick", function()
            wrap.open = not wrap.open
            content:SetShown(wrap.open)
            icon:SetText(wrap.open and "-" or "+")
            wrap:RecalcHeight()
            if onToggle then onToggle() end
        end)

        wrap:RecalcHeight()
        return wrap
    end

    local function CreateTopCard(parentFrame, titleText)
        local card = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
        card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        card:SetBackdropColor(0.02, 0.02, 0.02, 0.45)
        card:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

        local head = CreateFrame("Frame", nil, card, "BackdropTemplate")
        head:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
        head:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, -1)
        head:SetHeight(28)
        head:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        head:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.22)

        local label = head:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", head, "LEFT", 8, 0)
        label:SetText(titleText)
        label:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        ApplyFont(label, 0)

        local content = CreateFrame("Frame", nil, card)
        content:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -2)
        content:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", 0, -2)
        content:SetHeight(1)

        card.content = content

        function card:RecalcHeight()
            self:SetHeight(30 + (self.content:GetHeight() or 1) + 2)
        end

        card:RecalcHeight()
        return card
    end

    local function AddTwoColumnRow(builder, leftBuilderFn, rightBuilderFn, gap)
        local row = CreateFrame("Frame", nil, builder.parent)
        row:SetHeight(1)

        local left = CreateFrame("Frame", nil, row)
        left:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        left:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        left:SetPoint("RIGHT", row, "CENTER", -4, 0)

        local right = CreateFrame("Frame", nil, row)
        right:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
        right:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        right:SetPoint("LEFT", row, "CENTER", 4, 0)

        local lb = W.Builder(left, { startY = 0, padX = 0 })
        leftBuilderFn(lb)

        local rb = W.Builder(right, { startY = 0, padX = 0 })
        rightBuilderFn(rb)

        local rowHeight = math.max(lb.totalH, rb.totalH)
        row:SetHeight(rowHeight)

        builder:_Attach(row, rowHeight, gap or 4)
    end

    local function AddThreeColumnRow(builder, leftBuilderFn, midBuilderFn, rightBuilderFn, gap)
        local row = CreateFrame("Frame", nil, builder.parent)
        row:SetHeight(1)

        local left = CreateFrame("Frame", nil, row)
        left:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        left:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        left:SetPoint("RIGHT", row, "LEFT", (row:GetWidth() / 3) - 6, 0)

        local mid = CreateFrame("Frame", nil, row)
        mid:SetPoint("TOPLEFT", left, "TOPRIGHT", 6, 0)
        mid:SetPoint("BOTTOMLEFT", left, "BOTTOMRIGHT", 6, 0)
        mid:SetPoint("RIGHT", row, "LEFT", (2 * row:GetWidth() / 3) - 3, 0)

        local right = CreateFrame("Frame", nil, row)
        right:SetPoint("TOPLEFT", mid, "TOPRIGHT", 6, 0)
        right:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)

        row:SetScript("OnSizeChanged", function(self, w)
            local col = (w - 12) / 3
            left:ClearAllPoints()
            left:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
            left:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
            left:SetWidth(col)

            mid:ClearAllPoints()
            mid:SetPoint("TOPLEFT", left, "TOPRIGHT", 6, 0)
            mid:SetPoint("BOTTOMLEFT", left, "BOTTOMRIGHT", 6, 0)
            mid:SetWidth(col)

            right:ClearAllPoints()
            right:SetPoint("TOPLEFT", mid, "TOPRIGHT", 6, 0)
            right:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
        end)

        local lb = W.Builder(left, { startY = 0, padX = 0 })
        leftBuilderFn(lb)

        local mb = W.Builder(mid, { startY = 0, padX = 0 })
        midBuilderFn(mb)

        local rb = W.Builder(right, { startY = 0, padX = 0 })
        rightBuilderFn(rb)

        local rowHeight = math.max(lb.totalH, mb.totalH, rb.totalH)
        row:SetHeight(rowHeight)

        builder:_Attach(row, rowHeight, gap or 4)
    end

    local function ParseNumberInput(text, fallback, minValue, maxValue, asInteger, decimals)
        local n = tonumber(text)
        if not n then
            return fallback
        end
        if asInteger then
            n = math.floor(n + 0.5)
        elseif type(decimals) == "number" and decimals >= 0 then
            n = tonumber(string.format("%." .. tostring(decimals) .. "f", n)) or n
        end
        if minValue and n < minValue then n = minValue end
        if maxValue and n > maxValue then n = maxValue end
        return n
    end

    local function FormatRounded(value, decimals)
        local n = tonumber(value)
        if not n then
            n = 0
        end
        local s = string.format("%." .. tostring(decimals) .. "f", n)
        s = string.gsub(s, "(%..-)0+$", "%1")
        s = string.gsub(s, "%.$", "")
        return s
    end

    local root = CreateFrame("Frame", nil, parent)
    root:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    root:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
    root:SetHeight(1)

    local title = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 2, -2)
    title:SetText("DataBroker Bars")
    title:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    ApplyFont(title, 2)

    local subtitle = root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetPoint("TOPRIGHT", root, "TOPRIGHT", -2, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWordWrap(true)
    subtitle:SetText("Module options are grouped by category. Expand sections to edit bar setup, layout, and broker assignments.")
    ApplyFont(subtitle, -1)

    local topRow = CreateFrame("Frame", nil, root)
    topRow:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
    topRow:SetPoint("TOPRIGHT", subtitle, "BOTTOMRIGHT", 0, -10)
    topRow:SetHeight(1)

    local moduleCard = CreateTopCard(topRow, "Module Settings")
    moduleCard:SetPoint("TOPLEFT", topRow, "TOPLEFT", 0, 0)
    moduleCard:SetPoint("TOPRIGHT", topRow, "TOP", -4, 0)

    local createCard = CreateTopCard(topRow, "Create New Bar")
    createCard:SetPoint("TOPLEFT", topRow, "TOP", 4, 0)
    createCard:SetPoint("TOPRIGHT", topRow, "TOPRIGHT", 0, 0)

    local sectionsHost = CreateFrame("Frame", nil, root)
    sectionsHost:SetPoint("TOPLEFT", topRow, "BOTTOMLEFT", 0, -10)
    sectionsHost:SetPoint("TOPRIGHT", topRow, "BOTTOMRIGHT", 0, -10)
    sectionsHost:SetHeight(1)

    local sections = {}

    local function RelayoutSections()
        local y = 0
        for i, sec in ipairs(sections) do
            sec:ClearAllPoints()
            if i == 1 then
                sec:SetPoint("TOPLEFT", sectionsHost, "TOPLEFT", 0, 0)
                sec:SetPoint("TOPRIGHT", sectionsHost, "TOPRIGHT", 0, 0)
            else
                sec:SetPoint("TOPLEFT", sections[i - 1], "BOTTOMLEFT", 0, -8)
                sec:SetPoint("TOPRIGHT", sections[i - 1], "BOTTOMRIGHT", 0, -8)
            end
            sec:RecalcHeight()
            y = y + sec:GetHeight() + 8
        end

        sectionsHost:SetHeight(y)
        root:SetHeight(74 + y)
        parent:SetHeight(100 + y)
    end

    do
        local b = W.Builder(moduleCard.content)
        b:Desc("Configure module behavior and interaction for all bars.")
        b:Toggle("Enable DataBroker Bars",
            function() return Addon:IsModuleEnabled("databroker_bars") end,
            function(v)
                Addon.db.modules.databroker_bars.enabled = v and true or false
                applyModule()
            end)
        b:Toggle("Unlock Bars (Drag & Drop)",
            function() return db().unlocked end,
            function(v) db().unlocked = v and true or false; applyModule() end)
        b:Finalize()
        moduleCard:RecalcHeight()
    end

    local mediaSection = CreateSection(sectionsHost, "Module Media", true, RelayoutSections)
    do
        local b = W.Builder(mediaSection.content)
        b:Desc("These settings apply to module-level media styling.")

        AddTwoColumnRow(b,
            function(col)
                col:Cycle("Font",
                    function() return lsmItems("font", true) end,
                    function()
                        local cfg = Addon:GetModuleMediaConfig("databrokers")
                        return cfg.font
                    end,
                    function(v)
                        local cfg = Addon:GetModuleMediaConfig("databrokers")
                        cfg.font = (v == "") and nil or v
                        applyModule()
                    end,
                    0,
                    180)
            end,
            function(col)
                col:Input("Font Size",
                    function()
                        local cfg = Addon:GetModuleMediaConfig("databrokers")
                        return tostring(cfg.fontSize or 12)
                    end,
                    function(v)
                        local cfg = Addon:GetModuleMediaConfig("databrokers")
                        local fontSize = tonumber(v) or cfg.fontSize or 12
                        fontSize = math.floor(fontSize + 0.5)
                        if fontSize < 6 then fontSize = 6 end
                        if fontSize > 64 then fontSize = 64 end
                        cfg.fontSize = fontSize
                        applyModule()
                    end,
                    0)
            end)

        AddTwoColumnRow(b,
            function(col)
                col:Color("Border Color",
                    function()
                        local cfg = Addon:GetModuleMediaConfig("databrokers")
                        local c = cfg.borderColor or {}
                        return c.r or 0.18, c.g or 0.24, c.b or 0.30, c.a or 1
                    end,
                    function(r, g, bv, a)
                        local cfg = Addon:GetModuleMediaConfig("databrokers")
                        cfg.borderColor = { r = r, g = g, b = bv, a = a }
                        applyModule()
                    end,
                    true,
                    0)
            end,
            function(col)
                col:Color("Background Color",
                    function()
                        local cfg = Addon:GetModuleMediaConfig("databrokers")
                        local c = cfg.textureColor or {}
                        return c.r or 0.09, c.g or 0.11, c.b or 0.14, c.a or 0.95
                    end,
                    function(r, g, bv, a)
                        local cfg = Addon:GetModuleMediaConfig("databrokers")
                        cfg.textureColor = { r = r, g = g, b = bv, a = a }
                        applyModule()
                    end,
                    true,
                    0)
            end)

        AddTwoColumnRow(b,
            function(col)
                col:Cycle("Border Texture",
                    function() return lsmItems("border", true) end,
                    function()
                        local cfg = Addon:GetModuleMediaConfig("databrokers")
                        return cfg.border
                    end,
                    function(v)
                        local cfg = Addon:GetModuleMediaConfig("databrokers")
                        cfg.border = (v == "") and nil or v
                        applyModule()
                    end,
                    0,
                    180)
            end,
            function(col)
                col:Input("Border Size",
                    function()
                        local cfg = Addon:GetModuleMediaConfig("databrokers")
                        return tostring(cfg.borderSize or 1)
                    end,
                    function(v)
                        local cfg = Addon:GetModuleMediaConfig("databrokers")
                        local borderSize = tonumber(v) or cfg.borderSize or 1
                        borderSize = math.floor(borderSize + 0.5)
                        if borderSize < 1 then borderSize = 1 end
                        if borderSize > 8 then borderSize = 8 end
                        cfg.borderSize = borderSize
                        applyModule()
                    end,
                    0)
            end)

        b:Finalize()
        mediaSection:RecalcHeight()
    end
    sections[#sections + 1] = mediaSection

    do
        local b = W.Builder(createCard.content)
        b:Desc("Create a new DataBroker bar and set its initial slot capacity.")

        local newNameInput = b:Input("Bar Name", function() return "" end, nil)
        b:Input("Max Brokers",
            function() return tostring(newBarCount) end,
            function(v)
                newBarCount = ParseNumberInput(v, newBarCount, 1, 12, true)
            end)

        b:Button("Create Bar", function()
            if not dbModule or type(dbModule.CreateNamedBar) ~= "function" then return end
            local name = newNameInput.edit:GetText()
            dbModule:CreateNamedBar(name ~= "" and name or nil, newBarCount)
            newNameInput.edit:SetText("")
            newBarCount = 3
            applyModule()
            ns:InitDataBrokerBarsPage()
        end)

        b:Finalize()
        createCard:RecalcHeight()
    end
    topRow:SetHeight(math.max(moduleCard:GetHeight(), createCard:GetHeight()))

    local availableBrokerNames = {}
    if dbModule and type(dbModule.GetAvailableBrokerNames) == "function" then
        availableBrokerNames = dbModule:GetAvailableBrokerNames()
    end

    local function BuildBrokerItems()
        local items = { { value = "", label = "None" } }
        for _, name in ipairs(availableBrokerNames) do
            items[#items + 1] = { value = name, label = name }
        end
        return items
    end

    local brokerDisplaySection = CreateSection(sectionsHost, "Broker Display", true, RelayoutSections)
    do
        local b = W.Builder(brokerDisplaySection.content)
        b:Desc("Select a DataBroker category to control label, text, and icon visibility.")

        if #availableBrokerNames == 0 then
            b:Desc("|cffaaaaaaNo DataBrokers were detected.|r")
        else
            local pageDb = db()
            pageDb.brokerDisplayCategory = type(pageDb.brokerDisplayCategory) == "string" and pageDb.brokerDisplayCategory or ""

            local selectedBroker = pageDb.brokerDisplayCategory
            local hasSelected = false
            for _, brokerName in ipairs(availableBrokerNames) do
                if brokerName == selectedBroker then
                    hasSelected = true
                    break
                end
            end

            if not hasSelected then
                selectedBroker = availableBrokerNames[1]
                pageDb.brokerDisplayCategory = selectedBroker
            end

            b:Cycle("DataBroker Category",
                function()
                    local items = {}
                    for _, brokerName in ipairs(availableBrokerNames) do
                        items[#items + 1] = { value = brokerName, label = brokerName }
                    end
                    return items
                end,
                function()
                    return pageDb.brokerDisplayCategory
                end,
                function(v)
                    local scrollFrame = parent and parent.GetParent and parent:GetParent() or nil
                    local scrollY = (scrollFrame and scrollFrame.GetVerticalScroll and scrollFrame:GetVerticalScroll()) or 0
                    pageDb.brokerDisplayCategory = v
                    ns:InitDataBrokerBarsPage()
                    if scrollFrame and scrollFrame.SetVerticalScroll then
                        C_Timer.After(0, function()
                            scrollFrame:SetVerticalScroll(scrollY)
                        end)
                    end
                end,
                0,
                280,
                true)

            b:Desc("Selected: " .. selectedBroker)

            b:Toggle("Show Label",
                function()
                    local cfg = dbModule:GetBrokerDisplayConfig(selectedBroker)
                    return cfg.showLabel
                end,
                function(v)
                    local cfg = dbModule:GetBrokerDisplayConfig(selectedBroker)
                    cfg.showLabel = v and true or false
                    applyModule()
                end,
                0)

            b:Toggle("Show Text",
                function()
                    local cfg = dbModule:GetBrokerDisplayConfig(selectedBroker)
                    return cfg.showText
                end,
                function(v)
                    local cfg = dbModule:GetBrokerDisplayConfig(selectedBroker)
                    cfg.showText = v and true or false
                    applyModule()
                end,
                0)

            b:Toggle("Show Icon",
                function()
                    local cfg = dbModule:GetBrokerDisplayConfig(selectedBroker)
                    return cfg.showIcon
                end,
                function(v)
                    local cfg = dbModule:GetBrokerDisplayConfig(selectedBroker)
                    cfg.showIcon = v and true or false
                    applyModule()
                end,
                0)
        end

        b:Finalize()
        brokerDisplaySection:RecalcHeight()
    end
    sections[#sections + 1] = brokerDisplaySection

    local d = db()
    if #d.bars == 0 then
        local emptySection = CreateSection(sectionsHost, "Bars", true, RelayoutSections)
        local b = W.Builder(emptySection.content)
        b:Desc("|cffaaaaaaNo bars created yet. Use Create New Bar above.|r")
        b:Finalize()
        sections[#sections + 1] = emptySection
    else
        for index = 1, #d.bars do
            local bar = ensureBar(index)
            local sectionTitle = "Bar " .. index .. ": " .. (bar.name or ("Bar " .. index))
            local barSection = CreateSection(sectionsHost, sectionTitle, true, RelayoutSections)

            local b = W.Builder(barSection.content)
            b:Desc("Configure layout and broker assignments for this bar.")
            b:Button("Delete This Bar", function()
                if not dbModule or type(dbModule.DeleteBar) ~= "function" then return end
                local barLabel = bar and bar.name or ("Bar " .. index)
                local function deleteBarNow()
                    dbModule:DeleteBar(index)
                    applyModule()
                    ns:InitDataBrokerBarsPage()
                end

                if popupShow and popupDialogs then
                    pendingDeleteBar = deleteBarNow
                    popupShow("THISNTHAT_QOL_CONFIRM_DELETE_BAR", barLabel)
                else
                    deleteBarNow()
                end
            end)

            AddTwoColumnRow(b,
                function(col)
                    col:Input("Bar Name",
                        function()
                            local cur = ensureBar(index)
                            return cur and cur.name or ""
                        end,
                        function(v)
                            local cur = ensureBar(index)
                            if cur then
                                cur.name = v
                                applyModule()
                            end
                        end, 0)
                end,
                function(col)
                    col:Input("Max Brokers",
                        function()
                            local cur = ensureBar(index)
                            return tostring((cur and cur.maxBrokers) or 8)
                        end,
                        function(v)
                            local cur = ensureBar(index)
                            if cur then
                                cur.maxBrokers = ParseNumberInput(v, cur.maxBrokers or 8, 1, 40, true)
                                applyModule()
                                ns:InitDataBrokerBarsPage()
                            end
                        end, 0)
                end)

            AddTwoColumnRow(b,
                function(col)
                    col:Input("X Offset",
                        function()
                            local cur = ensureBar(index)
                            return FormatRounded((cur and cur.x) or 0, 2)
                        end,
                        function(v)
                            local cur = ensureBar(index)
                            if cur then
                                cur.x = ParseNumberInput(v, cur.x or 0, -4000, 4000, false, 2)
                                applyModule()
                            end
                        end, 0)
                end,
                function(col)
                    col:Input("Y Offset",
                        function()
                            local cur = ensureBar(index)
                            return FormatRounded((cur and cur.y) or -120, 2)
                        end,
                        function(v)
                            local cur = ensureBar(index)
                            if cur then
                                cur.y = ParseNumberInput(v, cur.y or -120, -4000, 4000, false, 2)
                                applyModule()
                            end
                        end, 0)
                end)

            AddTwoColumnRow(b,
                function(col)
                    col:Input("Width",
                        function()
                            local cur = ensureBar(index)
                            return FormatRounded((cur and cur.width) or 560, 2)
                        end,
                        function(v)
                            local cur = ensureBar(index)
                            if cur then
                                cur.width = ParseNumberInput(v, cur.width or 560, 120, 2400, false, 2)
                                applyModule()
                            end
                        end, 0)
                end,
                function(col)
                    col:Input("Height",
                        function()
                            local cur = ensureBar(index)
                            return FormatRounded((cur and cur.height) or 24, 2)
                        end,
                        function(v)
                            local cur = ensureBar(index)
                            if cur then
                                cur.height = ParseNumberInput(v, cur.height or 24, 12, 128, false, 2)
                                applyModule()
                            end
                        end, 0)
                end)

            AddTwoColumnRow(b,
                function(col)
                    col:Cycle("Anchor Point",
                        function()
                            local items = {}
                            for _, p in ipairs(ANCHOR_POINTS) do items[#items + 1] = { value = p, label = p } end
                            return items
                        end,
                        function() local cur = ensureBar(index); return cur and cur.point or "TOP" end,
                        function(v) local cur = ensureBar(index); if cur then cur.point = v; applyModule() end end, 0, 170)
                end,
                function(col)
                    col:Cycle("Relative Anchor",
                        function()
                            local items = {}
                            for _, p in ipairs(ANCHOR_POINTS) do items[#items + 1] = { value = p, label = p } end
                            return items
                        end,
                        function() local cur = ensureBar(index); return cur and cur.relativePoint or "TOP" end,
                        function(v) local cur = ensureBar(index); if cur then cur.relativePoint = v; applyModule() end end, 0, 170)
                end)

            AddTwoColumnRow(b,
                function(col)
                    col:Toggle("Show Background",
                        function()
                            local cur = ensureBar(index)
                            return cur and cur.showBackdrop
                        end,
                        function(v)
                            local cur = ensureBar(index)
                            if cur then
                                cur.showBackdrop = v and true or false
                                applyModule()
                            end
                        end, 0)
                end,
                function(col)
                    col:Toggle("Show Border",
                        function()
                            local cur = ensureBar(index)
                            return cur and cur.showBorder
                        end,
                        function(v)
                            local cur = ensureBar(index)
                            if cur then
                                cur.showBorder = v and true or false
                                applyModule()
                            end
                        end, 0)
                end)

            b:Header("Broker Slot Assignments")
            local slotItems = BuildBrokerItems()
            for slot = 1, bar.maxBrokers do
                b:Cycle("Slot " .. slot,
                    function() return slotItems end,
                    function()
                        local current = ensureBar(index)
                        return current and current.brokers and current.brokers[slot] or ""
                    end,
                    function(v)
                        local current = ensureBar(index)
                        if current and current.brokers then
                            current.brokers[slot] = (v == "") and nil or v
                            applyModule()
                        end
                    end)
            end

            b:Finalize()
            sections[#sections + 1] = barSection
        end
    end

    RelayoutSections()
    root:SetHeight(84 + topRow:GetHeight() + sectionsHost:GetHeight())
    parent:SetHeight(120 + topRow:GetHeight() + sectionsHost:GetHeight())
end
