local ADDON_NAME, ns = ...

function ns:InitFPSPage()
    local parent = ns.OptionsFrame.Content
    local W      = ns.OptionsWidgets
    local C      = ns.OptionsColors
    local Addon  = (type(ns.GetAddon) == "function" and ns.GetAddon()) or ns.Addon
    local module = Addon:GetModule("fps")

    local function ApplyFont(target, offset)
        if W and W.ApplyFont then
            W.ApplyFont(target, offset)
        end
    end

    local function MakeActionButton(parentFrame, text, width, onClick)
        local btn = W.ActionButton(parentFrame, text, width or 120, 22)
        btn:SetScript("OnClick", onClick)
        return btn
    end

    local function ShowCVarTooltip(owner, def)
        if not owner or not GameTooltip then
            return
        end

        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(def.label or def.cvar or "CVar", 1, 1, 1)
        GameTooltip:AddDoubleLine("Current Value", tostring(module and module:GetDisplayCurrentValue(def.cvar) or ""), 0.85, 0.85, 0.85, 1, 1, 1)
        GameTooltip:AddDoubleLine("Recommended Value", tostring(module and module:GetDisplayRecommendedValue(def.cvar) or ""), 0.85, 0.85, 0.85, 0.13, 0.77, 0.37)
        GameTooltip:AddDoubleLine("CVAR Name", tostring(def.cvar or ""), 0.85, 0.85, 0.85, 1, 1, 1)
        GameTooltip:Show()
    end

    local function AttachCVarTooltip(frame, def)
        frame:EnableMouse(true)
        frame:SetScript("OnEnter", function(self)
            ShowCVarTooltip(self, def)
        end)
        frame:SetScript("OnLeave", function()
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)
    end

    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
    header:SetHeight(148)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", header, "TOPLEFT", 2, -2)
    title:SetText("FPS Optimizations")
    title:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    ApplyFont(title, 2)

    local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetPoint("TOPRIGHT", header, "TOPRIGHT", -2, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWordWrap(true)
    subtitle:SetText("Apply all recommended settings or expand sections below to tune individual CVars. Green means optimal. Yellow means different.")
    ApplyFont(subtitle, -1)

    local applyAllBtn = MakeActionButton(header, "Apply All Recommended", 180, function()
        if module and type(module.ApplyAll) == "function" then
            local updated, failed = module:ApplyAll()
            Addon:Print("FPS: applied " .. tostring(updated) .. " settings." .. (failed > 0 and " " .. tostring(failed) .. " failed." or ""))
        end
        if ns.RefreshCurrentPage then ns.RefreshCurrentPage() end
    end)
    applyAllBtn:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)

    local restoreBtn = MakeActionButton(header, "Restore Previous", 140, function()
        if module and type(module.RestoreAll) == "function" then
            local restored, failed = module:RestoreAll()
            Addon:Print("FPS: restored " .. tostring(restored) .. " settings." .. (failed > 0 and " " .. tostring(failed) .. " failed." or ""))
        end
        if ns.RefreshCurrentPage then ns.RefreshCurrentPage() end
    end)
    restoreBtn:SetPoint("LEFT", applyAllBtn, "RIGHT", 8, 0)

    local enableRow = CreateFrame("Frame", nil, header, "BackdropTemplate")
    enableRow:SetHeight(30)
    enableRow:SetPoint("TOPLEFT", applyAllBtn, "BOTTOMLEFT", 0, -10)
    enableRow:SetPoint("TOPRIGHT", header, "TOPRIGHT", -2, 0)
    enableRow:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    enableRow:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.06)
    enableRow:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

    local enableLabel = enableRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    enableLabel:SetPoint("LEFT", enableRow, "LEFT", 10, 0)
    enableLabel:SetText("Enable FPS Module")
    enableLabel:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
    ApplyFont(enableLabel, -1)

    local toggle = CreateFrame("CheckButton", nil, enableRow, "UICheckButtonTemplate")
    toggle:SetPoint("RIGHT", enableRow, "RIGHT", -8, 0)
    toggle:SetChecked(Addon:IsModuleEnabled("fps"))
    toggle:SetScript("OnClick", function(self)
        Addon.db.modules.fps.enabled = self:GetChecked() and true or false
        Addon:Print("FPS module " .. (self:GetChecked() and "enabled" or "disabled") .. ".")
    end)

    local sectionsHost = CreateFrame("Frame", nil, parent)
    sectionsHost:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
    sectionsHost:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -8)
    sectionsHost:SetHeight(1)

    local sections = {}
    local rowsToRefresh = {}

    local function CreateCVarRow(parentFrame, def)
        local row = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
        row:SetHeight(26)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        row:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.06)
        AttachCVarTooltip(row, def)

        local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        name:SetPoint("LEFT", row, "LEFT", 6, 0)
        name:SetWidth(240)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        name:SetText(def.label)
        name:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        ApplyFont(name, -1)
        AttachCVarTooltip(name, def)

        local cur = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cur:SetPoint("LEFT", name, "RIGHT", 6, 0)
        cur:SetWidth(120)
        cur:SetJustifyH("LEFT")
        cur:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.95)
        ApplyFont(cur, -1)

        local rec = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rec:SetPoint("LEFT", cur, "RIGHT", 8, 0)
        rec:SetWidth(120)
        rec:SetJustifyH("LEFT")
        ApplyFont(rec, -1)
        AttachCVarTooltip(rec, def)

        local applyBtn = MakeActionButton(row, "Apply", 56, function()
            if module then module:ApplyCVar(def.cvar) end
            if ns.RefreshCurrentPage then ns.RefreshCurrentPage() end
        end)
        applyBtn:SetPoint("RIGHT", row, "RIGHT", -66, 0)
        AttachCVarTooltip(applyBtn, def)

        local revertBtn = MakeActionButton(row, "Revert", 56, function()
            if module then module:RevertCVar(def.cvar) end
            if ns.RefreshCurrentPage then ns.RefreshCurrentPage() end
        end)
        revertBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        AttachCVarTooltip(revertBtn, def)

        rowsToRefresh[#rowsToRefresh + 1] = {
            cvar = def.cvar,
            name = name,
            cur = cur,
            rec = rec,
            applyBtn = applyBtn,
            revertBtn = revertBtn,
        }

        return row
    end

    local function CreateSection(parentFrame, titleText, entries)
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
        icon:SetText("-")
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

        local y = -2
        for i, entry in ipairs(entries) do
            local row = CreateCVarRow(content, entry)
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 2, y)
            row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -2, y)
            y = y - 28
        end
        content:SetHeight(math.abs(y) + 2)

        wrap.open = true
        wrap.content = content
        wrap.head = head
        wrap.icon = icon

        function wrap:RecalcHeight()
            local h = 30
            if self.open then
                h = h + self.content:GetHeight() + 2
            end
            self:SetHeight(h)
        end

        head:SetScript("OnClick", function()
            wrap.open = not wrap.open
            wrap.content:SetShown(wrap.open)
            wrap.icon:SetText(wrap.open and "-" or "+")
            wrap:RecalcHeight()
            if ns.RefreshCurrentPage then ns.RefreshCurrentPage() end
        end)

        wrap:RecalcHeight()
        return wrap
    end

    local groups = (module and module.GetCategoryGroups and module:GetCategoryGroups()) or {}
    for _, group in ipairs(groups) do
        sections[#sections + 1] = CreateSection(sectionsHost, group.name, group.entries)
    end

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
        parent:SetHeight(header:GetHeight() + y + 40)
    end

    local function Refresh()
        for _, row in ipairs(rowsToRefresh) do
            local cvar = row.cvar
            local currentDisplay = tostring(module:GetDisplayCurrentValue(cvar) or "")
            local optimalDisplay = tostring(module:GetDisplayRecommendedValue(cvar) or "")
            local differs = module:IsCVarDifferent(cvar)
            local statusR, statusG, statusB = differs and 1 or 0.13, differs and 0.33 or 0.77, differs and 0.33 or 0.37
            local recR, recG, recB = differs and C.YELLOW.r or 0.13, differs and C.YELLOW.g or 0.77, differs and C.YELLOW.b or 0.37

            row.name:SetTextColor(statusR, statusG, statusB, 1)
            row.cur:SetText(currentDisplay)
            row.cur:SetTextColor(statusR, statusG, statusB, 1)
            row.rec:SetText(optimalDisplay)
            row.rec:SetTextColor(recR, recG, recB, 1)
            row.applyBtn:SetShown(differs)
            row.revertBtn:SetShown(module:HasBackup(cvar))
        end

        restoreBtn:SetAlpha((module and module:HasAnyBackup()) and 1 or 0.5)
        RelayoutSections()
    end

    ns.RefreshCurrentPage = Refresh
    Refresh()
end
