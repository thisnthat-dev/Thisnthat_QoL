local ADDON_NAME, ns = ...

function ns:InitMPlusRewardsPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    local parent = ns.OptionsFrame.Content
    local W = ns.OptionsWidgets
    local C = ns.OptionsColors
    local Addon = (type(ns.GetAddon) == "function" and ns.GetAddon()) or ns.Addon
    local module = Addon:GetModule("MPlusRewards")
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local ANCHOR_POINTS = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }

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

    local function NormalizePoint(value, fallback)
        if type(value) ~= "string" then
            return fallback
        end
        local upper = string.upper(value)
        for _, point in ipairs(ANCHOR_POINTS) do
            if upper == point then
                return point
            end
        end
        return fallback
    end

    local function pointItems()
        local items = {}
        for _, point in ipairs(ANCHOR_POINTS) do
            items[#items + 1] = { value = point, label = point }
        end
        return items
    end

    local function cfg()
        Addon.db.MPlusRewards = type(Addon.db.MPlusRewards) == "table" and Addon.db.MPlusRewards or {}
        local db = Addon.db.MPlusRewards
        db.attachToPVE = db.attachToPVE ~= false
        local legacyX = tonumber(db.x) or 0
        local legacyY = tonumber(db.y) or -1
        db.attachedX = tonumber(db.attachedX)
        db.attachedY = tonumber(db.attachedY)
        db.detachedX = tonumber(db.detachedX)
        db.detachedY = tonumber(db.detachedY)
        if db.attachedX == nil then db.attachedX = legacyX end
        if db.attachedY == nil then db.attachedY = legacyY end
        if db.detachedX == nil then db.detachedX = legacyX end
        if db.detachedY == nil then db.detachedY = legacyY end
        db.x = nil
        db.y = nil
        db.point = NormalizePoint(db.point, "BOTTOMLEFT")
        db.relativePoint = NormalizePoint(db.relativePoint, "BOTTOMRIGHT")
        db.scale = tonumber(db.scale) or 1
        db.alpha = tonumber(db.alpha) or 0.95
        db.hideBackground = db.hideBackground and true or false
        db.hideBorder = db.hideBorder and true or false
        db.borderSize = Clamp(math.floor((tonumber(db.borderSize) or 1) + 0.5), 0, 8, 1)
        db.backgroundColor = type(db.backgroundColor) == "table" and db.backgroundColor or { r = 0.08, g = 0.08, b = 0.08, a = 0.94 }
        db.borderColor = type(db.borderColor) == "table" and db.borderColor or { r = 0.31, g = 0.30, b = 0.30, a = 0.85 }
        return db
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

    local function apply()
        if module and type(module.Refresh) == "function" then
            module:Refresh()
        end
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
        if W and W.ApplyFont then W.ApplyFont(icon, 0) end

        local label = head:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        label:SetText(titleText)
        label:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        if W and W.ApplyFont then W.ApplyFont(label, 0) end

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
        local mid = CreateFrame("Frame", nil, row)
        local right = CreateFrame("Frame", nil, row)

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

    local function AddCompactInput(builder, label, getVal, setVal, gap)
        local f = CreateFrame("Frame", nil, builder.parent, "BackdropTemplate")
        f:SetHeight(34)
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        f:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.14)
        f:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", f, "LEFT", 10, 0)
        lbl:SetWidth(110)
        lbl:SetText(label)
        lbl:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        lbl:SetJustifyH("LEFT")
        if W and W.ApplyFont then W.ApplyFont(lbl, -1) end

        local edit = CreateFrame("EditBox", nil, f, "BackdropTemplate")
        edit:SetHeight(22)
        edit:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
        edit:SetPoint("RIGHT", f, "RIGHT", -10, 0)
        edit:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        edit:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        edit:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.55)
        if W and W.ApplyFont then W.ApplyFont(edit, -1) end
        edit:SetTextColor(1, 1, 1, 0.9)
        edit:SetTextInsets(6, 6, 0, 0)
        edit:SetAutoFocus(false)
        edit:SetMaxLetters(3)

        edit:SetScript("OnEnterPressed", function(self)
            if setVal then setVal(self:GetText()) end
            self:ClearFocus()
        end)
        edit:SetScript("OnEscapePressed", function(self)
            self:SetText(getVal and getVal() or "")
            self:ClearFocus()
        end)
        edit:SetText(getVal and getVal() or "")
        f:SetScript("OnShow", function() edit:SetText(getVal and getVal() or "") end)

        return builder:_Attach(f, 34, gap)
    end

    local root = CreateFrame("Frame", nil, parent)
    root:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    root:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -10)
    root:SetHeight(1)

    local title = root:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", root, "TOPLEFT", 2, -2)
    title:SetText("M+ Rewards")
    title:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    if W and W.ApplyFont then W.ApplyFont(title, 2) end

    local subtitle = root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetPoint("TOPRIGHT", root, "TOPRIGHT", -2, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWordWrap(true)
    subtitle:SetText("Configure panel position and appearance. Detached position is tracked by dragging the panel and restored automatically.")
    if W and W.ApplyFont then W.ApplyFont(subtitle, -1) end

    local enableRow = CreateFrame("Frame", nil, root, "BackdropTemplate")
    enableRow:SetHeight(30)
    enableRow:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
    enableRow:SetPoint("TOPRIGHT", subtitle, "BOTTOMRIGHT", 0, -10)
    enableRow:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    enableRow:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.06)
    enableRow:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)

    local enableLabel = enableRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    enableLabel:SetPoint("LEFT", enableRow, "LEFT", 10, 0)
    enableLabel:SetText("Enable M+ Rewards")
    enableLabel:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
    if W and W.ApplyFont then W.ApplyFont(enableLabel, -1) end

    local enableToggle = CreateFrame("CheckButton", nil, enableRow, "UICheckButtonTemplate")
    enableToggle:SetPoint("RIGHT", enableRow, "RIGHT", -8, 0)
    enableToggle:SetChecked(Addon:IsModuleEnabled("MPlusRewards"))
    enableToggle:SetScript("OnClick", function(self)
        Addon.db.modules.MPlusRewards = Addon.db.modules.MPlusRewards or {}
        if module and type(module.SetEnabled) == "function" then
            module:SetEnabled(self:GetChecked())
        else
            Addon.db.modules.MPlusRewards.enabled = self:GetChecked() and true or false
        end
        apply()
    end)

    local sectionsHost = CreateFrame("Frame", nil, root)
    sectionsHost:SetPoint("TOPLEFT", enableRow, "BOTTOMLEFT", 0, -10)
    sectionsHost:SetPoint("TOPRIGHT", enableRow, "BOTTOMRIGHT", 0, -10)
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
        root:SetHeight(84 + y)
        parent:SetHeight(110 + y)
    end

    local positionSection = CreateSection(sectionsHost, "Position", true, RelayoutSections)
    sections[#sections + 1] = positionSection

    do
        local b = W.Builder(positionSection.content)

        b:Toggle("Attach Panel To PVE Window",
            function() return cfg().attachToPVE end,
            function(v)
                cfg().attachToPVE = v and true or false
                apply()
                ns:InitMPlusRewardsPage()
            end)

        AddTwoColumnRow(b,
            function(lb)
                lb:Cycle("Anchor Point",
                    function() return pointItems() end,
                    function() return cfg().point end,
                    function(v)
                        cfg().point = NormalizePoint(v, "BOTTOMLEFT")
                        apply()
                    end)
            end,
            function(rb)
                rb:Cycle("Relative Anchor Point",
                    function() return pointItems() end,
                    function() return cfg().relativePoint end,
                    function(v)
                        cfg().relativePoint = NormalizePoint(v, "BOTTOMRIGHT")
                        apply()
                    end)
            end)

        if cfg().attachToPVE then
            AddTwoColumnRow(b,
                function(lb)
                    lb:Input("X Offset",
                        function() return tostring(cfg().attachedX or 0) end,
                        function(v)
                            cfg().attachedX = tonumber(v) or cfg().attachedX or 0
                            apply()
                        end)
                end,
                function(rb)
                    rb:Input("Y Offset",
                        function() return tostring(cfg().attachedY or -1) end,
                        function(v)
                            cfg().attachedY = tonumber(v) or cfg().attachedY or -1
                            apply()
                        end)
                end)
        end

        b:Button("Reset Attached Position", function()
            cfg().attachedX = 0
            cfg().attachedY = -1
            cfg().point = "BOTTOMLEFT"
            cfg().relativePoint = "BOTTOMRIGHT"
            apply()
            ns:InitMPlusRewardsPage()
        end)

        b:Finalize()
        positionSection:RecalcHeight()
    end

    local lookSection = CreateSection(sectionsHost, "Window Look", true, RelayoutSections)
    sections[#sections + 1] = lookSection

    do
        local b = W.Builder(lookSection.content)

        AddTwoColumnRow(b,
            function(lb)
                lb:Range("Panel Scale", 70, 200, 1,
                    function() return math.floor((cfg().scale or 1) * 100 + 0.5) end,
                    function(v)
                        cfg().scale = (tonumber(v) or 100) / 100
                        apply()
                    end)
            end,
            function(rb)
                rb:Range("Panel Opacity", 20, 100, 1,
                    function() return math.floor((cfg().alpha or 0.95) * 100 + 0.5) end,
                    function(v)
                        cfg().alpha = (tonumber(v) or 95) / 100
                        apply()
                    end)
            end)

        AddTwoColumnRow(b,
            function(lb)
                lb:Toggle("Hide Background",
                    function() return cfg().hideBackground end,
                    function(v)
                        cfg().hideBackground = v and true or false
                        apply()
                    end)
            end,
            function(rb)
                rb:Toggle("Hide Border",
                    function() return cfg().hideBorder end,
                    function(v)
                        cfg().hideBorder = v and true or false
                        apply()
                    end)
            end)

        AddThreeColumnRow(b,
            function(lb)
                lb:Color("Background Color",
                    function()
                        local color = cfg().backgroundColor or {}
                        return color.r or 0.08, color.g or 0.08, color.b or 0.08, color.a or 0.94
                    end,
                    function(r, g, bv, a)
                        cfg().backgroundColor = { r = r, g = g, b = bv, a = a }
                        apply()
                    end,
                    true)
            end,
            function(mb)
                mb:Color("Border Color",
                    function()
                        local color = cfg().borderColor or {}
                        return color.r or 0.31, color.g or 0.30, color.b or 0.30, color.a or 0.85
                    end,
                    function(r, g, bv, a)
                        cfg().borderColor = { r = r, g = g, b = bv, a = a }
                        apply()
                    end,
                    true)
            end,
            function(rb)
                AddCompactInput(rb,
                    "Border Size",
                    function() return tostring(cfg().borderSize or 1) end,
                    function(v)
                        cfg().borderSize = Clamp(math.floor((tonumber(v) or 1) + 0.5), 0, 8, 1)
                        apply()
                    end)
            end)

        AddTwoColumnRow(b,
            function(lb)
                lb:Cycle("Module Font",
                    function() return lsmItems("font", true) end,
                    function()
                        local media = Addon:GetModuleMediaConfig("MPlusRewards")
                        return media.font
                    end,
                    function(v)
                        local media = Addon:GetModuleMediaConfig("MPlusRewards")
                        media.useGlobal = false
                        media.font = (v == "") and nil or v
                        apply()
                    end,
                    0,
                    170)
            end,
            function(rb)
                rb:Input("Module Font Size",
                    function()
                        local media = Addon:GetModuleMediaConfig("MPlusRewards")
                        return tostring(tonumber(media.fontSize) or 12)
                    end,
                    function(v)
                        local media = Addon:GetModuleMediaConfig("MPlusRewards")
                        media.useGlobal = false
                        media.fontSize = Clamp(math.floor((tonumber(v) or 12) + 0.5), 8, 32, 12)
                        apply()
                    end)
            end)

        b:Button("Refresh Panel", function()
            apply()
        end)

        b:Finalize()
        lookSection:RecalcHeight()
    end

    RelayoutSections()
end
