local ADDON_NAME, ns = ...
local C = ns.OptionsColors
local W = ns.OptionsWidgets

local function ApplyFont(target, offset)
    if W and W.ApplyFont then
        W.ApplyFont(target, offset)
    end
end

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

local function IsKickAssistAddonLoaded()
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        return C_AddOns.IsAddOnLoaded("Thisnthat_KickAssist") and true or false
    end

    local isAddOnLoaded = rawget(_G, "IsAddOnLoaded")
    if type(isAddOnLoaded) == "function" then
        return isAddOnLoaded("Thisnthat_KickAssist") and true or false
    end

    return false
end

local function IsResourceBarsAddonLoaded()
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        return C_AddOns.IsAddOnLoaded("EllesmereUIResourceBars") and true or false
    end

    local isAddOnLoaded = rawget(_G, "IsAddOnLoaded")
    if type(isAddOnLoaded) == "function" then
        return isAddOnLoaded("EllesmereUIResourceBars") and true or false
    end

    return false
end

local sidebar = CreateFrame("Frame", nil, ns.OptionsFrame, "BackdropTemplate")
sidebar:SetWidth(178)
sidebar:SetPoint("TOPLEFT",    ns.OptionsFrame, "TOPLEFT",    1, -1)
sidebar:SetPoint("BOTTOMLEFT", ns.OptionsFrame, "BOTTOMLEFT", 1,  1)
sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
sidebar:SetBackdropColor(C.BG.r, C.BG.g, C.BG.b, 1)

-- Right divider line
local divider = sidebar:CreateTexture(nil, "OVERLAY")
divider:SetWidth(1)
divider:SetPoint("TOPRIGHT",    sidebar, "TOPRIGHT",    0, -70)
divider:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0,   0)
divider:SetColorTexture(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.75)

-- Header
local header = CreateFrame("Frame", nil, sidebar, "BackdropTemplate")
header:SetSize(178, 68)
header:SetPoint("TOP", sidebar, "TOP", 0, 0)
header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
header:SetBackdropColor(C.BG.r, C.BG.g, C.BG.b, 0.95)

local hAccent = header:CreateTexture(nil, "OVERLAY")
hAccent:SetHeight(3)
hAccent:SetPoint("TOPLEFT",  header, "TOPLEFT",  0, 0)
hAccent:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, 0)
hAccent:SetColorTexture(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)

local titleText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", header, "TOP", 0, -20)
titleText:SetText(ADDON_NAME)
titleText:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
ApplyFont(titleText, 2)

local hSep = header:CreateTexture(nil, "OVERLAY")
hSep:SetHeight(1)
hSep:SetPoint("BOTTOMLEFT",  header, "BOTTOMLEFT",  0, 0)
hSep:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
hSep:SetColorTexture(C.BLUE2.r, C.BLUE2.g, C.BLUE2.b, 0.7)

-- Scrollable nav area
local navScroll = CreateFrame("ScrollFrame", nil, sidebar)
navScroll:SetPoint("TOPLEFT",     header,  "BOTTOMLEFT",    0, 0)
navScroll:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT",   0, 0)
navScroll:EnableMouseWheel(true)

local navContent = CreateFrame("Frame", nil, navScroll)
navContent:SetWidth(178)
navContent:SetHeight(1)
navScroll:SetScrollChild(navContent)

navScroll:SetScript("OnMouseWheel", function(self, delta)
    local max = math.max(0, navContent:GetHeight() - self:GetHeight())
    self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScroll() - delta * 34, max)))
end)

-- Active tab left-edge indicator (orange strip)
local indicator = navContent:CreateTexture(nil, "OVERLAY")
indicator:SetWidth(3)
indicator:SetColorTexture(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
indicator:Hide()

local selectedBtn = nil
local tabReg      = {}
local groupStates = {}
local allGroups   = {}

local function HasTabKey(tabKey)
    return tabReg[tabKey] ~= nil
end

local function RecalcLayout()
    local y = 0
    for _, g in ipairs(allGroups) do
        g.header:ClearAllPoints()
        g.header:SetPoint("TOP", navContent, "TOP", 0, y)
        y = y - 36
        if groupStates[g.name] then
            for _, child in ipairs(g.children) do
                child:ClearAllPoints()
                child:SetPoint("TOP", navContent, "TOP", 0, y)
                child:Show()
                y = y - 32
            end
        else
            for _, child in ipairs(g.children) do child:Hide() end
        end
    end
    navContent:SetHeight(math.abs(y) + 16)
    navScroll:UpdateScrollChildRect()
    if selectedBtn then
        indicator:SetShown(selectedBtn:IsShown())
    end
end

local function SwitchTab(btn, initFn)
    if not ns.OptionsFrame then return end
    ns.OptionsFrame:ResetContent()
    selectedBtn = btn
    ns.CurrentTabKey = btn and btn.tabKey or nil
    indicator:ClearAllPoints()
    indicator:SetPoint("TOPLEFT",    btn, "TOPLEFT",    0, 0)
    indicator:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    indicator:SetShown(btn:IsShown())
    if initFn then initFn() end
end

local function MakeGroupHeader(label, name)
    local btn = CreateFrame("Button", nil, navContent, "BackdropTemplate")
    btn:SetSize(176, 32)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.28)
    btn:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.7)

    local icon = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    icon:SetPoint("LEFT", btn, "LEFT", 8, 0)
    icon:SetText("+")
    icon:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    ApplyFont(icon, 1)
    btn.icon = icon

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    lbl:SetText(label)
    lbl:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    ApplyFont(lbl, 0)
    btn.lbl = lbl

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.32)
        self:SetBackdropBorderColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.95)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.28)
        self:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.7)
    end)
    btn:SetScript("OnClick", function(self)
        groupStates[name] = not groupStates[name]
        self.icon:SetText(groupStates[name] and "-" or "+")
        RecalcLayout()
    end)

    return btn
end

local function MakeChildBtn(label, onClickFn, tabKey)
    local btn = CreateFrame("Button", nil, navContent, "BackdropTemplate")
    btn:SetSize(168, 28)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.16)
    btn:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.35)

    local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("LEFT", btn, "LEFT", 14, 0)
    arrow:SetText("\194\187")
    arrow:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    ApplyFont(arrow, -1)
    btn.arrow = arrow

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", arrow, "RIGHT", 5, 0)
    lbl:SetText(label)
    lbl:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
    ApplyFont(lbl, -1)
    btn.lbl = lbl

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.30)
        self:SetBackdropBorderColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.95)
        self.lbl:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        self.arrow:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.16)
        self:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.35)
        self.lbl:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.9)
        self.arrow:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    end)
    btn:SetScript("OnClick", function(self)
        SwitchTab(self, onClickFn)
    end)

    btn.tabKey = tabKey
    return btn
end

local function CreateGroup(name, label, childDefs)
    local hdr      = MakeGroupHeader(label, name)
    local children = {}
    for _, def in ipairs(childDefs) do
        local child = MakeChildBtn(def.label, def.onClick, def.key)
        children[#children + 1] = child
        if def.key then
            tabReg[def.key] = { button = child, groupName = name, initFn = def.onClick }
        end
    end
    groupStates[name] = true -- start expanded
    hdr.icon:SetText("-")
    allGroups[#allGroups + 1] = { name = name, header = hdr, children = children }
end

local function AddChildToGroup(groupName, childDef)
    if not childDef or not childDef.key or HasTabKey(childDef.key) then
        return
    end

    for _, group in ipairs(allGroups) do
        if group.name == groupName then
            local child = MakeChildBtn(childDef.label, childDef.onClick, childDef.key)
            group.children[#group.children + 1] = child
            tabReg[childDef.key] = { button = child, groupName = groupName, initFn = childDef.onClick }
            RecalcLayout()
            return
        end
    end
end

-- Navigation tree
CreateGroup("general", "General", {
    { key = "addon_settings", label = "Addon Settings",
      onClick = function() if ns.InitGeneralPage     then ns:InitGeneralPage()     end end },
})

local moduleEntries = {
        { key = "DatabrokerPanels",  label = "DataBroker Panels",
            onClick = function() if ns.InitDataBrokerPanelsPage then ns:InitDataBrokerPanelsPage() end end },
        { key = "PerformanceSettings", label = "Performance",
            onClick = function() if ns.InitPerformancePage then ns:InitPerformancePage() end end },
        { key = "MPlusRewards", label = "M+ Rewards",
            onClick = function() if ns.InitMPlusRewardsPage then ns:InitMPlusRewardsPage() end end },
        { key = "ElvUI", label = "ElvUI",
            onClick = function() if ns.InitElvUIPage then ns:InitElvUIPage() end end },
}

if IsResourceBarsAddonLoaded() then
    table.insert(moduleEntries, 2, {
        key = "EllesmereUIAbsorb",
        label = "EllesmereUI Absorb",
        onClick = function() if ns.InitEllesmereUIAbsorbPage then ns:InitEllesmereUIAbsorbPage() end end,
    })
end

local addonEntries = {}

if IsKickAssistAddonLoaded() then
    table.insert(addonEntries, {
                key = "KickAssist",
                label = "Kick Assist",
                onClick = function() if ns.InitKickAssistPage then ns:InitKickAssistPage() end end,
        })
end

if IsDatabrokersAddonLoaded() then
    table.insert(addonEntries, {
                key = "DataBrokers",
                label = "DataBrokers",
                onClick = function() if ns.InitDataBrokersPage then ns:InitDataBrokersPage() end end,
        })
end

CreateGroup("modules", "Modules", moduleEntries)
CreateGroup("addons", "Addons", addonEntries)

-- Public: navigate to a specific tab key
function ns:OpenOptionsTab(tabKey)
    local info = tabReg[tabKey]
    if not info then
        if ns.InitGeneralPage then ns:InitGeneralPage() end
        return
    end
    for _, g in ipairs(allGroups) do
        local open = (g.name == info.groupName)
        groupStates[g.name] = open
        g.header.icon:SetText(open and "-" or "+")
    end
    RecalcLayout()
    SwitchTab(info.button, info.initFn)
end

_G.Thisnthat_OpenOptionsTab = function(tabKey)
    if type(ns.OpenOptionsTab) == "function" then
        ns:OpenOptionsTab(tabKey)
    end
end

_G.Thisnthat_ShowOptions = function(tabKey)
    if ns.OptionsFrame then
        ns.OptionsFrame:Show()
    end

    if type(ns.OpenOptionsTab) == "function" then
        ns:OpenOptionsTab(tabKey or "addon_settings")
    end
end

_G.Thisnthat_RefreshOptionsTab = function(tabKey)
    if not ns.OptionsFrame or not ns.OptionsFrame:IsShown() then
        return
    end

    if tabKey and ns.CurrentTabKey ~= tabKey then
        return
    end

    if type(ns.RefreshCurrentPage) == "function" then
        ns.RefreshCurrentPage()
    end
end

function ns:RefreshSidebarAccent()
    hAccent:SetColorTexture(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    indicator:SetColorTexture(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    titleText:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)

    for _, g in ipairs(allGroups) do
        if g.header and g.header.icon then
            g.header.icon:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        end
        if g.header and g.header.lbl then
            g.header.lbl:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
        end

        for _, child in ipairs(g.children or {}) do
            if child and child.arrow then
                child.arrow:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
            end
        end
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, event, loadedName)
    if event == "PLAYER_LOGIN" then
        RecalcLayout()
        return
    end

    if loadedName == "Thisnthat_KickAssist" and IsKickAssistAddonLoaded() then
        AddChildToGroup("addons", {
            key = "KickAssist",
            label = "Kick Assist",
            onClick = function() if ns.InitKickAssistPage then ns:InitKickAssistPage() end end,
        })
    elseif loadedName == "Thisnthat_Databrokers" and IsDatabrokersAddonLoaded() then
        AddChildToGroup("addons", {
            key = "DataBrokers",
            label = "DataBrokers",
            onClick = function() if ns.InitDataBrokersPage then ns:InitDataBrokersPage() end end,
        })
    end
end)
