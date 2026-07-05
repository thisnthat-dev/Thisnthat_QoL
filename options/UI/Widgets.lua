local ADDON_NAME, ns = ...
local C = ns.OptionsColors
local CONTROL_BG = 0.05

local W = {}
ns.OptionsWidgets = W

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local function Clamp(value, minValue, maxValue, fallback)
    local n = tonumber(value)
    if not n then return fallback end
    if n < minValue then return minValue end
    if n > maxValue then return maxValue end
    return n
end

local function ResolveOptionsFont()
    local fontPath = (rawget(_G, "STANDARD_TEXT_FONT")) or "Fonts\\FRIZQT__.TTF"
    local fontSize = 12

    local Addon = ns and ns.Addon
    if Addon and type(Addon.GetGlobalMediaConfig) == "function" then
        local cfg = Addon:GetGlobalMediaConfig()
        fontSize = Clamp(cfg and cfg.fontSize, 6, 64, 12)
        if cfg and cfg.font and LSM and type(LSM.Fetch) == "function" then
            fontPath = LSM:Fetch("font", cfg.font, true) or fontPath
        end
    end

    return fontPath, fontSize
end

function W.ApplyFont(target, sizeOffset, flags)
    if not target or type(target.SetFont) ~= "function" then
        return
    end

    local offset = tonumber(sizeOffset) or 0
    target._tntFontOffset = offset

    local currentFlags = ""
    if target.GetFont then
        local _, _, f = target:GetFont()
        currentFlags = f or ""
    end
    target._tntFontFlags = flags or currentFlags

    local fontPath, baseSize = ResolveOptionsFont()
    local size = Clamp(baseSize + offset, 6, 72, baseSize)
    target:SetFont(fontPath, size, target._tntFontFlags)
end

-- ────────────────────────────────────────────────────────────
-- Internal helpers
-- ────────────────────────────────────────────────────────────

local function RowBG(frame)
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.14)
    frame:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.4)
end

local function StyleActionButton(btn, w, h)
    btn:SetSize(w or 120, h or 22)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.34)
    btn:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.8)

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.36)
        self:SetBackdropBorderColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        if self.lbl then self.lbl:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1) end
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.34)
        self:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.8)
        if self.lbl then self.lbl:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.92) end
    end)

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("CENTER")
    lbl:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.92)
    W.ApplyFont(lbl, -1)
    btn.lbl = lbl
    return lbl
end

-- ────────────────────────────────────────────────────────────
-- Color picker (compatible with old and new WoW API)
-- ────────────────────────────────────────────────────────────

local function OpenColorPicker(r, g, b, a, hasAlpha, onSet, onCancel)
    if ColorPickerFrame.SetupColorPickerAndShow then
        local info = {
            r = r, g = g, b = b,
            hasOpacity  = hasAlpha,
            opacity     = hasAlpha and (1 - a) or nil,
            swatchFunc  = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = hasAlpha and (1 - ColorPickerFrame:GetColorAlpha()) or 1
                onSet(nr, ng, nb, na)
            end,
            opacityFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = 1 - ColorPickerFrame:GetColorAlpha()
                onSet(nr, ng, nb, na)
            end,
            cancelFunc  = function(restore)
                if restore then onCancel(restore.r, restore.g, restore.b, restore.a or 1) end
            end,
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    else
        ColorPickerFrame.func = function()
            local nr, ng, nb = ColorPickerFrame:GetColorRGB()
            local na = hasAlpha and (1 - OpacitySliderFrame:GetValue()) or 1
            onSet(nr, ng, nb, na)
        end
        ColorPickerFrame.opacityFunc    = ColorPickerFrame.func
        ColorPickerFrame.cancelFunc     = function(restore)
            if restore then onCancel(restore.r, restore.g, restore.b, restore.a or 1) end
        end
        ColorPickerFrame.hasOpacity     = hasAlpha
        ColorPickerFrame.opacity        = hasAlpha and (1 - a) or 0
        ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }
        ColorPickerFrame:SetColorRGB(r, g, b)
        ShowUIPanel(ColorPickerFrame)
    end
end

-- ────────────────────────────────────────────────────────────
-- Builder: chains widgets automatically anchored top-down
-- ────────────────────────────────────────────────────────────

function W.Builder(parent, opts)
    local startY = (opts and tonumber(opts.startY)) or 10
    local padX   = (opts and tonumber(opts.padX)) or 10
    local b      = { parent = parent, last = nil, totalH = startY }
    local PAD_X  = padX

    function b:_Attach(frame, h, gap)
        gap = gap or 4
        if self.last then
            frame:SetPoint("TOPLEFT",  self.last, "BOTTOMLEFT",  0, -gap)
            frame:SetPoint("TOPRIGHT", self.last, "BOTTOMRIGHT", 0, -gap)
        else
            frame:SetPoint("TOPLEFT",  parent, "TOPLEFT",  PAD_X, -self.totalH)
            frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PAD_X, 0)
        end
        self.last   = frame
        self.totalH = self.totalH + h + gap
        return frame
    end

    -- Section header (orange title + blue divider line)
    function b:Header(title, gap)
        local f = CreateFrame("Frame", nil, parent)
        f:SetHeight(28)

        local accent = f:CreateTexture(nil, "OVERLAY")
        accent:SetHeight(1)
        accent:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  0, 0)
        accent:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
        accent:SetColorTexture(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.45)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", f, "LEFT", 2, 0)
        lbl:SetText(title)
        lbl:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        lbl:SetJustifyH("LEFT")
        W.ApplyFont(lbl, 0)

        return self:_Attach(f, 28, gap or 10)
    end

    -- Toggle (checkbox + label)
    function b:Toggle(label, getVal, setVal, gap)
        local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        f:SetHeight(30)
        RowBG(f)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT",  f, "LEFT",  10, 0)
        lbl:SetPoint("RIGHT", f, "RIGHT", -36, 0)
        lbl:SetText(label)
        lbl:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        lbl:SetJustifyH("LEFT")
        W.ApplyFont(lbl, -1)

        local check = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
        check:SetSize(20, 20)
        check:SetPoint("RIGHT", f, "RIGHT", -8, 0)
        local checkBG = check:CreateTexture(nil, "BACKGROUND")
        checkBG:SetPoint("TOPLEFT", check, "TOPLEFT", 4, -4)
        checkBG:SetPoint("BOTTOMRIGHT", check, "BOTTOMRIGHT", -4, 4)
        checkBG:SetColorTexture(CONTROL_BG, CONTROL_BG, CONTROL_BG, 0.95)
        check:SetChecked(getVal and getVal() or false)
        check:SetScript("OnClick", function(self)
            if setVal then setVal(self:GetChecked()) end
        end)
        f:SetScript("OnShow", function() check:SetChecked(getVal and getVal() or false) end)

        f.check = check
        return self:_Attach(f, 30, gap)
    end

    -- Execute button (full-width row with a right-aligned button)
    function b:Button(label, fn, gap)
        local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        f:SetHeight(30)
        RowBG(f)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", f, "LEFT", 10, 0)
        lbl:SetTextColor(C.GRAY.r, C.GRAY.g, C.GRAY.b, 0.85)
        lbl:SetJustifyH("LEFT")
        W.ApplyFont(lbl, -1)

        local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
        StyleActionButton(btn, 180, 22)
        btn.lbl:SetText(label)
        btn:SetPoint("CENTER", f, "CENTER", 0, 0)
        btn:SetScript("OnClick", function() if fn then fn() end end)

        return self:_Attach(f, 30, gap)
    end

    -- Labeled range slider
    function b:Range(label, minV, maxV, step, getVal, setVal, gap)
        local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        f:SetHeight(44)
        RowBG(f)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)
        lbl:SetText(label)
        lbl:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        W.ApplyFont(lbl, -1)

        local valText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        valText:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -8)
        valText:SetWidth(40)
        valText:SetJustifyH("RIGHT")
        valText:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        W.ApplyFont(valText, -1)

        local sl = CreateFrame("Slider", nil, f)
        sl:SetSize(0, 14)
        sl:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  10, 8)
        sl:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 8)
        sl:SetOrientation("HORIZONTAL")
        sl:SetMinMaxValues(minV, maxV)
        sl:SetValueStep(step or 1)
        sl:SetObeyStepOnDrag(true)

        local track = sl:CreateTexture(nil, "BACKGROUND")
        track:SetAllPoints()
        track:SetColorTexture(CONTROL_BG, CONTROL_BG, CONTROL_BG, 0.95)

        local thumb = sl:CreateTexture(nil, "OVERLAY")
        thumb:SetSize(10, 18)
        thumb:SetColorTexture(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.85)
        sl:SetThumbTexture(thumb)

        sl:SetValue(tonumber(getVal and getVal()) or minV)
        valText:SetText(tostring(tonumber(getVal and getVal()) or minV))

        sl:SetScript("OnValueChanged", function(self, val)
            val = math.floor(val / (step or 1) + 0.5) * (step or 1)
            valText:SetText(tostring(val))
            if setVal then setVal(val) end
        end)
        f:SetScript("OnShow", function()
            sl:SetValue(tonumber(getVal and getVal()) or minV)
        end)

        return self:_Attach(f, 44, gap)
    end

    -- Styled dropdown select
    function b:Cycle(label, getItemsFn, getVal, setVal, gap, dropdownWidth, forceSearch)
        local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        f:SetHeight(30)
        RowBG(f)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", f, "LEFT", 10, 0)
        lbl:SetPoint("RIGHT", f, "CENTER", -60, 0)
        lbl:SetText(label)
        lbl:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(false)
        W.ApplyFont(lbl, -1)

        local dropdownBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
        dropdownBtn:SetSize(dropdownWidth or 260, 22)
        dropdownBtn:SetPoint("RIGHT", f, "RIGHT", -8, 0)
        dropdownBtn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        dropdownBtn:SetBackdropColor(CONTROL_BG, CONTROL_BG, CONTROL_BG, 0.95)
        dropdownBtn:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.55)

        local valText = dropdownBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        valText:SetPoint("LEFT",  dropdownBtn, "LEFT",  8, 0)
        valText:SetPoint("RIGHT", dropdownBtn, "RIGHT", -20, 0)
        valText:SetJustifyH("LEFT")
        valText:SetWordWrap(false)
        valText:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.95)
        W.ApplyFont(valText, -1)

        local arrow = dropdownBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        arrow:SetPoint("RIGHT", dropdownBtn, "RIGHT", -7, 0)
        arrow:SetText("v")
        arrow:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.75)
        W.ApplyFont(arrow, -1)

        local function getItems()
            return type(getItemsFn) == "function" and getItemsFn() or {}
        end
        local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        menu:SetFrameStrata("DIALOG")
        menu:SetFrameLevel(400)
        menu:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        menu:SetBackdropColor(CONTROL_BG, CONTROL_BG, CONTROL_BG, 0.97)
        menu:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.7)
        menu:EnableMouse(true)
        menu:EnableMouseWheel(true)
        menu:Hide()

        local ROW_H = 20
        local MAX_VISIBLE = 10
        local SEARCH_THRESHOLD = 12
        local startIndex = 1
        local activeItems = {}
        local filteredItems = {}
        local searchQuery = ""
        local searchBox
        local buttons = {}
        local Refresh

        local function CreateOptionRow(index)
            local btn = CreateFrame("Button", nil, menu, "BackdropTemplate")
            btn:SetHeight(ROW_H)
            btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -1)
            btn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -1, -1)
            btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            btn:SetBackdropColor(0.04, 0.04, 0.04, 0)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.text:SetPoint("LEFT",  btn, "LEFT",  7, 0)
            btn.text:SetPoint("RIGHT", btn, "RIGHT", -7, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetWordWrap(false)
            btn.text:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
            W.ApplyFont(btn.text, -1)

            btn:SetScript("OnEnter", function(self)
                self:SetBackdropColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.22)
                self.text:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
            end)
            btn:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0.04, 0.04, 0.04, 0)
                self.text:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
            end)

            return btn
        end

        for i = 1, MAX_VISIBLE do
            buttons[i] = CreateOptionRow(i)
        end

        searchBox = CreateFrame("EditBox", nil, menu, "BackdropTemplate")
        searchBox:SetHeight(20)
        searchBox:SetPoint("TOPLEFT",  menu, "TOPLEFT",  2, -2)
        searchBox:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -2, -2)
        searchBox:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        searchBox:SetBackdropColor(CONTROL_BG, CONTROL_BG, CONTROL_BG, 0.95)
        searchBox:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.55)
        W.ApplyFont(searchBox, -1)
        searchBox:SetTextColor(1, 1, 1, 0.9)
        searchBox:SetTextInsets(6, 6, 0, 0)
        searchBox:SetAutoFocus(false)
        searchBox:Hide()

        local searchPlaceholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        searchPlaceholder:SetPoint("LEFT",  searchBox, "LEFT",  7, 0)
        searchPlaceholder:SetPoint("RIGHT", searchBox, "RIGHT", -7, 0)
        searchPlaceholder:SetJustifyH("LEFT")
        searchPlaceholder:SetText("Search")
        W.ApplyFont(searchPlaceholder, -1)

        local function BuildFilteredItems()
            wipe(filteredItems)
            if searchQuery == "" then
                for i = 1, #activeItems do
                    filteredItems[#filteredItems + 1] = activeItems[i]
                end
                return
            end

            local q = string.lower(searchQuery)
            for i = 1, #activeItems do
                local item = activeItems[i]
                local label = tostring(item.label or item.value or "")
                if string.find(string.lower(label), q, 1, true) then
                    filteredItems[#filteredItems + 1] = item
                end
            end
        end

        local function RenderMenu()
            local showSearch = forceSearch and true or (#activeItems >= SEARCH_THRESHOLD)
            local topPad = showSearch and 24 or 0
            local visible = math.min(MAX_VISIBLE, #filteredItems)
            menu:SetWidth(dropdownBtn:GetWidth())
            menu:SetHeight((visible * ROW_H) + 2 + topPad)

            searchBox:SetShown(showSearch)
            searchPlaceholder:SetShown(showSearch and searchBox:GetText() == "")

            for i = 1, MAX_VISIBLE do
                local btn = buttons[i]
                local item = filteredItems[startIndex + i - 1]
                if item and i <= visible then
                    btn:SetShown(true)
                    btn:ClearAllPoints()
                    btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -1 - topPad - ((i - 1) * ROW_H))
                    btn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -1, -1 - topPad - ((i - 1) * ROW_H))
                    btn.text:SetText(item.label or tostring(item.value))
                    btn:SetScript("OnClick", function()
                        if setVal then setVal(item.value) end
                        menu:Hide()
                        if Refresh then
                            Refresh()
                        end
                    end)
                else
                    btn:Hide()
                end
            end
        end

        menu:SetScript("OnMouseWheel", function(_, delta)
            if #filteredItems <= MAX_VISIBLE then return end
            startIndex = startIndex - delta
            if startIndex < 1 then startIndex = 1 end
            local maxStart = #filteredItems - MAX_VISIBLE + 1
            if startIndex > maxStart then startIndex = maxStart end
            RenderMenu()
        end)

        searchBox:SetScript("OnTextChanged", function(self)
            searchQuery = self:GetText() or ""
            searchPlaceholder:SetShown(searchQuery == "")
            startIndex = 1
            BuildFilteredItems()
            RenderMenu()
        end)

        searchBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            self:SetText("")
        end)

        searchBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
        end)

        dropdownBtn:SetScript("OnClick", function()
            activeItems = getItems()
            if #activeItems == 0 then return end
            if menu:IsShown() then
                menu:Hide()
                return
            end
            startIndex = 1
            searchQuery = ""
            searchBox:SetText("")
            BuildFilteredItems()
            menu:ClearAllPoints()
            menu:SetPoint("TOPLEFT", dropdownBtn, "BOTTOMLEFT", 0, -2)
            RenderMenu()
            menu:Show()
        end)

        Refresh = function()
            local items = getItems()
            local cur   = getVal and getVal()
            local found = false
            for _, it in ipairs(items) do
                if it.value == cur then
                    valText:SetText(it.label or tostring(it.value))
                    found = true; break
                end
            end
            if not found then valText:SetText(cur and tostring(cur) or "None") end
        end

        f:SetScript("OnShow", Refresh)
        Refresh()
        f.Refresh = Refresh

        return self:_Attach(f, 30, gap)
    end

    -- Color swatch button
    function b:Color(label, getVal, setVal, hasAlpha, gap)
        local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        f:SetHeight(30)
        RowBG(f)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", f, "LEFT", 10, 0)
        lbl:SetText(label)
        lbl:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        W.ApplyFont(lbl, -1)

        local swatch = CreateFrame("Button", nil, f, "BackdropTemplate")
        swatch:SetSize(34, 22)
        swatch:SetPoint("RIGHT", f, "RIGHT", -8, 0)
        swatch:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        swatch:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

        local colorTex = swatch:CreateTexture(nil, "ARTWORK")
        colorTex:SetPoint("TOPLEFT",     swatch, "TOPLEFT",     2, -2)
        colorTex:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", -2,  2)

        local function Refresh()
            local r, g, bv, a = 1, 1, 1, 1
            if getVal then r, g, bv, a = getVal() end
            colorTex:SetColorTexture(r, g, bv, 1)
        end
        Refresh()
        f:SetScript("OnShow", Refresh)

        swatch:SetScript("OnClick", function()
            local r, g, bv, a = 1, 1, 1, 1
            if getVal then r, g, bv, a = getVal() end
            local originalR, originalG, originalB, originalA = r, g, bv, a or 1
            OpenColorPicker(r, g, bv, a or 1, hasAlpha ~= false,
                function(nr, ng, nb, na)
                    if setVal then setVal(nr, ng, nb, na) end
                    colorTex:SetColorTexture(nr, ng, nb, 1)
                end,
                function()
                    if setVal then setVal(originalR, originalG, originalB, originalA) end
                    colorTex:SetColorTexture(originalR, originalG, originalB, 1)
                end
            )
        end)

        return self:_Attach(f, 30, gap)
    end

    -- Labeled text input
    function b:Input(label, getVal, setVal, gap)
        local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        f:SetHeight(34)
        RowBG(f)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", f, "LEFT", 10, 0)
        lbl:SetWidth(200)
        lbl:SetText(label)
        lbl:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        lbl:SetJustifyH("LEFT")
        W.ApplyFont(lbl, -1)

        local edit = CreateFrame("EditBox", nil, f, "BackdropTemplate")
        edit:SetHeight(22)
        edit:SetPoint("LEFT",  lbl,  "RIGHT",     8,  0)
        edit:SetPoint("RIGHT", f,    "RIGHT",    -10,  0)
        edit:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        edit:SetBackdropColor(CONTROL_BG, CONTROL_BG, CONTROL_BG, 0.95)
        edit:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.55)
        W.ApplyFont(edit, -1)
        edit:SetTextColor(1, 1, 1, 0.9)
        edit:SetTextInsets(6, 6, 0, 0)
        edit:SetAutoFocus(false)
        edit:SetMaxLetters(64)

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

        f.edit = edit
        return self:_Attach(f, 34, gap)
    end

    -- Description / info text
    function b:Desc(text, gap)
        local f = CreateFrame("Frame", nil, parent)
        f:SetHeight(18)

        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        lbl:SetPoint("TOPLEFT",  f, "TOPLEFT",  2, 0)
        lbl:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, 0)
        lbl:SetText(text)
        lbl:SetTextColor(C.GRAY.r, C.GRAY.g, C.GRAY.b, 0.85)
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(true)
        W.ApplyFont(lbl, -1)
        -- Expand frame height to text height after layout
        C_Timer.After(0, function()
            local h = lbl:GetStringHeight()
            f:SetHeight(math.max(18, h + 4))
        end)

        return self:_Attach(f, 18, gap or 4)
    end

    -- Thin spacer
    function b:Spacer(h, gap)
        local f = CreateFrame("Frame", nil, parent)
        h = h or 6
        f:SetHeight(h)
        return self:_Attach(f, h, gap or 0)
    end

    -- Commit final content height
    function b:Finalize()
        parent:SetHeight(self.totalH + 20)
        return self.totalH + 20
    end

    return b
end

-- Convenience: a standalone themed button (not in a row)
function W.ActionButton(parent, label, w, h)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    StyleActionButton(btn, w, h)
    btn.lbl:SetText(label or "")
    return btn
end
