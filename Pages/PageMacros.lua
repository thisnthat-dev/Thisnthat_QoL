local _, ns = ...

function ns:InitMacrosPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    local parent = ns.OptionsFrame.Content
    local W = ns.OptionsWidgets
    local C = ns.OptionsColors
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
    title:SetText("Macros")
    title:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    ApplyFont(title, 2)

    local subtitle = root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetPoint("TOPRIGHT", root, "TOPRIGHT", -2, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWordWrap(true)
    subtitle:SetText("Create and manage account-wide consumable macros. Flask is fully automated; other sections are scaffolded for the next steps.")
    ApplyFont(subtitle, -1)

    local body = CreateFrame("Frame", nil, root)
    body:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
    body:SetPoint("TOPRIGHT", subtitle, "BOTTOMRIGHT", 0, -10)
    body:SetHeight(1)

    if not Addon then
        local notice = W.Builder(body, { startY = 0, padX = 0 })
        notice:Desc("|cffff7777Addon context is unavailable.|r")
        local h = notice:Finalize()
        body:SetHeight(h)
        root:SetHeight(84 + h)
        parent:SetHeight(110 + h)
        return
    end

    local module = Addon:GetModule("Macros")
    if not module then
        local notice = W.Builder(body, { startY = 0, padX = 0 })
        notice:Desc("|cffff7777Macros module is not available.|r")
        local h = notice:Finalize()
        body:SetHeight(h)
        root:SetHeight(84 + h)
        parent:SetHeight(110 + h)
        return
    end

    local cfg = module:GetConfig()
    cfg.sectionState = type(cfg.sectionState) == "table" and cfg.sectionState or {}

    local rightTotal = 0
    local rightLast

    local function CreateCard(titleText, startOpen)
        local card = CreateFrame("Frame", nil, body, "BackdropTemplate")
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
        ApplyFont(icon, 0)

        local label = head:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        label:SetText(titleText)
        label:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        ApplyFont(label, 0)

        local content = CreateFrame("Frame", nil, card)
        content:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -2)
        content:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", 0, -2)

        card.head = head
        card.icon = icon
        card.content = content
        card.open = startOpen ~= false
        if card.open then
            content:Show()
        else
            content:Hide()
        end
        icon:SetText(card.open and "-" or "+")

        return card
    end

    local function AddSection(sectionKey, titleText, buildFn, defaultOpen)
        local state = cfg.sectionState[sectionKey]
        if state == nil then
            state = defaultOpen ~= false
        end

        local card = CreateCard(titleText, state)
        if rightLast then
            card:SetPoint("TOPLEFT", rightLast, "BOTTOMLEFT", 0, -8)
            card:SetPoint("TOPRIGHT", rightLast, "BOTTOMRIGHT", 0, -8)
            rightTotal = rightTotal + 8
        else
            card:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
            card:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, 0)
        end

        card.head:SetScript("OnClick", function()
            cfg.sectionState[sectionKey] = not card.open
            ns:InitMacrosPage()
        end)

        local builder = W.Builder(card.content, { startY = 8, padX = 8 })
        local ok, err = pcall(buildFn, builder)
        if not ok then
            builder:Desc("|cffff7777Section failed to load:|r " .. tostring(err))
            local addonRef = (type(ns.GetAddon) == "function" and ns.GetAddon()) or ns.Addon
            if addonRef and type(addonRef.Print) == "function" then
                addonRef:Print("Macros page section '" .. tostring(sectionKey) .. "' failed: " .. tostring(err))
            end
        end
        local innerHeight = builder:Finalize()
        card.content:SetHeight(innerHeight)

        local cardHeight = 30
        if card.open then
            cardHeight = cardHeight + innerHeight + 6
        end
        card:SetHeight(cardHeight)

        rightTotal = rightTotal + cardHeight
        rightLast = card
    end

    AddSection("flask", "Flask Macro", function(builder)
        local flaskCfg = module:GetFlaskConfig()

        builder:Toggle("Enable automatic flask macro updates",
            function()
                return flaskCfg.enabled ~= false
            end,
            function(value)
                module:SetFlaskEnabled(value and true or false)
            end)

        builder:Desc("When enabled, the macro is auto-created (if missing) and kept updated automatically.")

        local preview = module:GetFlaskMacroPreview()
        if preview.chosenItemName then
            builder:Desc("Current selection: " .. tostring(preview.selectedStatLabel) .. " (" .. tostring(preview.chosenItemName) .. ")")
        else
            builder:Desc("Current selection: " .. tostring(preview.selectedStatLabel) .. " (no matching flask currently in bags)")
        end

        builder:Header("Role Defaults")
        for _, roleEntry in ipairs(module:GetRoleOptions()) do
            local roleKey = roleEntry.value
            builder:Cycle(roleEntry.label,
                function()
                    return module:GetFlaskOptionItems(false)
                end,
                function()
                    return module:GetFlaskConfig().roleDefaults[roleKey]
                end,
                function(value)
                    module:SetRoleDefault(roleKey, value)
                end,
                2,
                220,
                false)
        end

        builder:Header("Class / Spec Overrides")
        builder:Desc("Role Default uses the role-level value above. Any change that impacts your active spec updates the macro immediately.")

        for _, classGroup in ipairs(module:GetSpecGroups()) do
            builder:Header(classGroup.className, 6)

            for _, specRow in ipairs(classGroup.specs) do
                local classID = specRow.classID
                local specID = specRow.specID
                local rowLabel = specRow.specName .. " (" .. tostring(specRow.roleCategory) .. ")"

                builder:Cycle(rowLabel,
                    function()
                        return module:GetFlaskOptionItems(true)
                    end,
                    function()
                        return module:GetSpecOverrideValue(classID, specID)
                    end,
                    function(value)
                        module:SetSpecOverrideValue(classID, specID, value)
                    end,
                    2,
                    220,
                    true)
            end
        end
    end, true)

    AddSection("combat_potion", "Combat Potion Macro", function(builder)
        local combatCfg = module:GetCombatPotionConfig()

        builder:Toggle("Enable automatic combat potion macro updates",
            function()
                return combatCfg.enabled ~= false
            end,
            function(value)
                module:SetCombatPotionEnabled(value and true or false)
            end)

        builder:Desc("When enabled, the macro is auto-created (if missing) and kept updated automatically.")

        local preview = module:GetCombatPotionMacroPreview()
        if preview.chosenItemName then
            builder:Desc("Current selection: " .. tostring(preview.selectedChoiceLabel) .. " (" .. tostring(preview.chosenItemName) .. ")")
        else
            builder:Desc("Current selection: " .. tostring(preview.selectedChoiceLabel) .. " (no matching potion currently in bags)")
        end

        builder:Header("Role Defaults")
        for _, roleEntry in ipairs(module:GetRoleOptions()) do
            local roleKey = roleEntry.value
            builder:Cycle(roleEntry.label,
                function()
                    return module:GetCombatPotionOptionItems(false)
                end,
                function()
                    return module:GetCombatPotionConfig().roleDefaults[roleKey]
                end,
                function(value)
                    module:SetCombatPotionRoleDefault(roleKey, value)
                end,
                2,
                220,
                false)
        end

        builder:Header("Class / Spec Overrides")
        builder:Desc("Role Default uses the role-level value above. Any change that impacts your active spec updates the macro immediately.")

        for _, classGroup in ipairs(module:GetSpecGroups()) do
            builder:Header(classGroup.className, 6)

            for _, specRow in ipairs(classGroup.specs) do
                local classID = specRow.classID
                local specID = specRow.specID
                local rowLabel = specRow.specName .. " (" .. tostring(specRow.roleCategory) .. ")"

                builder:Cycle(rowLabel,
                    function()
                        return module:GetCombatPotionOptionItems(true)
                    end,
                    function()
                        return module:GetCombatPotionSpecOverrideValue(classID, specID)
                    end,
                    function(value)
                        module:SetCombatPotionSpecOverrideValue(classID, specID, value)
                    end,
                    2,
                    220,
                    true)
            end
        end
    end, false)

    AddSection("healing_potion", "Healing Potion Macro", function(builder)
        local healingCfg = module:GetHealingPotionConfig()

        builder:Toggle("Enable automatic healing macro updates",
            function()
                return healingCfg.enabled ~= false
            end,
            function(value)
                module:SetHealingPotionEnabled(value and true or false)
            end)

        builder:Toggle("Use Recuperate out of combat",
            function()
                return healingCfg.useRecuperateOutOfCombat and true or false
            end,
            function(value)
                module:SetHealingUseRecuperateOutOfCombat(value)
            end)

        builder:Toggle("Enable Healthstones",
            function()
                return healingCfg.enableHealthstones ~= false
            end,
            function(value)
                module:SetHealingEnableHealthstones(value)
            end)

        builder:Toggle("Enable Healing Potions",
            function()
                return healingCfg.enableHealingPotions ~= false
            end,
            function(value)
                module:SetHealingEnablePotions(value)
            end)

        builder:Toggle("Add Stop Cast to macro",
            function()
                return healingCfg.addStopCast and true or false
            end,
            function(value)
                module:SetHealingAddStopCast(value)
            end)

        builder:Desc("When enabled, the macro is auto-created (if missing) and kept updated automatically.")

        local preview = module:GetHealingPotionMacroPreview()
        if preview.chosenItemName then
            if preview.allOnCooldown then
                builder:Desc("Current selection: " .. tostring(preview.chosenItemName) .. " (currently on cooldown, auto-rescanning every 10s)")
            else
                builder:Desc("Current selection: " .. tostring(preview.chosenItemName))
            end
        else
            builder:Desc("Current selection: no enabled healing items found in bags")
        end

        builder:Header("Warlock Options")

        builder:Toggle("Create separate Healthstone and Healing Potion macros",
            function()
                return healingCfg.warlockSeparateMacros and true or false
            end,
            function(value)
                module:SetWarlockSeparateMacros(value)
            end)

        builder:Toggle("Use Soulburn in Healthstone macro",
            function()
                return healingCfg.useSoulburnForHealthstone and true or false
            end,
            function(value)
                module:SetHealingUseSoulburn(value)
            end)

        builder:Desc("Soulburn only applies when separate macros are created. On Warlocks, the Healthstone item automatically switches to the Demonic Healthstone if Pact of Gluttony is selected; the combined macro instead uses a cast sequence that resets every 60 seconds with Pact of Gluttony, or on leaving combat without it.")

        if healingCfg.warlockSeparateMacros then
            local warlockPreview = module:GetWarlockHealthstoneMacroPreview()
            if warlockPreview.chosenItemName then
                builder:Desc("Healthstone macro selection: " .. tostring(warlockPreview.chosenItemName))
            end
        end
    end, false)

    AddSection("drink", "Drink Macro", function(builder)
        local drinkCfg = module:GetDrinkConfig()
        local drinkOrder = module:GetDrinkOrder()
        local rowCount = math.max(1, #drinkOrder)
        local rowHeight = 30
        local rowGap = 6
        local listHeight = (rowCount * rowHeight) + ((rowCount - 1) * rowGap)

        builder:Toggle("Enable automatic drink macro updates",
            function()
                return drinkCfg.enabled ~= false
            end,
            function(value)
                module:SetDrinkEnabled(value and true or false)
            end)

        builder:Desc("Drag entries to reorder priority. The macro uses the first matching item it finds in your bags.")

        local dragFrame = CreateFrame("Frame", nil, builder.parent)
        dragFrame:SetHeight(listHeight)

        local rows = {}
        local draggingKey = nil
        local draggingFromIndex = nil
        local hoverIndex = nil
        local dragActive = false

        local function ApplyRowStyle(row, isDragging)
            if not row then
                return
            end

            if isDragging then
                row:SetBackdropColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.22)
                row:SetBackdropBorderColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.95)
                if row.label then
                    row.label:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
                end
                row:SetAlpha(0.75)
            else
                row:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.14)
                row:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)
                if row.label then
                    row.label:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.95)
                end
                row:SetAlpha(1)
            end
        end

        local function BuildPreviewOrder(baseOrder, fromIndex, toIndex)
            local out = {}
            for i = 1, #baseOrder do
                out[i] = baseOrder[i]
            end

            if not fromIndex or not toIndex or fromIndex < 1 or fromIndex > #out or toIndex < 1 or toIndex > #out or fromIndex == toIndex then
                return out
            end

            local movedKey = table.remove(out, fromIndex)
            table.insert(out, toIndex, movedKey)
            return out
        end

        local function RefreshRows(previewOrder)
            local order = previewOrder or module:GetDrinkOrder()
            for i = 1, #rows do
                local row = rows[i]
                local entryKey = order[i]
                row.key = entryKey
                row.orderLabel:SetText(tostring(i) .. ".")
                row.label:SetText(entryKey and module:GetDrinkLabelByKey(entryKey) or "")
                local rowIsDragging = dragActive and draggingKey and entryKey == draggingKey
                ApplyRowStyle(row, rowIsDragging and true or false)
                if dragActive and hoverIndex == i then
                    row:SetBackdropColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.30)
                    row:SetBackdropBorderColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
                end
            end
        end

        local function OnDrop(targetRow)
            if not draggingKey or not targetRow or not targetRow.key then
                return
            end
            local targetIndex = hoverIndex
            if not targetIndex then
                for i = 1, #rows do
                    if rows[i] == targetRow then
                        targetIndex = i
                        break
                    end
                end
            end

            if targetIndex then
                module:MoveDrinkEntryToIndex(draggingKey, targetIndex)
            end

            draggingKey = nil
            draggingFromIndex = nil
            hoverIndex = nil
            dragActive = false
            for _, row in ipairs(rows) do
                ApplyRowStyle(row, false)
            end
            RefreshRows()
        end

        for i = 1, rowCount do
            local row = CreateFrame("Button", nil, dragFrame, "BackdropTemplate")
            row:SetHeight(30)
            row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

            if i == 1 then
                row:SetPoint("TOPLEFT", dragFrame, "TOPLEFT", 0, 0)
                row:SetPoint("TOPRIGHT", dragFrame, "TOPRIGHT", 0, 0)
            else
                row:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT", 0, -6)
                row:SetPoint("TOPRIGHT", rows[i - 1], "BOTTOMRIGHT", 0, -6)
            end

            local grip = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            grip:SetPoint("LEFT", row, "LEFT", 8, 0)
            grip:SetText("::")
            grip:SetTextColor(C.GRAY.r, C.GRAY.g, C.GRAY.b, 1)
            ApplyFont(grip, 0)

            local orderLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            orderLabel:SetPoint("LEFT", grip, "RIGHT", 8, 0)
            orderLabel:SetTextColor(C.GRAY.r, C.GRAY.g, C.GRAY.b, 0.95)
            ApplyFont(orderLabel, -1)
            row.orderLabel = orderLabel

            local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("LEFT", orderLabel, "RIGHT", 8, 0)
            label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            label:SetJustifyH("LEFT")
            ApplyFont(label, -1)
            row.label = label

            row:RegisterForDrag("LeftButton")
            row:SetScript("OnDragStart", function(self)
                draggingKey = self.key
                draggingFromIndex = i
                hoverIndex = i
                dragActive = true
                RefreshRows()
            end)
            row:SetScript("OnDragStop", function(self)
                OnDrop(self)
            end)
            row:SetScript("OnEnter", function()
                if dragActive then
                    hoverIndex = i
                    local liveOrder = BuildPreviewOrder(module:GetDrinkOrder(), draggingFromIndex, hoverIndex)
                    RefreshRows(liveOrder)
                end
            end)
            row:SetScript("OnLeave", function()
                if dragActive then
                    hoverIndex = nil
                    local liveOrder = BuildPreviewOrder(module:GetDrinkOrder(), draggingFromIndex, draggingFromIndex)
                    RefreshRows(liveOrder)
                end
            end)
            row:SetScript("OnMouseUp", function(self)
                if dragActive then
                    OnDrop(self)
                end
            end)

            ApplyRowStyle(row, false)

            rows[i] = row
        end

        RefreshRows()
        builder:_Attach(dragFrame, listHeight, 6)

        local preview = module:GetDrinkMacroPreview()
        if preview.chosenItemName and preview.selectedEntryLabel then
            builder:Desc("Current selection: " .. tostring(preview.selectedEntryLabel) .. " (" .. tostring(preview.chosenItemName) .. ")")
        elseif preview.chosenItemName then
            builder:Desc("Current selection: " .. tostring(preview.chosenItemName))
        else
            builder:Desc("Current selection: no preferred drink item found in bags")
        end
    end, false)

    body:SetHeight(math.max(1, rightTotal))
    root:SetHeight(84 + body:GetHeight())
    parent:SetHeight(110 + body:GetHeight())

    ns.RefreshCurrentPage = function()
        ns:InitMacrosPage()
    end
end
