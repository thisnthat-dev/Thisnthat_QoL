local ADDON_NAME, ns = ...

local function IsDatabrokersAddonLoaded()
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        return C_AddOns.IsAddOnLoaded("Thisnthat_Databrokers") and true or false
    end

    local isAddOnLoaded = rawget(_G, "IsAddOnLoaded")
    if type(isAddOnLoaded) == "function" then
        return isAddOnLoaded("Thisnthat_Databrokers") and true or false
    end

    return false
end

local function GetCustomBrokerNames()
    local getter = rawget(_G, "Thisnthat_Databrokers_GetCustomBrokerNames")
    if type(getter) == "function" then
        local ok, names = pcall(getter)
        if ok and type(names) == "table" then
            table.sort(names)
            return names
        end
    end

    return {}
end

local function EnsureSelectionDB(Addon)
    Addon.db.databrokers = Addon.db.databrokers or {}
    local db = Addon.db.databrokers
    db.options = type(db.options) == "table" and db.options or {}
    db.options.selectedCustomBroker = type(db.options.selectedCustomBroker) == "string" and db.options.selectedCustomBroker or nil
    return db
end

function ns:InitDataBrokersPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    local parent = ns.OptionsFrame.Content
    local W = ns.OptionsWidgets
    local C = ns.OptionsColors
    local Addon = (type(ns.GetAddon) == "function" and ns.GetAddon()) or ns.Addon
    local panelsModule = Addon and Addon.GetModule and Addon:GetModule("DatabrokerPanels") or nil

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
    title:SetText("DataBrokers")
    title:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    ApplyFont(title, 2)

    local subtitle = root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetPoint("TOPRIGHT", root, "TOPRIGHT", -2, 0)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWordWrap(true)
    subtitle:SetText("Configure display settings for custom DataBrokers from Thisnthat_Databrokers.")
    ApplyFont(subtitle, -1)

    local body = CreateFrame("Frame", nil, root)
    body:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -10)
    body:SetPoint("TOPRIGHT", subtitle, "BOTTOMRIGHT", 0, -10)
    body:SetHeight(1)

    local b = W.Builder(body, { startY = 0, padX = 0 })

    if not IsDatabrokersAddonLoaded() then
        b:Desc("|cffff7777Thisnthat_Databrokers is not loaded.|r")
        local h = b:Finalize()
        body:SetHeight(h)
        root:SetHeight(84 + h)
        parent:SetHeight(110 + h)
        return
    end

    if not Addon or not panelsModule then
        b:Desc("|cffff7777Databroker Panels module is unavailable.|r")
        local h = b:Finalize()
        body:SetHeight(h)
        root:SetHeight(84 + h)
        parent:SetHeight(110 + h)
        return
    end

    local db = EnsureSelectionDB(Addon)
    local names = GetCustomBrokerNames()

    if #names == 0 then
        b:Desc("|cffff7777No custom DataBrokers were found from Thisnthat_Databrokers.|r")
        local h = b:Finalize()
        body:SetHeight(h)
        root:SetHeight(84 + h)
        parent:SetHeight(110 + h)
        return
    end

    local selected = db.options.selectedCustomBroker
    local valid = false
    for _, name in ipairs(names) do
        if name == selected then
            valid = true
            break
        end
    end
    if not valid then
        selected = names[1]
        db.options.selectedCustomBroker = selected
    end

    local items = {}
    for _, name in ipairs(names) do
        items[#items + 1] = { value = name, label = name }
    end

    b:Cycle("DataBroker",
        function() return items end,
        function() return db.options.selectedCustomBroker end,
        function(v)
            db.options.selectedCustomBroker = tostring(v or "")
            ns:InitDataBrokersPage()
        end,
        0,
        360,
        true)

    local brokerName = db.options.selectedCustomBroker
    local brokerCfg = panelsModule:GetBrokerDisplayConfig(brokerName)

    b:Header("Display")

    b:Toggle("Show Icon",
        function() return brokerCfg.showIcon ~= false end,
        function(v)
            brokerCfg.showIcon = v and true or false
            if type(panelsModule.ApplySettings) == "function" then
                panelsModule:ApplySettings()
            end
        end)

    b:Toggle("Show Label",
        function() return brokerCfg.showLabel ~= false end,
        function(v)
            brokerCfg.showLabel = v and true or false
            if type(panelsModule.ApplySettings) == "function" then
                panelsModule:ApplySettings()
            end
        end)

    b:Toggle("Show Text",
        function() return brokerCfg.showText ~= false end,
        function(v)
            brokerCfg.showText = v and true or false
            if type(panelsModule.ApplySettings) == "function" then
                panelsModule:ApplySettings()
            end
        end)

    local h = b:Finalize()
    body:SetHeight(h)
    root:SetHeight(84 + h)
    parent:SetHeight(110 + h)
end
