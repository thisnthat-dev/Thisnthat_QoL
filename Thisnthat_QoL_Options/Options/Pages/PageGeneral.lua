local ADDON_NAME, ns = ...

function ns:InitGeneralPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    local parent = ns.OptionsFrame.Content
    local W      = ns.OptionsWidgets
    local Addon  = (type(ns.GetAddon) == "function" and ns.GetAddon()) or ns.Addon
    local LSM    = LibStub and LibStub("LibSharedMedia-3.0", true)

    local function cfg() return Addon:GetGlobalMediaConfig() end

    local function lsmItems(mediaType, withNone)
        local items = withNone and { { value = "", label = "None" } } or {}
        if LSM and type(LSM.List) == "function" then
            for _, name in ipairs(LSM:List(mediaType) or {}) do
                items[#items + 1] = { value = name, label = name }
            end
        end
        return items
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

    local function applyAll()
        local module = Addon:GetModule("databroker_bars")
        if module and type(module.ApplySettings) == "function" then
            module:ApplySettings()
        end

        if ns.OptionsFrame and ns.OptionsFrame.ApplyCurrentAccent then
            ns.OptionsFrame:ApplyCurrentAccent()
        end

        if ns.OptionsFrame and ns.OptionsFrame.ApplyCurrentFont then
            ns.OptionsFrame:ApplyCurrentFont()
        end

        if ns.RefreshCurrentPage then
            ns.RefreshCurrentPage()
        end
    end

    local b = W.Builder(parent)

    b:Header("Global Appearance")
    b:Desc("These settings provide shared global styling for the options UI.")

    AddTwoColumnRow(b,
        function(col)
            col:Cycle("Default Font",
                function() return lsmItems("font", true) end,
                function() return cfg().font end,
                function(v) cfg().font = (v == "") and nil or v; applyAll() end,
                0,
                180)
        end,
        function(_) end)

    AddTwoColumnRow(b,
        function(col)
            col:Input("Font Size",
                function()
                    return tostring(cfg().fontSize or 12)
                end,
                function(v)
                    local fontSize = tonumber(v) or cfg().fontSize or 12
                    fontSize = math.floor(fontSize + 0.5)
                    if fontSize < 6 then fontSize = 6 end
                    if fontSize > 64 then fontSize = 64 end
                    cfg().fontSize = fontSize
                    applyAll()
                end,
                0)
        end,
        function(_) end)

    AddTwoColumnRow(b,
        function(col)
            col:Toggle("Use Class Color for Accent",
                function()
                    return cfg().useClassAccentColor
                end,
                function(v)
                    cfg().useClassAccentColor = v and true or false
                    applyAll()
                end,
                0)
        end,
        function(_) end)

    AddTwoColumnRow(b,
        function(col)
            col:Color("Accent Color",
                function()
                    local accent = cfg().accentColor or {}
                    return accent.r or 0.78, accent.g or 0.23, accent.b or 0.30, accent.a or 1
                end,
                function(r, g, bv, a)
                    cfg().accentColor = { r = r, g = g, b = bv, a = a }
                    applyAll()
                end,
                true,
                0)
        end,
        function(_) end)

    b:Finalize()
    ns.RefreshCurrentPage = function()
        ns:InitGeneralPage()
    end
end
