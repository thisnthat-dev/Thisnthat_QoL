local ADDON_NAME, ns = ...

function ns:InitKickAssistPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    local parent = ns.OptionsFrame.Content
    local W = ns.OptionsWidgets
    local C = ns.OptionsColors
    local standaloneAddon = rawget(_G, "Thisnthat_KickAssist_Addon")

    local function ApplyFont(target, offset)
        if W and W.ApplyFont then
            W.ApplyFont(target, offset)
        end
    end

    local function ShowCopyDialog(titleText, macroText)
        ns.KickAssistCopyDialog = ns.KickAssistCopyDialog or nil
        local dialog = ns.KickAssistCopyDialog

        if not dialog then
            dialog = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
            dialog:SetSize(560, 220)
            dialog:SetPoint("CENTER")
            dialog:SetFrameStrata("DIALOG")
            dialog:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            dialog:SetBackdropColor(0.02, 0.02, 0.02, 0.95)
            dialog:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.85)

            dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            dialog.title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -10)
            dialog.title:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
            ApplyFont(dialog.title, 0)

            dialog.desc = dialog:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            dialog.desc:SetPoint("TOPLEFT", dialog.title, "BOTTOMLEFT", 0, -6)
            dialog.desc:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -12, -6)
            dialog.desc:SetJustifyH("LEFT")
            dialog.desc:SetWordWrap(true)
            dialog.desc:SetText("Press Ctrl+C after the text is highlighted.")
            ApplyFont(dialog.desc, -1)

            dialog.edit = CreateFrame("EditBox", nil, dialog, "BackdropTemplate")
            dialog.edit:SetPoint("TOPLEFT", dialog.desc, "BOTTOMLEFT", 0, -8)
            dialog.edit:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 42)
            dialog.edit:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            dialog.edit:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
            dialog.edit:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.55)
            dialog.edit:SetTextInsets(8, 8, 8, 8)
            dialog.edit:SetAutoFocus(false)
            dialog.edit:SetMultiLine(true)
            dialog.edit:SetFontObject(ChatFontNormal)
            dialog.edit:SetTextColor(0.95, 0.95, 0.95, 1)

            dialog.close = W.ActionButton and W.ActionButton(dialog, "Close", 88, 24) or CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
            dialog.close:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 10)
            if dialog.close.lbl then
                dialog.close.lbl:SetText("Close")
            else
                dialog.close:SetText("Close")
            end
            dialog.close:SetScript("OnClick", function()
                dialog:Hide()
            end)

            dialog:SetScript("OnShow", function(self)
                self.edit:SetFocus()
                self.edit:HighlightText(0)
            end)

            ns.KickAssistCopyDialog = dialog
        end

        dialog.title:SetText(titleText or "Copy Macro")
        dialog.edit:SetText(macroText or "")
        dialog:Show()
    end

    local root = CreateFrame("Frame", nil, parent)
    root:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    root:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
    root:SetHeight(1)

    local title = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 2, -2)
    title:SetText("Kick Assist")
    title:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    ApplyFont(title, 2)

    local subtitle = root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetPoint("TOPRIGHT", root, "TOPRIGHT", -2, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWordWrap(true)
    subtitle:SetText("Configure the standalone Thisnthat_KickAssist addon using the shared Thisnthat options interface.")
    ApplyFont(subtitle, -1)

    local body = CreateFrame("Frame", nil, root)
    body:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
    body:SetPoint("TOPRIGHT", subtitle, "BOTTOMRIGHT", 0, -10)
    body:SetHeight(1)

    if not standaloneAddon or type(standaloneAddon.GetConfig) ~= "function" then
        local notice = W.Builder(body, { startY = 0, padX = 0 })
        notice:Desc("|cffff7777Thisnthat_KickAssist is not loaded.|r")
        local h = notice:Finalize()
        body:SetHeight(h)
        root:SetHeight(84 + h)
        parent:SetHeight(110 + h)
        return
    end

    local function cfg()
        return standaloneAddon:GetConfig()
    end

    local function markerItems()
        local items = {}
        for _, marker in ipairs(standaloneAddon:GetRaidMarkers()) do
            local icon = standaloneAddon:GetMarkerTextureTag(marker.index, 14)
            items[#items + 1] = {
                value = marker.index,
                label = (icon ~= "" and (icon .. " ") or "") .. marker.name,
            }
        end
        return items
    end

    local function focusMacroPreview()
        return standaloneAddon:BuildFocusMacro(cfg().markerIndex)
    end

    local function kickMacroPreview()
        return standaloneAddon:BuildKickMacro()
    end

    local function announcementPreview()
        local markerTexture = standaloneAddon:GetMarkerTextureTag(cfg().markerIndex, 14)
        local text = cfg().announceTemplate or ""
        if text == "" then
            text = "My Kick target is {RAIDMARKER}"
        end
        if markerTexture == "" then
            return "No ready check message will be sent while marker is set to None."
        end
        return string.gsub(text, "{RAIDMARKER}", markerTexture)
    end

    local function AddTwoButtonsRow(builder, leftLabel, leftClick, rightLabel, rightClick, gap)
        local row = CreateFrame("Frame", nil, builder.parent)
        row:SetHeight(30)

        local left = (W and type(W.ActionButton) == "function") and W.ActionButton(row, leftLabel, 120, 24) or CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        left:SetHeight(24)
        left:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        left:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        left:SetPoint("RIGHT", row, "CENTER", -4, 0)
        if left.lbl and type(left.lbl.SetText) == "function" then
            left.lbl:SetText(leftLabel)
        else
            left:SetText(leftLabel)
        end
        left:SetScript("OnClick", function()
            if leftClick then
                leftClick()
            end
        end)

        local right = (W and type(W.ActionButton) == "function") and W.ActionButton(row, rightLabel, 120, 24) or CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        right:SetHeight(24)
        right:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
        right:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        right:SetPoint("LEFT", row, "CENTER", 4, 0)
        if right.lbl and type(right.lbl.SetText) == "function" then
            right.lbl:SetText(rightLabel)
        else
            right:SetText(rightLabel)
        end
        right:SetScript("OnClick", function()
            if rightClick then
                rightClick()
            end
        end)

        builder:_Attach(row, 30, gap or 4)
    end

    local b = W.Builder(body, { startY = 0, padX = 0 })

    b:Header("Target Marker")
    b:Cycle("Kick Marker",
        markerItems,
        function() return cfg().markerIndex end,
        function(v)
            cfg().markerIndex = tonumber(v) or 0
            ns:InitKickAssistPage()
        end,
        0,
        280,
        true)

    b:Desc("Your selected marker is used in the focus-mark macro and in the ready-check announcement.")

    b:Header("Minimap Button")
    b:Toggle("Show minimap button",
        function()
            return cfg().hideMinimapButton ~= true
        end,
        function(v)
            cfg().hideMinimapButton = not (v and true or false)
            if type(standaloneAddon.UpdateMinimapButton) == "function" then
                standaloneAddon:UpdateMinimapButton()
            end
        end)

    b:Header("Kick Macro")
    b:Cycle("Interrupt ability",
        function()
            return standaloneAddon:GetInterruptSpellChoices()
        end,
        function()
            return cfg().interruptSpell or "AUTO"
        end,
        function(v)
            cfg().interruptSpell = type(v) == "string" and v or "AUTO"
            ns:InitKickAssistPage()
        end,
        0,
        280,
        true)

    b:Desc("Use this macro for your class interrupt:")
    b:Desc("|cffd7e3ff" .. kickMacroPreview() .. "|r")
    AddTwoButtonsRow(
        b,
        "Copy Kick Macro Text",
        function()
            ShowCopyDialog("Copy Kick Macro", kickMacroPreview())
        end,
        "Create TNT: Kick Macro",
        function()
            standaloneAddon:CreateKickMacro()
        end
    )

    b:Header("Focus + Mark Macro")
    b:Desc("Use this macro to focus and mark your target:")
    b:Desc("|cffd7e3ff" .. focusMacroPreview() .. "|r")
    AddTwoButtonsRow(
        b,
        "Copy Focus Macro Text",
        function()
            ShowCopyDialog("Copy Focus Macro", focusMacroPreview())
        end,
        "Create TNT: Focus Macro",
        function()
            standaloneAddon:CreateFocusMacro()
        end
    )

    b:Header("Ready Check Announcement")
    b:Toggle("Announce kick target in party on ready check",
        function() return cfg().announceOnReadyCheck end,
        function(v)
            cfg().announceOnReadyCheck = v and true or false
        end)

    b:Input("Announcement message",
        function()
            return cfg().announceTemplate
        end,
        function(v)
            if type(v) ~= "string" or v == "" then
                cfg().announceTemplate = "My Kick target is {RAIDMARKER}"
                return
            end
            cfg().announceTemplate = v
        end)

    b:Desc("Preview: " .. announcementPreview())

    b:Toggle("M+",
        function() return cfg().announceInMythicPlus end,
        function(v) cfg().announceInMythicPlus = v and true or false end)

    b:Toggle("Mythic Dungeons",
        function() return cfg().announceInMythicDungeon end,
        function(v) cfg().announceInMythicDungeon = v and true or false end)

    b:Toggle("Heroic Dungeons",
        function() return cfg().announceInHeroicDungeon end,
        function(v) cfg().announceInHeroicDungeon = v and true or false end)

    b:Toggle("Normal Dungeons",
        function() return cfg().announceInNormalDungeon end,
        function(v) cfg().announceInNormalDungeon = v and true or false end)

    local h = b:Finalize()
    body:SetHeight(h)
    root:SetHeight(84 + h)
    parent:SetHeight(110 + h)

    ns.RefreshCurrentPage = function()
        ns:InitKickAssistPage()
    end
end
