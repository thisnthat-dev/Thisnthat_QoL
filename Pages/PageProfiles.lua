local ADDON_NAME, ns = ...

local function Trim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function ns:InitProfilesPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    local parent = ns.OptionsFrame.Content
    local W = ns.OptionsWidgets
    local Addon = (type(ns.GetAddon) == "function" and ns.GetAddon()) or ns.Addon

    local newProfileName = ""
    local deleteProfileName = ""
    local profileDialog = nil
    local newProfileInputRow = nil
    local PROFILE_BUTTON_WIDTH = 108

    local function EstimateEditBoxTextHeight(editBox)
        local text = tostring(editBox:GetText() or "")
        local lineCount = 1
        if text ~= "" then
            local _, breaks = string.gsub(text, "\n", "\n")
            lineCount = breaks + 1
        end

        local _, fontSize = editBox:GetFont()
        fontSize = tonumber(fontSize) or 12
        return (lineCount * (fontSize + 2))
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

    local function refreshProfilesPage()
        if ns.OptionsFrame and ns.OptionsFrame.ApplyCurrentAccent then
            ns.OptionsFrame:ApplyCurrentAccent()
        end

        if ns.OptionsFrame and ns.OptionsFrame.ApplyCurrentFont then
            ns.OptionsFrame:ApplyCurrentFont()
        end

        ns:InitProfilesPage()
    end

    local function EnsureProfileDialogButtons(dialog)
        if not dialog.cancelButton then
            dialog.cancelButton = W.ActionButton(dialog, "Cancel", 100, 24)
            dialog.cancelButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 12)
            dialog.cancelButton:SetScript("OnClick", function()
                dialog:Hide()
            end)
        end

        if not dialog.primaryButton then
            dialog.primaryButton = W.ActionButton(dialog, "Apply", 160, 24)
        end

        dialog.primaryButton:Show()
        dialog.primaryButton:ClearAllPoints()
        dialog.primaryButton:SetPoint("RIGHT", dialog.cancelButton, "LEFT", -8, 0)
    end

    local function EnsureProfileDialog()
        if profileDialog then
            EnsureProfileDialogButtons(profileDialog)
            return profileDialog
        end

        profileDialog = CreateFrame("Frame", "ThisnthatQoL_ProfileDialog", UIParent, "BackdropTemplate")
        profileDialog:SetSize(620, 360)
        profileDialog:SetPoint("CENTER")
        profileDialog:SetFrameStrata("FULLSCREEN_DIALOG")
        profileDialog:SetToplevel(true)
        profileDialog:SetMovable(true)
        profileDialog:EnableMouse(true)
        profileDialog:RegisterForDrag("LeftButton")
        profileDialog:SetScript("OnDragStart", profileDialog.StartMoving)
        profileDialog:SetScript("OnDragStop", profileDialog.StopMovingOrSizing)
        profileDialog:SetClampedToScreen(true)
        profileDialog:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        profileDialog:SetBackdropColor(0.06, 0.06, 0.06, 0.97)
        profileDialog:SetBackdropBorderColor(0.31, 0.30, 0.30, 0.9)
        profileDialog:Hide()

        profileDialog.title = profileDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        profileDialog.title:SetPoint("TOPLEFT", profileDialog, "TOPLEFT", 12, -12)
        profileDialog.title:SetTextColor(0.78, 0.23, 0.30, 1)
        W.ApplyFont(profileDialog.title, 0)

        profileDialog.desc = profileDialog:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        profileDialog.desc:SetPoint("TOPLEFT", profileDialog.title, "BOTTOMLEFT", 0, -6)
        profileDialog.desc:SetPoint("TOPRIGHT", profileDialog, "TOPRIGHT", -12, 0)
        profileDialog.desc:SetJustifyH("LEFT")
        profileDialog.desc:SetWordWrap(true)
        profileDialog.desc:SetTextColor(0.67, 0.67, 0.67, 0.95)
        W.ApplyFont(profileDialog.desc, -1)

        profileDialog.nameLabel = profileDialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        profileDialog.nameLabel:SetPoint("TOPLEFT", profileDialog.desc, "BOTTOMLEFT", 0, -12)
        profileDialog.nameLabel:SetText("Profile Name")
        profileDialog.nameLabel:SetTextColor(1, 1, 1, 0.9)
        W.ApplyFont(profileDialog.nameLabel, -1)

        profileDialog.nameEdit = CreateFrame("EditBox", nil, profileDialog, "BackdropTemplate")
        profileDialog.nameEdit:SetHeight(24)
        profileDialog.nameEdit:SetPoint("TOPLEFT", profileDialog.nameLabel, "BOTTOMLEFT", 0, -4)
        profileDialog.nameEdit:SetPoint("TOPRIGHT", profileDialog, "TOPRIGHT", -12, -70)
        profileDialog.nameEdit:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        profileDialog.nameEdit:SetBackdropColor(0.04, 0.04, 0.04, 0.95)
        profileDialog.nameEdit:SetBackdropBorderColor(0.31, 0.30, 0.30, 0.8)
        profileDialog.nameEdit:SetAutoFocus(false)
        profileDialog.nameEdit:SetTextInsets(6, 6, 0, 0)
        profileDialog.nameEdit:SetMaxLetters(64)
        profileDialog.nameEdit:SetTextColor(1, 1, 1, 0.95)
        W.ApplyFont(profileDialog.nameEdit, -1)

        profileDialog.overwriteCheck = CreateFrame("CheckButton", nil, profileDialog, "UICheckButtonTemplate")
        profileDialog.overwriteCheck:SetPoint("TOPLEFT", profileDialog.nameEdit, "BOTTOMLEFT", -2, -6)
        profileDialog.overwriteCheck:SetChecked(true)

        profileDialog.overwriteLabel = profileDialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        profileDialog.overwriteLabel:SetPoint("LEFT", profileDialog.overwriteCheck, "RIGHT", 2, 0)
        profileDialog.overwriteLabel:SetText("Overwrite if profile name already exists")
        profileDialog.overwriteLabel:SetTextColor(1, 1, 1, 0.9)
        W.ApplyFont(profileDialog.overwriteLabel, -1)

        profileDialog.sourceNameLabel = profileDialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        profileDialog.sourceNameLabel:SetText("Profile")
        profileDialog.sourceNameLabel:SetTextColor(1, 1, 1, 0.9)
        W.ApplyFont(profileDialog.sourceNameLabel, -1)

        profileDialog.sourceNameText = profileDialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        profileDialog.sourceNameText:SetJustifyH("LEFT")
        profileDialog.sourceNameText:SetPoint("LEFT", profileDialog.sourceNameLabel, "RIGHT", 10, 0)
        profileDialog.sourceNameText:SetPoint("RIGHT", profileDialog, "RIGHT", -12, 0)
        profileDialog.sourceNameText:SetTextColor(0.67, 0.67, 0.67, 0.95)
        W.ApplyFont(profileDialog.sourceNameText, -1)

        profileDialog.importStatus = profileDialog:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        profileDialog.importStatus:SetTextColor(0.67, 0.67, 0.67, 0.95)
        profileDialog.importStatus:SetJustifyH("LEFT")
        W.ApplyFont(profileDialog.importStatus, -1)

        local bodyTopAnchor = CreateFrame("Frame", nil, profileDialog)
        bodyTopAnchor:SetSize(1, 1)
        bodyTopAnchor:SetPoint("TOPLEFT", profileDialog.nameEdit, "BOTTOMLEFT", 0, -10)

        profileDialog.bodyContainer = CreateFrame("Frame", nil, profileDialog, "BackdropTemplate")
        profileDialog.bodyContainer:SetPoint("TOPLEFT", bodyTopAnchor, "TOPLEFT", 0, 0)
        profileDialog.bodyContainer:SetPoint("TOPRIGHT", profileDialog, "TOPRIGHT", -12, 0)
        profileDialog.bodyContainer:SetPoint("BOTTOM", profileDialog, "BOTTOM", 0, 44)
        profileDialog.bodyContainer:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        profileDialog.bodyContainer:SetBackdropColor(0.03, 0.03, 0.03, 0.98)
        profileDialog.bodyContainer:SetBackdropBorderColor(0.31, 0.30, 0.30, 0.8)

        profileDialog.bodyScroll = CreateFrame("ScrollFrame", nil, profileDialog.bodyContainer, "UIPanelScrollFrameTemplate")
        profileDialog.bodyScroll:SetPoint("TOPLEFT", profileDialog.bodyContainer, "TOPLEFT", 6, -6)
        profileDialog.bodyScroll:SetPoint("BOTTOMRIGHT", profileDialog.bodyContainer, "BOTTOMRIGHT", -28, 6)
        profileDialog.bodyScroll:EnableMouseWheel(true)
        profileDialog.bodyScroll:EnableMouse(true)

        profileDialog.body = CreateFrame("EditBox", nil, profileDialog.bodyScroll)
        profileDialog.body:SetAutoFocus(false)
        profileDialog.body:EnableMouse(true)
        profileDialog.body:SetMultiLine(true)
        profileDialog.body:SetTextInsets(4, 4, 4, 4)
        profileDialog.body:SetJustifyH("LEFT")
        profileDialog.body:SetJustifyV("TOP")
        profileDialog.body:SetTextColor(1, 1, 1, 0.95)
        profileDialog.body:SetFontObject(ChatFontNormal)
        W.ApplyFont(profileDialog.body, -1)
        profileDialog.body:SetPoint("TOPLEFT", profileDialog.bodyScroll, "TOPLEFT", 0, 0)
        profileDialog.body:SetWidth(560)
        profileDialog.body:SetHeight(120)
        profileDialog.bodyScroll:SetScrollChild(profileDialog.body)

        profileDialog.bodyContainer:SetScript("OnSizeChanged", function(container, width, height)
            local innerWidth = math.max(80, (width or 0) - 38)
            local innerHeight = math.max(80, (height or 0) - 12)
            profileDialog.body:SetWidth(innerWidth)

            local textHeight = EstimateEditBoxTextHeight(profileDialog.body)
            profileDialog.body:SetHeight(math.max(innerHeight, textHeight + 12))
        end)

        profileDialog.body:SetScript("OnTextChanged", function(self)
            local h = profileDialog.bodyScroll:GetHeight() or 0
            local minHeight = math.max(80, h)
            local textHeight = EstimateEditBoxTextHeight(self)
            self:SetHeight(math.max(minHeight, textHeight + 12))

            if type(profileDialog.onBodyTextChanged) == "function" then
                profileDialog.onBodyTextChanged(self)
            end
        end)

        profileDialog.bodyScroll:SetScript("OnMouseWheel", function(self, delta)
            local current = self:GetVerticalScroll() or 0
            local nextOffset = current - (delta * 20)
            if nextOffset < 0 then
                nextOffset = 0
            end
            self:SetVerticalScroll(nextOffset)
        end)

        local function FocusBodyForTyping()
            profileDialog.body:SetFocus()
            local text = tostring(profileDialog.body:GetText() or "")
            profileDialog.body:SetCursorPosition(string.len(text))
        end

        profileDialog.body:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)

        profileDialog.body:SetScript("OnEditFocusGained", function(self)
            local text = tostring(self:GetText() or "")
            self:SetCursorPosition(string.len(text))
            profileDialog.bodyContainer:SetBackdropBorderColor(0.78, 0.23, 0.30, 0.95)
        end)

        profileDialog.body:SetScript("OnEditFocusLost", function()
            profileDialog.bodyContainer:SetBackdropBorderColor(0.31, 0.30, 0.30, 0.8)
        end)

        -- Make the whole text area focus the edit box so users can click anywhere to type.
        profileDialog.bodyContainer:SetScript("OnMouseDown", function()
            FocusBodyForTyping()
        end)
        profileDialog.bodyScroll:SetScript("OnMouseDown", function()
            FocusBodyForTyping()
        end)
        profileDialog.body:SetScript("OnMouseDown", function(self)
            self:SetFocus()
            local text = tostring(self:GetText() or "")
            self:SetCursorPosition(string.len(text))
        end)

        EnsureProfileDialogButtons(profileDialog)

        return profileDialog
    end

    local function ShowExportDialog()
        local ok, payload = Addon:ExportProfile()
        if not ok then
            Addon:Print("Profile export failed: " .. tostring(payload))
            return
        end

        local dialog = EnsureProfileDialog()
        dialog.onBodyTextChanged = nil
        dialog:SetSize(620, 360)
        local activeName = Addon:GetActiveProfileName()
        dialog.title:SetText("Export Profile")
        dialog.desc:SetText("Copy this text and keep it somewhere safe. It includes profile name and settings.")
        dialog.nameLabel:Hide()
        dialog.nameEdit:Hide()
        dialog.overwriteCheck:Hide()
        dialog.overwriteLabel:Hide()
        dialog.sourceNameLabel:Hide()
        dialog.sourceNameText:Hide()
        dialog.importStatus:Hide()
        dialog.bodyContainer:ClearAllPoints()
        dialog.bodyContainer:SetPoint("TOPLEFT", dialog.desc, "BOTTOMLEFT", 0, -10)
        dialog.bodyContainer:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -12, -46)
        dialog.bodyContainer:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 44)
        dialog.bodyContainer:Show()
        dialog.body:SetText(payload)
        dialog.bodyScroll:SetVerticalScroll(0)
        dialog.body:Show()
        dialog.body:SetCursorPosition(0)
        dialog.body:SetFocus()
        dialog.body:HighlightText(0)
        dialog.primaryButton.lbl:SetText("Close")
        dialog.primaryButton:SetScript("OnClick", function()
            dialog:Hide()
        end)
        dialog.primaryButton:ClearAllPoints()
        dialog.primaryButton:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 12)
        dialog.cancelButton:Hide()
        Addon:Print("Exported active profile '" .. tostring(activeName) .. "'.")
        dialog:Show()
    end

    local function ShowConfirmDialog(titleText, descriptionText, buttonText, onConfirm)
        local dialog = EnsureProfileDialog()
        dialog.onBodyTextChanged = nil
        dialog:SetSize(460, 210)
        dialog.title:SetText(titleText or "Confirm")
        dialog.desc:SetText(descriptionText or "Are you sure?")

        dialog.nameLabel:Hide()
        dialog.nameEdit:Hide()
        dialog.overwriteCheck:Hide()
        dialog.overwriteLabel:Hide()
        dialog.sourceNameLabel:Hide()
        dialog.sourceNameText:Hide()
        dialog.importStatus:Hide()
        dialog.bodyContainer:Hide()
        dialog.body:Hide()

        dialog.cancelButton:Show()
        dialog.cancelButton:ClearAllPoints()
        dialog.cancelButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 12)
        dialog.primaryButton:ClearAllPoints()
        dialog.primaryButton:SetPoint("RIGHT", dialog.cancelButton, "LEFT", -8, 0)
        dialog.cancelButton:Show()
        dialog.primaryButton.lbl:SetText(buttonText or "Confirm")
        dialog.primaryButton:SetScript("OnClick", function()
            dialog:Hide()
            if type(onConfirm) == "function" then
                onConfirm()
            end
        end)

        dialog:Show()
    end

    local function ShowImportDialog()
        local dialog = EnsureProfileDialog()
        dialog:SetSize(620, 440)
        dialog.title:SetText("Import Profile")
        dialog.desc:SetText("Paste an exported profile string below. The source profile name is detected automatically. Use New Profile only if you want to import under a different name.")

        dialog.bodyContainer:ClearAllPoints()
        dialog.bodyContainer:SetPoint("TOPLEFT", dialog.desc, "BOTTOMLEFT", 0, -10)
        dialog.bodyContainer:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -12, -70)
        dialog.bodyContainer:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 148)
        dialog.bodyContainer:Show()

        dialog.sourceProfileName = ""
        dialog.sourceNameLabel:Show()
        dialog.sourceNameText:Show()
        dialog.sourceNameText:SetText("Waiting for valid import string")
        dialog.sourceNameText:SetTextColor(0.67, 0.67, 0.67, 0.95)
        dialog.sourceNameLabel:ClearAllPoints()
        dialog.sourceNameLabel:SetPoint("TOPLEFT", dialog.bodyContainer, "BOTTOMLEFT", 0, -12)
        dialog.sourceNameText:ClearAllPoints()
        dialog.sourceNameText:SetPoint("LEFT", dialog.sourceNameLabel, "RIGHT", 10, 0)
        dialog.sourceNameText:SetPoint("RIGHT", dialog, "RIGHT", -12, 0)

        dialog.nameLabel:Show()
        dialog.nameLabel:SetText("New Profile")
        dialog.nameLabel:ClearAllPoints()
        dialog.nameLabel:SetPoint("TOPLEFT", dialog.sourceNameLabel, "BOTTOMLEFT", 0, -10)
        dialog.nameEdit:Show()
        dialog.nameEdit:SetText("")
        dialog.nameEdit:ClearAllPoints()
        dialog.nameEdit:SetPoint("TOPLEFT", dialog.nameLabel, "BOTTOMLEFT", 0, -4)
        dialog.nameEdit:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -12, -320)

        dialog.importStatus:Show()
        dialog.importStatus:SetText("Paste a valid profile string to detect profile name.")
        dialog.importStatus:SetTextColor(0.67, 0.67, 0.67, 0.95)
        dialog.importStatus:ClearAllPoints()
        dialog.importStatus:SetPoint("TOPLEFT", dialog.nameEdit, "BOTTOMLEFT", 0, -6)
        dialog.importStatus:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -12, -6)

        dialog.overwriteCheck:Show()
        dialog.overwriteLabel:Show()
        dialog.overwriteCheck:SetChecked(true)
        dialog.overwriteCheck:ClearAllPoints()
        dialog.overwriteCheck:SetPoint("TOPLEFT", dialog.importStatus, "BOTTOMLEFT", -2, -6)
        dialog.overwriteLabel:ClearAllPoints()
        dialog.overwriteLabel:SetPoint("LEFT", dialog.overwriteCheck, "RIGHT", 2, 0)

        dialog.body:Show()
        dialog.body:SetText("")
        dialog.bodyScroll:SetVerticalScroll(0)
        dialog.body:ClearFocus()

        local function UpdateImportSourceName()
            local text = dialog.body:GetText()
            local okInspect, result = Addon:InspectImportProfile(text)
            if okInspect then
                dialog.sourceProfileName = Trim(result)
                dialog.sourceNameText:SetText(dialog.sourceProfileName)

                local root = Addon:GetProfileRoot()
                local exists = type(root.profiles[dialog.sourceProfileName]) == "table"
                if exists then
                    dialog.sourceNameText:SetTextColor(0.94, 0.37, 0.37, 0.95)
                else
                    dialog.sourceNameText:SetTextColor(0.52, 0.81, 0.52, 0.95)
                end

                dialog.importStatus:SetText("Valid profile string detected.")
                dialog.importStatus:SetTextColor(0.52, 0.81, 0.52, 0.95)
                dialog.primaryButton:Enable()
            else
                dialog.sourceProfileName = ""
                dialog.sourceNameText:SetText("Waiting for valid import string")
                dialog.sourceNameText:SetTextColor(0.67, 0.67, 0.67, 0.95)
                local errText = Trim(result)
                if errText == "" then
                    errText = "Invalid profile string"
                end
                dialog.importStatus:SetText(errText)
                dialog.importStatus:SetTextColor(0.94, 0.37, 0.37, 0.95)
                dialog.primaryButton:Disable()
            end
        end

        dialog.onBodyTextChanged = UpdateImportSourceName

        dialog.cancelButton:Show()
        dialog.cancelButton:ClearAllPoints()
        dialog.cancelButton:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 12)
        dialog.primaryButton:ClearAllPoints()
        dialog.primaryButton:SetPoint("RIGHT", dialog.cancelButton, "LEFT", -8, 0)
        dialog.primaryButton.lbl:SetText("Import")
        dialog.primaryButton:SetScript("OnClick", function()
            local newName = Trim(dialog.nameEdit:GetText())
            local requestedName = newName ~= "" and newName or Trim(dialog.sourceProfileName)
            if requestedName == "" then
                Addon:Print("Profile import failed: Invalid profile string")
                return
            end

            local payload = dialog.body:GetText()
            local collisionMode = dialog.overwriteCheck:GetChecked() and "overwrite" or "auto_rename"
            local ok, result = Addon:ImportProfile(payload, requestedName, true, {
                collisionMode = collisionMode,
            })
            if not ok then
                Addon:Print("Profile import failed: " .. tostring(result))
                return
            end

            Addon:Print("Imported and selected profile '" .. tostring(result) .. "'.")
            dialog:Hide()
            refreshProfilesPage()
        end)

        UpdateImportSourceName()
        dialog:Show()
    end

    local contentColumn = CreateFrame("Frame", nil, parent)
    contentColumn:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    contentColumn:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)

    local function UpdateContentColumnWidth()
        local parentWidth = parent:GetWidth() or 0
        if parentWidth <= 0 then
            contentColumn:SetWidth(360)
            return
        end

        -- Use roughly 60% of the page width so controls stay readable without spanning too wide.
        contentColumn:SetWidth(math.max(320, math.floor(parentWidth * 0.6) - 8))
    end

    UpdateContentColumnWidth()
    contentColumn:SetScript("OnShow", UpdateContentColumnWidth)
    parent:HookScript("OnSizeChanged", UpdateContentColumnWidth)

    local b = W.Builder(contentColumn)

    b:Header("Profiles")
    b:Desc("Select, create, import, export, clone, and delete profiles.")

    b:Cycle("Profiles",
        function()
            local items = {}
            for _, name in ipairs(Addon:GetProfileNames()) do
                items[#items + 1] = { value = name, label = name }
            end
            return items
        end,
        function()
            return Addon:GetActiveProfileName()
        end,
        function(value)
            local ok, err = Addon:SetActiveProfile(value)
            if not ok then
                Addon:Print("Could not switch profile: " .. tostring(err))
                return
            end
            Addon:Print("Active profile set to '" .. tostring(value) .. "'.")
            refreshProfilesPage()
        end,
        0,
        220)

    AddTwoColumnRow(b,
        function(col)
            col:Button("Export", function()
                ShowExportDialog()
            end, 0, PROFILE_BUTTON_WIDTH)
        end,
        function(col)
            col:Button("Import", function()
                ShowImportDialog()
            end, 0, PROFILE_BUTTON_WIDTH)
        end)

    b:Spacer(10, 2)
    b:Desc("Create")

    local function CreateAndSelectProfile()
        if newProfileInputRow and newProfileInputRow.edit then
            newProfileName = Trim(newProfileInputRow.edit:GetText())
        end

        local name = Trim(newProfileName)
        local ok, err = Addon:CreateProfile(name, true)
        if not ok then
            Addon:Print("Could not create profile: " .. tostring(err))
            return
        end

        Addon:Print("Created and selected profile '" .. tostring(name) .. "'.")
        newProfileName = ""
        refreshProfilesPage()
    end

    local function CloneToNewProfile()
        if newProfileInputRow and newProfileInputRow.edit then
            newProfileName = Trim(newProfileInputRow.edit:GetText())
        end

        local name = Trim(newProfileName)
        local sourceName = Addon:GetActiveProfileName()
        local ok, err = Addon:CloneProfile(name, sourceName, true)
        if not ok then
            Addon:Print("Could not clone profile: " .. tostring(err))
            return
        end

        Addon:Print("Cloned profile '" .. tostring(sourceName) .. "' into '" .. tostring(name) .. "'.")
        newProfileName = ""
        refreshProfilesPage()
    end

    newProfileInputRow = b:Input("New Profile",
        function() return newProfileName end,
        function(v)
            newProfileName = Trim(v)
        end,
        0)

    if newProfileInputRow and newProfileInputRow.edit then
        newProfileInputRow.edit:SetScript("OnTextChanged", function(self)
            newProfileName = Trim(self:GetText())
        end)
        newProfileInputRow.edit:SetScript("OnEnterPressed", function(self)
            newProfileName = Trim(self:GetText())
            self:ClearFocus()
            CreateAndSelectProfile()
        end)
    end

    AddTwoColumnRow(b,
        function(col)
            col:Button("Create", function()
                CreateAndSelectProfile()
            end, 0, PROFILE_BUTTON_WIDTH)
        end,
        function(col)
            col:Button("Clone", function()
                CloneToNewProfile()
            end, 0, PROFILE_BUTTON_WIDTH)
        end)

    b:Spacer(10, 2)
    b:Desc("Delete")

    b:Cycle("Profiles",
        function()
            local items = {}
            for _, name in ipairs(Addon:GetProfileNames()) do
                if name ~= Addon:GetActiveProfileName() then
                    items[#items + 1] = { value = name, label = name }
                end
            end
            if #items == 0 then
                items[1] = { value = "", label = "No deletable profiles" }
            end
            return items
        end,
        function()
            local activeName = Addon:GetActiveProfileName()
            local names = Addon:GetProfileNames()
            local found = false
            for _, name in ipairs(names) do
                if name == deleteProfileName and name ~= activeName then
                    found = true
                    break
                end
            end

            if not found then
                deleteProfileName = ""
                for _, name in ipairs(names) do
                    if name ~= activeName then
                        deleteProfileName = name
                        break
                    end
                end
            end

            return deleteProfileName
        end,
        function(value)
            deleteProfileName = type(value) == "string" and value or ""
        end,
        0,
        220)

    b:Button("Delete", function()
        local target = Trim(deleteProfileName)
        if target == "" then
            Addon:Print("No deletable profile is selected.")
            return
        end

        ShowConfirmDialog(
            "Delete Profile",
            "Delete profile '" .. tostring(target) .. "'?\nThis cannot be undone.",
            "Delete",
            function()
                local ok, err = Addon:DeleteProfile(target)
                if not ok then
                    Addon:Print("Could not delete profile: " .. tostring(err))
                    return
                end

                Addon:Print("Deleted profile '" .. tostring(target) .. "'.")
                deleteProfileName = ""
                refreshProfilesPage()
            end)
    end, 0, PROFILE_BUTTON_WIDTH)

    b:Spacer(12, 4)
    b:Desc("Reset Current Profile to Default")
    b:Spacer(4, 6)
    b:Button("Reset Current Profile to Default", function()
        local activeName = Addon:GetActiveProfileName()

        ShowConfirmDialog(
            "Reset Profile",
            "Reset profile '" .. tostring(activeName) .. "' to addon defaults?\nThis cannot be undone.",
            "Reset",
            function()
                local ok, err = Addon:ResetProfile(activeName, true)
                if not ok then
                    Addon:Print("Could not reset profile: " .. tostring(err))
                    return
                end

                Addon:Print("Reset profile '" .. tostring(activeName) .. "' to defaults.")
                refreshProfilesPage()
            end)
    end, 0, PROFILE_BUTTON_WIDTH)

    b:Desc("Safety rules: the active profile cannot be deleted. Switch to another profile first.")

    b:Finalize()
    ns.RefreshCurrentPage = function()
        ns:InitProfilesPage()
    end
end
