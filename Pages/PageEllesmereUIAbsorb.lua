local ADDON_NAME, ns = ...

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local function IsAddOnLoadedByName(addOnName)
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        return C_AddOns.IsAddOnLoaded(addOnName) and true or false
    end

    local isAddOnLoaded = rawget(_G, "IsAddOnLoaded")
    if type(isAddOnLoaded) == "function" then
        return isAddOnLoaded(addOnName) and true or false
    end

    return false
end

function ns:InitEllesmereUIAbsorbPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    local parent = ns.OptionsFrame.Content
    local W = ns.OptionsWidgets
    local C = ns.OptionsColors
    local Addon = (type(ns.GetAddon) == "function" and ns.GetAddon()) or ns.Addon
    local module = Addon and Addon.GetModule and Addon:GetModule("EllesmereUIAbsorb") or nil
    local resourceBarsLoaded = IsAddOnLoadedByName("EllesmereUIResourceBars")
    local DEFAULT_ABSORB_TEXTURE = "Thisnthat Shield"

    local function appendUnique(items, seen, name)
        if type(name) ~= "string" or name == "" or seen[name] then
            return
        end

        seen[name] = true
        items[#items + 1] = { value = name, label = name }
    end

    local function cfg()
        return (module and type(module.GetSettings) == "function" and module:GetSettings())
            or (Addon.db and Addon.db.EllesmereUIAbsorb)
            or {}
    end

    local function lsmItems(mediaType)
        local items = {}
        local seen = {}

        if mediaType == "statusbar" and module and type(module.GetBuiltInTextureNames) == "function" then
            for _, name in ipairs(module:GetBuiltInTextureNames() or {}) do
                appendUnique(items, seen, name)
            end
        end

        if LSM and type(LSM.List) == "function" then
            for _, name in ipairs(LSM:List(mediaType) or {}) do
                appendUnique(items, seen, name)
            end
        end
        return items
    end

    local function apply()
        if module and type(module.ApplySettings) == "function" then
            module:ApplySettings()
        end

        if ns.RefreshCurrentPage then
            ns.RefreshCurrentPage()
        end
    end

    local function applyPreviewTiling(statusBar, textureName)
        if not statusBar then
            return
        end

        local texturePath = nil
        if LSM and type(LSM.Fetch) == "function" and type(textureName) == "string" and textureName ~= "" then
            texturePath = LSM:Fetch("statusbar", textureName, true)
        end

        local tiled = module
            and type(module.IsTiledAbsorbTexture) == "function"
            and module:IsTiledAbsorbTexture(textureName, texturePath)

        local fill = statusBar:GetStatusBarTexture()
        if fill then
            fill:SetDrawLayer("ARTWORK", 1)
            fill:SetHorizTile(tiled and true or false)
            fill:SetVertTile(tiled and true or false)
        end
    end

    local b = W.Builder(parent)

    b:Header("EllesmereUI Absorb")
    b:Desc("Configure the absorb and heal-absorb overlay used by EllesmereUIResourceBars.")

    if not resourceBarsLoaded then
        b:Desc("|cffff7777EllesmereUIResourceBars is not currently loaded, so this module is disabled.|r")
        b:Finalize()

        ns.RefreshCurrentPage = function()
            ns:InitEllesmereUIAbsorbPage()
        end
        return
    end

    b:Toggle("Enable module",
        function()
            return cfg().enabled and true or false
        end,
        function(v)
            if module and type(module.SetEnabled) == "function" then
                module:SetEnabled(v and true or false)
            else
                cfg().enabled = v and true or false
            end
            apply()
        end)

    b:Color("Absorb Color",
        function()
            local color = cfg().absorbColor or {}
            return color.r or 1, color.g or 1, color.b or 1, color.a or 0.8
        end,
        function(r, g, bv, a)
            cfg().absorbColor = { r = r, g = g, b = bv, a = a }
            apply()
        end,
        true)

    b:Color("Heal Absorb Color",
        function()
            local color = cfg().healAbsorbColor or {}
            return color.r or 0.8, color.g or 0.15, color.b or 0.15, color.a or 0.65
        end,
        function(r, g, bv, a)
            cfg().healAbsorbColor = { r = r, g = g, b = bv, a = a }
            apply()
        end,
        true)

    b:Cycle("Absorb Texture",
        function()
            return lsmItems("statusbar")
        end,
        function()
            return cfg().absorbTexture or DEFAULT_ABSORB_TEXTURE
        end,
        function(v)
            cfg().absorbTexture = v or DEFAULT_ABSORB_TEXTURE
            apply()
        end,
        0,
        260)

    b:Cycle("Heal Absorb Texture",
        function()
            return lsmItems("statusbar")
        end,
        function()
            return cfg().healAbsorbTexture or DEFAULT_ABSORB_TEXTURE
        end,
        function(v)
            cfg().healAbsorbTexture = v or DEFAULT_ABSORB_TEXTURE
            apply()
        end,
        0,
        260)

    local previewWrap = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    previewWrap:SetHeight(88)
    previewWrap:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    previewWrap:SetBackdropColor(0.04, 0.05, 0.06, 0.92)
    previewWrap:SetBackdropBorderColor(C.BLUE.r, C.BLUE.g, C.BLUE.b, 0.5)

    local previewLabel = previewWrap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewLabel:SetPoint("TOPLEFT", previewWrap, "TOPLEFT", 10, -8)
    previewLabel:SetText("Preview")
    previewLabel:SetTextColor(C.ACCENT.r, C.ACCENT.g, C.ACCENT.b, 1)
    W.ApplyFont(previewLabel, -1)

    local previewBar = CreateFrame("Frame", nil, previewWrap, "BackdropTemplate")
    previewBar:SetPoint("TOPLEFT", previewLabel, "BOTTOMLEFT", 0, -8)
    previewBar:SetPoint("TOPRIGHT", previewWrap, "TOPRIGHT", -10, -12)
    previewBar:SetHeight(42)
    previewBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    previewBar:SetBackdropColor(0.07, 0.08, 0.10, 1)

    local health = CreateFrame("StatusBar", nil, previewBar)
    health:SetAllPoints(previewBar)
    health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    health:SetMinMaxValues(0, 100)
    health:SetValue(62)
    health:SetStatusBarColor(0.12, 0.14, 0.17, 1)

    local absorb = CreateFrame("StatusBar", nil, previewBar)
    absorb:SetAllPoints(previewBar)
    local absorbTextureName = cfg().absorbTexture or DEFAULT_ABSORB_TEXTURE
    absorb:SetStatusBarTexture(module and type(module.GetAbsorbTexturePath) == "function" and module:GetAbsorbTexturePath() or "Interface\\Buttons\\WHITE8X8")
    absorb:SetReverseFill(false)
    absorb:SetMinMaxValues(0, 100)
    absorb:SetValue(22)
    absorb:SetFrameLevel(health:GetFrameLevel() + 1)
    applyPreviewTiling(absorb, absorbTextureName)
    local absorbTexture = absorb:GetStatusBarTexture()
    if absorbTexture then
        local color = cfg().absorbColor or {}
        absorbTexture:SetVertexColor(color.r or 1, color.g or 1, color.b or 1, color.a or 0.8)
    end

    local healAbsorb = CreateFrame("StatusBar", nil, previewBar)
    healAbsorb:SetAllPoints(previewBar)
    local healAbsorbTextureName = cfg().healAbsorbTexture or DEFAULT_ABSORB_TEXTURE
    healAbsorb:SetStatusBarTexture(module and type(module.GetHealAbsorbTexturePath) == "function" and module:GetHealAbsorbTexturePath() or "Interface\\Buttons\\WHITE8X8")
    healAbsorb:SetReverseFill(true)
    healAbsorb:SetMinMaxValues(0, 100)
    healAbsorb:SetValue(16)
    healAbsorb:SetFrameLevel(health:GetFrameLevel() + 2)
    applyPreviewTiling(healAbsorb, healAbsorbTextureName)
    local healTexture = healAbsorb:GetStatusBarTexture()
    if healTexture then
        local color = cfg().healAbsorbColor or {}
        healTexture:SetVertexColor(color.r or 0.8, color.g or 0.15, color.b or 0.15, color.a or 0.65)
    end

    local previewText = previewBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewText:SetPoint("LEFT", previewBar, "LEFT", 10, 0)
    previewText:SetText("Absorb and heal absorb preview")
    previewText:SetTextColor(1, 1, 1, 0.86)
    W.ApplyFont(previewText, -1)

    b:_Attach(previewWrap, 88, 8)
    b:Finalize()

    ns.RefreshCurrentPage = function()
        ns:InitEllesmereUIAbsorbPage()
    end
end