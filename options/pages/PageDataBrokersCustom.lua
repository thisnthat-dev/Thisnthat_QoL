local ADDON_NAME, ns = ...

function ns:InitDataBrokersPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    local parent = ns.OptionsFrame.Content
    local W = ns.OptionsWidgets
    local Addon = ns.Addon

    local customModule = Addon:GetModule("databrokers")
    local barsModule = Addon:GetModule("databroker_bars")

    local function applyBars()
        if barsModule and type(barsModule.ApplySettings) == "function" then
            barsModule:ApplySettings()
        end
    end

    local function getDataBrokerDB()
        Addon.db.databrokers = Addon.db.databrokers or {}
        return Addon.db.databrokers
    end

    local function getClockConfig()
        local db = getDataBrokerDB()
        db.clockBroker = type(db.clockBroker) == "table" and db.clockBroker or {}
        local cfg = db.clockBroker
        cfg.useServerTime = cfg.useServerTime and true or false
        cfg.use24Hour = cfg.use24Hour and true or false
        return cfg
    end

    local function getDurabilityColors()
        local db = getDataBrokerDB()
        db.durabilityColors = type(db.durabilityColors) == "table" and db.durabilityColors or {}
        local cfg = db.durabilityColors
        cfg.ok = type(cfg.ok) == "table" and cfg.ok or { r = 0, g = 1, b = 0, a = 1 }
        cfg.warning = type(cfg.warning) == "table" and cfg.warning or { r = 1, g = 1, b = 0, a = 1 }
        cfg.critical = type(cfg.critical) == "table" and cfg.critical or { r = 1, g = 0, b = 0, a = 1 }
        return cfg
    end

    local function getSystemConfig()
        local db = getDataBrokerDB()
        db.systemBroker = type(db.systemBroker) == "table" and db.systemBroker or {}
        local cfg = db.systemBroker
        cfg.fpsColors = type(cfg.fpsColors) == "table" and cfg.fpsColors or {}
        cfg.latencyColors = type(cfg.latencyColors) == "table" and cfg.latencyColors or {}

        if type(cfg.fpsColors.ok) ~= "table" then
            cfg.fpsColors.ok = type(cfg.fpsColors.green) == "table" and cfg.fpsColors.green or { r = 0, g = 1, b = 0, a = 1 }
        end
        if type(cfg.fpsColors.warning) ~= "table" then
            cfg.fpsColors.warning = type(cfg.fpsColors.yellow) == "table" and cfg.fpsColors.yellow or { r = 1, g = 1, b = 0, a = 1 }
        end
        if type(cfg.fpsColors.critical) ~= "table" then
            cfg.fpsColors.critical = type(cfg.fpsColors.red) == "table" and cfg.fpsColors.red or { r = 1, g = 0, b = 0, a = 1 }
        end
        cfg.fpsColors.red = nil
        cfg.fpsColors.orange = nil
        cfg.fpsColors.yellow = nil
        cfg.fpsColors.green = nil

        if type(cfg.latencyColors.ok) ~= "table" then
            cfg.latencyColors.ok = type(cfg.latencyColors.green) == "table" and cfg.latencyColors.green or { r = 0, g = 1, b = 0, a = 1 }
        end
        if type(cfg.latencyColors.warning) ~= "table" then
            cfg.latencyColors.warning = type(cfg.latencyColors.yellow) == "table" and cfg.latencyColors.yellow or { r = 1, g = 1, b = 0, a = 1 }
        end
        if type(cfg.latencyColors.critical) ~= "table" then
            cfg.latencyColors.critical = type(cfg.latencyColors.red) == "table" and cfg.latencyColors.red or { r = 1, g = 0, b = 0, a = 1 }
        end
        cfg.latencyColors.red = nil
        cfg.latencyColors.orange = nil
        cfg.latencyColors.yellow = nil
        cfg.latencyColors.green = nil

        return cfg
    end

    local availableMap = {}
    if barsModule and type(barsModule.GetAvailableBrokerNames) == "function" then
        for _, name in ipairs(barsModule:GetAvailableBrokerNames() or {}) do
            availableMap[name] = true
        end
    end

    local customNames = {}
    if customModule and type(customModule.GetCustomBrokerNames) == "function" then
        customNames = customModule:GetCustomBrokerNames() or {}
    end

    local function trimLabel(name)
        local text = tostring(name or "")
        text = string.match(text, "^%s*(.-)%s*$") or text
        local prefix = ADDON_NAME .. " "
        if string.sub(text, 1, string.len(prefix)) == prefix then
            text = string.sub(text, string.len(prefix) + 1)
        end
        return text ~= "" and text or tostring(name or "Broker")
    end

    local function getCategoryItems()
        local items = {
            { value = "module", label = "Module" },
        }

        for _, brokerName in ipairs(customNames) do
            items[#items + 1] = {
                value = "broker:" .. brokerName,
                label = trimLabel(brokerName),
            }
        end

        return items
    end

    local function getSelectedCategory()
        local db = getDataBrokerDB()
        local selected = type(db.customCategoryView) == "string" and db.customCategoryView or "module"
        if selected == "module" then
            return selected
        end

        for _, brokerName in ipairs(customNames) do
            if selected == ("broker:" .. brokerName) then
                return selected
            end
        end

        db.customCategoryView = "module"
        return "module"
    end

    local function setSelectedCategory(value)
        local db = getDataBrokerDB()
        db.customCategoryView = value
        ns:InitDataBrokersPage()
    end

    local function getSelectedBrokerName(selected)
        if selected == "module" then
            return nil
        end
        return string.match(selected or "", "^broker:(.+)$")
    end

    local b = W.Builder(parent)

    b:Header("DataBrokers")
    b:Desc("Select a category to configure a specific DataBroker.")

    local selectedCategory = getSelectedCategory()
    b:Cycle("Category",
        getCategoryItems,
        function()
            return selectedCategory
        end,
        function(v)
            setSelectedCategory(v)
        end,
        0,
        220)

    local selectedBroker = getSelectedBrokerName(selectedCategory)

    if not selectedBroker then
        b:Header("Module Settings")

        b:Toggle("Enable DataBrokers Module",
            function() return Addon:IsModuleEnabled("databrokers") end,
            function(v)
                Addon.db.modules.databrokers.enabled = v and true or false
            end)

        b:Desc("Registered custom brokers:")

        if #customNames == 0 then
            b:Desc("|cffaaaaaaNo custom brokers are currently registered.|r")
        else
            for _, name in ipairs(customNames) do
                local stateText = availableMap[name] and "Loaded" or "Pending"
                local stateColor = availableMap[name] and "|cff6fdc6f" or "|cffffd36f"
                b:Desc(" - " .. name .. ": " .. stateColor .. stateText .. "|r")
            end
        end

        b:Desc("Changes to module enable state apply on next /reload.")
        b:Button("Reload UI", function()
            local reloadUI = rawget(_G, "ReloadUI")
            if type(reloadUI) == "function" then
                reloadUI()
            end
        end)
    else
        local brokerLabel = trimLabel(selectedBroker)
        local key = string.lower(brokerLabel)

        if string.find(key, "clock", 1, true) then
            b:Header("Clock Broker")
            b:Toggle("Use Server Time",
                function() return getClockConfig().useServerTime end,
                function(v)
                    getClockConfig().useServerTime = v and true or false
                    applyBars()
                end)
            b:Toggle("Use 24 Hour Format",
                function() return getClockConfig().use24Hour end,
                function(v)
                    getClockConfig().use24Hour = v and true or false
                    applyBars()
                end)
        elseif string.find(key, "durability", 1, true) then
            b:Header("Durability Broker")
            b:Color("OK Color",
                function()
                    local c = getDurabilityColors().ok
                    return c.r or 0, c.g or 1, c.b or 0, c.a or 1
                end,
                function(r, g, bv, a)
                    getDurabilityColors().ok = { r = r, g = g, b = bv, a = a }
                    applyBars()
                end,
                true,
                0)
            b:Color("Warning Color",
                function()
                    local c = getDurabilityColors().warning
                    return c.r or 1, c.g or 1, c.b or 0, c.a or 1
                end,
                function(r, g, bv, a)
                    getDurabilityColors().warning = { r = r, g = g, b = bv, a = a }
                    applyBars()
                end,
                true,
                0)
            b:Color("Critical Color",
                function()
                    local c = getDurabilityColors().critical
                    return c.r or 1, c.g or 0, c.b or 0, c.a or 1
                end,
                function(r, g, bv, a)
                    getDurabilityColors().critical = { r = r, g = g, b = bv, a = a }
                    applyBars()
                end,
                true,
                0)
        elseif string.find(key, "system", 1, true) then
            b:Header("System Broker")
            b:Desc("FPS thresholds: Critical < 20, Warning < 60, OK >= 60")
            b:Color("OK",
                function() local c = getSystemConfig().fpsColors.ok; return c.r or 0, c.g or 1, c.b or 0, c.a or 1 end,
                function(r, g, bv, a) getSystemConfig().fpsColors.ok = { r = r, g = g, b = bv, a = a }; applyBars() end,
                true,
                0)
            b:Color("Warning",
                function() local c = getSystemConfig().fpsColors.warning; return c.r or 1, c.g or 1, c.b or 0, c.a or 1 end,
                function(r, g, bv, a) getSystemConfig().fpsColors.warning = { r = r, g = g, b = bv, a = a }; applyBars() end,
                true,
                0)
            b:Color("Critical",
                function() local c = getSystemConfig().fpsColors.critical; return c.r or 1, c.g or 0, c.b or 0, c.a or 1 end,
                function(r, g, bv, a) getSystemConfig().fpsColors.critical = { r = r, g = g, b = bv, a = a }; applyBars() end,
                true,
                0)

            b:Desc("Latency thresholds: Critical > 300, Warning > 150, OK <= 150")
            b:Color("Latency OK",
                function() local c = getSystemConfig().latencyColors.ok; return c.r or 0, c.g or 1, c.b or 0, c.a or 1 end,
                function(r, g, bv, a) getSystemConfig().latencyColors.ok = { r = r, g = g, b = bv, a = a }; applyBars() end,
                true,
                0)
            b:Color("Latency Warning",
                function() local c = getSystemConfig().latencyColors.warning; return c.r or 1, c.g or 1, c.b or 0, c.a or 1 end,
                function(r, g, bv, a) getSystemConfig().latencyColors.warning = { r = r, g = g, b = bv, a = a }; applyBars() end,
                true,
                0)
            b:Color("Latency Critical",
                function() local c = getSystemConfig().latencyColors.critical; return c.r or 1, c.g or 0, c.b or 0, c.a or 1 end,
                function(r, g, bv, a) getSystemConfig().latencyColors.critical = { r = r, g = g, b = bv, a = a }; applyBars() end,
                true,
                0)
        else
            b:Header(brokerLabel)
            b:Desc("This broker has no custom settings yet.")
        end
    end

    b:Finalize()
end
