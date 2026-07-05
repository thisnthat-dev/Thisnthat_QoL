local ADDON_NAME, ns = ...

local function Clamp(value, minValue, maxValue, fallback)
    local n = tonumber(value)
    if not n then return fallback end
    if n < minValue then return minValue end
    if n > maxValue then return maxValue end
    return n
end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

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

-- Color palette matching NaowhQOL look and feel
ns.OptionsColors = {
    ACCENT = { r = 0.78, g = 0.23, b = 0.30 }, -- #c73a4c accent
    BLUE   = { r = 0.31, g = 0.30, b = 0.30 }, -- #4f4c4c border/divider
    BLUE2  = { r = 0.42, g = 0.40, b = 0.40 }, -- slightly brighter border highlight
    BG     = { r = 0.08, g = 0.08, b = 0.08 }, -- darker backdrop
    WHITE  = { r = 1.00, g = 1.00, b = 1.00 },
    GRAY   = { r = 0.67, g = 0.67, b = 0.67 },
    GREEN  = { r = 0.13, g = 0.77, b = 0.37 },
    YELLOW = { r = 0.98, g = 0.80, b = 0.08 },
}
local C = ns.OptionsColors

local function ApplyConfiguredAccentColor()
    local Addon = ns and ns.Addon
    if not Addon or type(Addon.GetGlobalMediaConfig) ~= "function" then
        return
    end

    local cfg = Addon:GetGlobalMediaConfig() or {}
    local accent = type(cfg.accentColor) == "table" and cfg.accentColor or {}
    C.ACCENT.r = Clamp(accent.r, 0, 1, 0.78)
    C.ACCENT.g = Clamp(accent.g, 0, 1, 0.23)
    C.ACCENT.b = Clamp(accent.b, 0, 1, 0.30)
end

ApplyConfiguredAccentColor()

local MainWindow = CreateFrame("Frame", "ThisnthatQoL_OptionsFrame", UIParent, "BackdropTemplate")
MainWindow:SetSize(950, 650)
MainWindow:SetPoint("CENTER")
MainWindow:SetFrameStrata("HIGH")
MainWindow:SetMovable(true)
MainWindow:SetResizable(true)
MainWindow:EnableMouse(true)
MainWindow:RegisterForDrag("LeftButton")
MainWindow:SetClampedToScreen(true)
MainWindow:SetScript("OnDragStart", MainWindow.StartMoving)
MainWindow:SetScript("OnDragStop", MainWindow.StopMovingOrSizing)
MainWindow:Hide()

MainWindow:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
MainWindow:SetBackdropColor(C.BG.r, C.BG.g, C.BG.b, 0.97)
MainWindow:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.9)

if MainWindow.SetResizeBounds then
    MainWindow:SetResizeBounds(860, 560, 1400, 980)
else
    if MainWindow.SetMinResize then MainWindow:SetMinResize(860, 560) end
    if MainWindow.SetMaxResize then MainWindow:SetMaxResize(1400, 980) end
end

local specialFrames = rawget(_G, "UISpecialFrames")
if type(specialFrames) == "table" then
    tinsert(specialFrames, MainWindow:GetName())
end

-- Accent top bar (3px)
local topBar = MainWindow:CreateTexture(nil, "OVERLAY")
topBar:SetHeight(3)
topBar:SetPoint("TOPLEFT",  MainWindow, "TOPLEFT",  1, -1)
topBar:SetPoint("TOPRIGHT", MainWindow, "TOPRIGHT", -1, -1)
topBar:SetColorTexture(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)

-- Border-tone bottom accent bar (2px)
local botBar = MainWindow:CreateTexture(nil, "OVERLAY")
botBar:SetHeight(2)
botBar:SetPoint("BOTTOMLEFT",  MainWindow, "BOTTOMLEFT",  1, 1)
botBar:SetPoint("BOTTOMRIGHT", MainWindow, "BOTTOMRIGHT", -1, 1)
botBar:SetColorTexture(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.85)

-- Close button
local closeBtn = CreateFrame("Button", nil, MainWindow, "BackdropTemplate")
closeBtn:SetSize(22, 22)
closeBtn:SetPoint("TOPRIGHT", -8, -8)
closeBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
closeBtn:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.34)
closeBtn:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.75)

local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
closeText:SetPoint("CENTER", 0, 0)
closeText:SetText("X")
closeText:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.92)

closeBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.36)
    self:SetBackdropBorderColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.95)
    closeText:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
end)

closeBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.34)
    self:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.75)
    closeText:SetTextColor(C.WHITE.r, C.WHITE.g, C.WHITE.b, 0.92)
end)

closeBtn:SetScript("OnClick", function()
    MainWindow:Hide()
end)

local resizeGrip = CreateFrame("Button", nil, MainWindow)
resizeGrip:SetSize(18, 18)
resizeGrip:SetPoint("BOTTOMRIGHT", MainWindow, "BOTTOMRIGHT", -3, 3)
resizeGrip:EnableMouse(true)
resizeGrip:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

local gripIcon = resizeGrip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
gripIcon:SetPoint("CENTER", 0, 0)
gripIcon:SetText("///")
gripIcon:SetTextColor(C.BLUE2.r, C.BLUE2.g, C.BLUE2.b, 0.9)

resizeGrip:SetScript("OnEnter", function()
    gripIcon:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 0.95)
end)

resizeGrip:SetScript("OnLeave", function()
    gripIcon:SetTextColor(C.BLUE2.r, C.BLUE2.g, C.BLUE2.b, 0.9)
end)

resizeGrip:SetScript("OnMouseDown", function(_, button)
    if button == "LeftButton" then
        MainWindow:StartSizing("BOTTOMRIGHT")
    end
end)

resizeGrip:SetScript("OnMouseUp", function(_, button)
    if button == "LeftButton" then
        MainWindow:StopMovingOrSizing()
    end
end)

-- Scrollable content area (right of sidebar)
local contentScroll = CreateFrame("ScrollFrame", nil, MainWindow)
contentScroll:SetPoint("TOPLEFT",     MainWindow, "TOPLEFT",     183, -5)
contentScroll:SetPoint("BOTTOMRIGHT", MainWindow, "BOTTOMRIGHT", -4,   4)
contentScroll:EnableMouseWheel(true)

local contentChild = CreateFrame("Frame", nil, contentScroll)
contentChild:SetWidth(740)
contentChild:SetHeight(1)
contentScroll:SetScrollChild(contentChild)

contentScroll:SetScript("OnMouseWheel", function(self, delta)
    local maxScroll = math.max(0, contentChild:GetHeight() - self:GetHeight())
    self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScroll() - delta * 28, maxScroll)))
end)

contentScroll:SetScript("OnSizeChanged", function(self)
    contentChild:SetWidth(math.max(200, self:GetWidth() - 4))
end)

function MainWindow:ResetContent()
    for _, c in ipairs({ contentChild:GetChildren() }) do
        if c and c.Hide then c:Hide() end
    end
    for _, r in ipairs({ contentChild:GetRegions() }) do
        if r and r.Hide then r:Hide() end
    end
    contentChild:SetHeight(1)
    contentScroll:SetVerticalScroll(0)
    ns.RefreshCurrentPage = nil
end

function MainWindow:ApplyCurrentFont()
    local fontPath, baseSize = ResolveOptionsFont()
    local visited = {}

    local function ApplyToObject(obj)
        if not obj or type(obj.GetFont) ~= "function" or type(obj.SetFont) ~= "function" then
            return
        end

        local _, currentSize, currentFlags = obj:GetFont()
        if not currentSize then
            return
        end

        local offset = obj._tntFontOffset
        if type(offset) ~= "number" then
            local prevBase = self._lastAppliedBaseSize or baseSize
            offset = currentSize - prevBase
            obj._tntFontOffset = offset
        end

        local size = Clamp(baseSize + offset, 6, 72, baseSize)
        obj:SetFont(fontPath, size, obj._tntFontFlags or currentFlags or "")
    end

    local function Walk(frame)
        if not frame or visited[frame] then
            return
        end
        visited[frame] = true

        ApplyToObject(frame)

        for _, region in ipairs({ frame:GetRegions() }) do
            ApplyToObject(region)
        end

        for _, child in ipairs({ frame:GetChildren() }) do
            Walk(child)
        end
    end

    Walk(self)
    self._lastAppliedBaseSize = baseSize
end

function MainWindow:ApplyCurrentAccent()
    ApplyConfiguredAccentColor()

    if topBar and topBar.SetColorTexture then
        topBar:SetColorTexture(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    end

    if type(ns.RefreshSidebarAccent) == "function" then
        ns:RefreshSidebarAccent()
    end
end

MainWindow:HookScript("OnShow", function(self)
    self:ApplyCurrentAccent()
    self:ApplyCurrentFont()
end)

MainWindow.Content = contentChild
ns.OptionsFrame    = MainWindow
