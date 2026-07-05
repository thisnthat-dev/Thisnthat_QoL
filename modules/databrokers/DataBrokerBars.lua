local ADDON_NAME, ns = ...

local Addon = ns.Addon
local Module = {
    bars = {},
    buttons = {},
}

Addon:RegisterModule("databroker_bars", Module)

local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local VALID_POINTS = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true,
}

local function Clamp(value, minValue, maxValue, fallback)
    local numberValue = tonumber(value)
    if not numberValue then
        return fallback
    end

    if numberValue < minValue then
        return minValue
    end

    if numberValue > maxValue then
        return maxValue
    end

    return numberValue
end

local function NormalizeColor(colorValue, defaultR, defaultG, defaultB, defaultA)
    local color = type(colorValue) == "table" and colorValue or {}

    local r = Clamp(color.r, 0, 1, defaultR)
    local g = Clamp(color.g, 0, 1, defaultG)
    local b = Clamp(color.b, 0, 1, defaultB)
    local a = Clamp(color.a, 0, 1, defaultA)

    return {
        r = r,
        g = g,
        b = b,
        a = a,
    }
end

local function NormalizePoint(value, fallback)
    if type(value) ~= "string" then
        return fallback
    end

    local upper = string.upper(value)
    if VALID_POINTS[upper] then
        return upper
    end

    return fallback
end

local function GetModuleMedia()
    local mediaCfg = (Addon.GetModuleMediaConfig and Addon:GetModuleMediaConfig("databrokers")) or {}
    return {
        font = mediaCfg.font,
        fontSize = Clamp(mediaCfg.fontSize, 6, 64, 12),
        statusbar = mediaCfg.statusbar,
        border = mediaCfg.border,
        background = mediaCfg.background,
        textureColor = NormalizeColor(mediaCfg.textureColor, 0.09, 0.11, 0.14, 0.95),
        borderColor = NormalizeColor(mediaCfg.borderColor, 0.18, 0.24, 0.30, 1),
        borderSize = Clamp(mediaCfg.borderSize, 0, 8, 1),
    }
end

local function GetDataBrokerDB()
    Addon.db.databrokers = Addon.db.databrokers or {}
    local db = Addon.db.databrokers

    db.unlocked = db.unlocked and true or false
    db.whitelistEnabled = false
    db.whitelist = {}
    db.bars = type(db.bars) == "table" and db.bars or {}
    db.brokerDisplay = type(db.brokerDisplay) == "table" and db.brokerDisplay or {}
    db.showBackdrop = db.showBackdrop ~= false
    db.showBorder = db.showBorder ~= false

    return db
end

local function EnsureBrokerDisplayConfig(name)
    local db = GetDataBrokerDB()
    if type(name) ~= "string" or name == "" then
        return {
            showLabel = true,
            showText = true,
            showIcon = true,
        }
    end

    db.brokerDisplay[name] = type(db.brokerDisplay[name]) == "table" and db.brokerDisplay[name] or {}
    local cfg = db.brokerDisplay[name]
    cfg.showLabel = cfg.showLabel ~= false
    cfg.showText = cfg.showText ~= false
    cfg.showIcon = cfg.showIcon ~= false
    return cfg
end

local function EnsureBarConfig(index)
    local db = GetDataBrokerDB()
    db.bars[index] = type(db.bars[index]) == "table" and db.bars[index] or {}

    local cfg = db.bars[index]
    local defaultY = -120 - ((index - 1) * 30)

    cfg.name = type(cfg.name) == "string" and cfg.name or ("Bar " .. tostring(index))
    cfg.width = Clamp(cfg.width, 120, 2400, 560)
    cfg.height = Clamp(cfg.height, 12, 128, 24)
    cfg.maxBrokers = Clamp(cfg.maxBrokers, 1, 40, 8)
    cfg.point = NormalizePoint(cfg.point, "TOP")
    cfg.relativePoint = NormalizePoint(cfg.relativePoint, cfg.point)
    cfg.x = Clamp(cfg.x, -4000, 4000, 0)
    cfg.y = Clamp(cfg.y, -4000, 4000, defaultY)
    cfg.overrideColors = cfg.overrideColors and true or false
    if cfg.backgroundColor ~= nil then
        cfg.backgroundColor = NormalizeColor(cfg.backgroundColor, 0, 0, 0, 0.35)
        if cfg.backgroundColor.r == 0 and cfg.backgroundColor.g == 0 and cfg.backgroundColor.b == 0 and cfg.backgroundColor.a == 0.35 then
            cfg.backgroundColor = nil
        end
    end
    if cfg.borderColor ~= nil then
        cfg.borderColor = NormalizeColor(cfg.borderColor, 0.2, 0.2, 0.2, 0.9)
        if cfg.borderColor.r == 0.2 and cfg.borderColor.g == 0.2 and cfg.borderColor.b == 0.2 and cfg.borderColor.a == 0.9 then
            cfg.borderColor = nil
        end
    end
    cfg.brokers = type(cfg.brokers) == "table" and cfg.brokers or {}

    return cfg
end

local function BuildBrokerMap()
    local byName = {}
    local names = {}

    if not LDB or type(LDB.DataObjectIterator) ~= "function" then
        return byName, names
    end

    for name, dataObject in LDB:DataObjectIterator() do
        byName[name] = dataObject
        names[#names + 1] = name
    end

    table.sort(names)

    return byName, names
end

local function CreateBarFrame(index)
    local bar = CreateFrame("Frame", ADDON_NAME .. "DataBrokerBar" .. index, UIParent, "BackdropTemplate")
    bar:SetFrameStrata("LOW")
    bar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    bar:SetBackdropColor(0, 0, 0, 0.35)
    bar:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.9)
    bar:RegisterForDrag("LeftButton")
    bar:SetClampedToScreen(true)

    bar:SetScript("OnDragStart", function(self)
        local db = GetDataBrokerDB()
        if not db.unlocked then
            return
        end

        self:StartMoving()
    end)

    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local db = GetDataBrokerDB()
        db.bars[index] = db.bars[index] or {}
        local cfg = db.bars[index]

        local point, _, relativePoint, x, y = self:GetPoint(1)
        cfg.point = NormalizePoint(point, cfg.point or "TOP")
        cfg.relativePoint = NormalizePoint(relativePoint, cfg.relativePoint or cfg.point)
        cfg.x = Clamp(x, -4000, 4000, cfg.x or 0)
        cfg.y = Clamp(y, -4000, 4000, cfg.y or 0)

        if type(Module.onBarMoved) == "function" then
            local ok = pcall(Module.onBarMoved, index, cfg)
            if not ok then
                Module.onBarMoved = nil
            end
        end
    end)

    return bar
end

local function CreateButton(bar, barIndex, buttonIndex)
    local button = CreateFrame("Button", nil, bar, "BackdropTemplate")
    button:RegisterForClicks("AnyUp")
    button:SetFrameStrata("LOW")
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    button:SetBackdropColor(0, 0, 0, 0)
    button:SetBackdropBorderColor(0, 0, 0, 0)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("LEFT", 4, 0)
    button.icon:SetSize(14, 14)
    button.icon:Hide()

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.text:SetPoint("LEFT", 6, 0)
    button.text:SetPoint("RIGHT", -4, 0)
    button.text:SetJustifyH("CENTER")
    button.text:SetWordWrap(false)
    button.text:SetMaxLines(1)

    button:SetScript("OnEnter", function(self)
        local dataObject = self.dataObject
        if not dataObject then
            return
        end

        if type(dataObject.OnTooltipShow) == "function" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            dataObject.OnTooltipShow(GameTooltip)
            GameTooltip:Show()
        elseif type(dataObject.OnEnter) == "function" then
            dataObject.OnEnter(self)
        end
    end)

    button:SetScript("OnLeave", function(self)
        local dataObject = self.dataObject
        if type(dataObject.OnLeave) == "function" then
            dataObject.OnLeave(self)
        else
            GameTooltip:Hide()
        end
    end)

    button:SetScript("OnClick", function(self, mouseButton)
        local dataObject = self.dataObject
        if type(dataObject and dataObject.OnClick) == "function" then
            dataObject.OnClick(self, mouseButton)
        end
    end)

    Module.buttons[barIndex] = Module.buttons[barIndex] or {}
    Module.buttons[barIndex][buttonIndex] = button

    return button
end

function Module:HideAllBars()
    for _, bar in ipairs(self.bars) do
        bar:Hide()
    end
end

function Module:GetAvailableBrokerNames()
    local _, names = BuildBrokerMap()
    return names
end

function Module:SetBarMovedCallback(callback)
    if type(callback) == "function" then
        self.onBarMoved = callback
    else
        self.onBarMoved = nil
    end
end

function Module:GetBrokerDisplayConfig(name)
    return EnsureBrokerDisplayConfig(name)
end

function Module:CreateBar()
    local db = GetDataBrokerDB()
    local index = #db.bars + 1
    db.bars[index] = {
        name = "Bar " .. tostring(index),
        width = 560,
        height = 24,
        maxBrokers = 8,
        point = "TOP",
        relativePoint = "TOP",
        x = 0,
        y = -120 - ((index - 1) * 30),
        brokers = {},
    }

    self:RefreshBars()
    return index
end

function Module:CreateNamedBar(name, maxBrokers)
    local db = GetDataBrokerDB()
    local index = #db.bars + 1
    local cleanName = type(name) == "string" and string.match(name, "^%s*(.-)%s*$") or ""
    if cleanName == "" then
        cleanName = "Bar " .. tostring(index)
    end

    db.bars[index] = {
        name = cleanName,
        width = 560,
        height = 24,
        maxBrokers = Clamp(maxBrokers, 1, 40, 8),
        point = "TOP",
        relativePoint = "TOP",
        x = 0,
        y = -120 - ((index - 1) * 30),
        brokers = {},
    }

    self:RefreshBars()
    return index
end

function Module:DeleteBar(index)
    local db = GetDataBrokerDB()
    if type(index) ~= "number" then
        return
    end

    if index < 1 or index > #db.bars then
        return
    end

    table.remove(db.bars, index)
    self:RefreshBars()
end

function Module:UpdateButtonVisual(button, cfg)
    local dataObject = button.dataObject
    if not dataObject then
        button.text:SetText("")
        button.icon:Hide()
        button:SetAlpha(0.55)
        button:EnableMouse(false)
        button:Show()
        return
    end

    local brokerCfg = EnsureBrokerDisplayConfig(button.brokerName)
    local showLabel = brokerCfg.showLabel
    local showText = brokerCfg.showText
    local showIcon = brokerCfg.showIcon

    local labelText = showLabel and tostring(dataObject.label or button.brokerName or "") or ""
    local valueText = showText and tostring(dataObject.text or "") or ""

    local displayText
    if labelText ~= "" and valueText ~= "" then
        displayText = labelText .. ": " .. valueText
    elseif labelText ~= "" then
        displayText = labelText
    else
        displayText = valueText
    end

    button.text:SetText(displayText)
    button:SetAlpha(1)
    button:EnableMouse(true)

    if showIcon and dataObject.icon then
        button.icon:SetTexture(dataObject.icon)
        button.icon:Show()
        button.icon:ClearAllPoints()

        if displayText ~= "" then
            local iconSize = 14
            local gap = 4
            local maxTextWidth = math.max(0, button:GetWidth() - (iconSize + gap + 8))
            local textWidth = math.min(button.text:GetStringWidth() or 0, maxTextWidth)
            local groupWidth = iconSize + gap + textWidth

            button.icon:SetPoint("LEFT", button, "CENTER", -math.floor(groupWidth / 2), 0)

            button.text:ClearAllPoints()
            button.text:SetPoint("LEFT", button.icon, "RIGHT", gap, 0)
            button.text:SetWidth(textWidth)
            button.text:SetJustifyH("LEFT")
        else
            button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
            button.text:ClearAllPoints()
            button.text:SetPoint("LEFT", 6, 0)
            button.text:SetPoint("RIGHT", -4, 0)
            button.text:SetWidth(0)
            button.text:SetJustifyH("CENTER")
        end
    else
        button.icon:Hide()
        button.text:ClearAllPoints()
        button.text:SetPoint("LEFT", 6, 0)
        button.text:SetPoint("RIGHT", -4, 0)
        button.text:SetWidth(0)
        button.text:SetJustifyH("CENTER")
    end

    button:Show()
end

function Module:RefreshBars()
    if not Addon.db or not Addon.db.databrokers then
        return
    end

    if not Addon:IsModuleEnabled("databroker_bars") then
        self:HideAllBars()
        return
    end

    local db = GetDataBrokerDB()

    if not LDB then
        self:HideAllBars()
        return
    end

    local moduleMedia = GetModuleMedia()
    local fontSize = moduleMedia.fontSize

    local fontPath
    local statusbarPath
    local borderPath
    local backgroundPath

    if LSM then
        if moduleMedia.font then
            fontPath = LSM:Fetch("font", moduleMedia.font, true)
        end
        if moduleMedia.statusbar then
            statusbarPath = LSM:Fetch("statusbar", moduleMedia.statusbar, true)
        end
        if moduleMedia.border then
            borderPath = LSM:Fetch("border", moduleMedia.border, true)
        end
        if moduleMedia.background then
            backgroundPath = LSM:Fetch("background", moduleMedia.background, true)
        end
    end

    fontPath = fontPath or rawget(_G, "STANDARD_TEXT_FONT") or "Fonts\\FRIZQT__.TTF"
    backgroundPath = backgroundPath or "Interface\\Tooltips\\UI-Tooltip-Background"
    borderPath = borderPath or "Interface\\Tooltips\\UI-Tooltip-Border"
    local buttonBackground = statusbarPath or "Interface\\Buttons\\WHITE8X8"
    local buttonBorder = borderPath or "Interface\\Buttons\\WHITE8X8"
    local textureColor = moduleMedia.textureColor
    local borderColor = moduleMedia.borderColor
    local borderSize = moduleMedia.borderSize
    local defaultBarBackground = textureColor
    local defaultBarBorder = borderColor

    local brokerMap = BuildBrokerMap()

    for barIndex, _ in ipairs(db.bars) do
        local cfg = EnsureBarConfig(barIndex)
        local bar = self.bars[barIndex] or CreateBarFrame(barIndex)
        self.bars[barIndex] = bar

        bar:SetMovable(db.unlocked and true or false)
        bar:EnableMouse(db.unlocked and true or false)

        bar:ClearAllPoints()
        bar:SetPoint(cfg.point, UIParent, cfg.relativePoint, cfg.x, cfg.y)
        bar:SetSize(cfg.width, cfg.height)
        bar:SetBackdrop({
            bgFile = db.showBackdrop and backgroundPath or "Interface\\Buttons\\WHITE8X8",
            edgeFile = db.showBorder and borderPath or "Interface\\Buttons\\WHITE8X8",
            tile = true,
            tileSize = 16,
            edgeSize = db.showBorder and borderSize or 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        local useBarColors = cfg.overrideColors and true or false
        local effectiveBarBackground = (useBarColors and cfg.backgroundColor) or defaultBarBackground
        local effectiveBarBorder = (useBarColors and cfg.borderColor) or defaultBarBorder
        if not effectiveBarBackground then effectiveBarBackground = defaultBarBackground end
        if not effectiveBarBorder then effectiveBarBorder = defaultBarBorder end
        if db.showBackdrop then
            bar:SetBackdropColor(effectiveBarBackground.r, effectiveBarBackground.g, effectiveBarBackground.b, effectiveBarBackground.a)
        else
            bar:SetBackdropColor(0, 0, 0, 0)
        end
        if db.showBorder then
            bar:SetBackdropBorderColor(effectiveBarBorder.r, effectiveBarBorder.g, effectiveBarBorder.b, effectiveBarBorder.a)
        else
            bar:SetBackdropBorderColor(0, 0, 0, 0)
        end
        bar:Show()

        local spacing = 4
        local slotWidth = cfg.maxBrokers > 0 and math.floor((cfg.width - ((cfg.maxBrokers - 1) * spacing)) / cfg.maxBrokers) or cfg.width

        for buttonIndex = 1, cfg.maxBrokers do
            local button = (self.buttons[barIndex] and self.buttons[barIndex][buttonIndex]) or CreateButton(bar, barIndex, buttonIndex)
            local brokerName = cfg.brokers[buttonIndex]
            local dataObject = brokerName and brokerMap[brokerName] or nil

            if dataObject then
                button.brokerName = brokerName
                button.dataObject = dataObject
                button:SetBackdrop({
                    bgFile = buttonBackground,
                    edgeFile = buttonBorder,
                    edgeSize = borderSize,
                })
                button:SetBackdropColor(0, 0, 0, 0)
                button:SetBackdropBorderColor(0, 0, 0, 0)
                button.text:SetFont(fontPath, fontSize)
                button.text:SetWordWrap(false)
                button.text:SetMaxLines(1)
                button:SetParent(bar)
                button:ClearAllPoints()
                if buttonIndex == 1 then
                    button:SetPoint("LEFT", bar, "LEFT", 0, 0)
                else
                    button:SetPoint("LEFT", self.buttons[barIndex][buttonIndex - 1], "RIGHT", spacing, 0)
                end
                button:SetSize(slotWidth, cfg.height)
                self:UpdateButtonVisual(button, cfg)
            else
                button.brokerName = nil
                button.dataObject = nil
                button:SetParent(bar)
                button:SetBackdrop({
                    bgFile = buttonBackground,
                    edgeFile = buttonBorder,
                    edgeSize = borderSize,
                })
                button:SetBackdropColor(0, 0, 0, 0)
                button:SetBackdropBorderColor(0, 0, 0, 0)
                button.text:SetWordWrap(false)
                button.text:SetMaxLines(1)
                button:ClearAllPoints()
                if buttonIndex == 1 then
                    button:SetPoint("LEFT", bar, "LEFT", 0, 0)
                else
                    button:SetPoint("LEFT", self.buttons[barIndex][buttonIndex - 1], "RIGHT", spacing, 0)
                end
                button:SetSize(slotWidth, cfg.height)
                self:UpdateButtonVisual(button, cfg)
            end
        end
    end

    for barIndex = #db.bars + 1, #self.bars do
        self.bars[barIndex]:Hide()
    end
end

function Module:OnBrokerChanged()
    self:RefreshBars()
end

function Module:ApplySettings()
    if not Addon:IsModuleEnabled("databroker_bars") then
        self:HideAllBars()
        return
    end

    self:RefreshBars()
end

function Module:OnInitialize()
    GetDataBrokerDB()

    local customModule = Addon:GetModule("databrokers")
    if customModule and type(customModule.InitializeCustomBrokers) == "function" then
        customModule:InitializeCustomBrokers()
    end

    if LDB and type(LDB.RegisterCallback) == "function" then
        LDB.RegisterCallback(self, "LibDataBroker_DataObjectCreated", "OnBrokerChanged")
        LDB.RegisterCallback(self, "LibDataBroker_AttributeChanged", "OnBrokerChanged")
    else
        Addon:Print("LibDataBroker-1.1 was not found. DataBroker bars are disabled.")
    end
end

function Module:OnEnable()
    self:RefreshBars()
end
