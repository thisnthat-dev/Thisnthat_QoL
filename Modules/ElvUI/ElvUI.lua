local _, ns = ...

local Addon = ns.Addon
local Module = {
    tagsRegistered = false,
    colorCurve = nil,
    retryQueued = false,
}

Addon:RegisterModule("ElvUI", Module)

local CurveConstants = rawget(_G, "CurveConstants")
local C_CurveUtil = C_CurveUtil
local UnitHealthPercent = UnitHealthPercent

local function ResolveElvUIEngine()
    local ElvUI = rawget(_G, "ElvUI")
    if type(ElvUI) ~= "table" then
        return nil
    end

    local engine = unpack(ElvUI)
    if type(engine) ~= "table" then
        return nil
    end

    return engine
end

local function IsElvUILoaded()
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        return C_AddOns.IsAddOnLoaded("ElvUI") and true or false
    end

    local isAddOnLoaded = rawget(_G, "IsAddOnLoaded")
    if type(isAddOnLoaded) == "function" then
        return isAddOnLoaded("ElvUI") and true or false
    end

    return false
end

function Module:GetColorCurve()
    if self.colorCurve then
        return self.colorCurve
    end

    if not (C_CurveUtil and Enum and Enum.LuaCurveType and CreateColor and CurveConstants and UnitHealthPercent) then
        return nil
    end

    local colorCurve = C_CurveUtil.CreateColorCurve()
    colorCurve:SetType(Enum.LuaCurveType.Linear)
    colorCurve:AddPoint(0.0, CreateColor(1, 0.3, 0.31))
    colorCurve:AddPoint(0.3, CreateColor(1, 0.3, 0.31))
    colorCurve:AddPoint(0.5, CreateColor(1, 0.93, 0.43))
    colorCurve:AddPoint(0.8, CreateColor(0.38, 0.87, 0.23))
    colorCurve:AddPoint(1.0, CreateColor(0.38, 0.87, 0.23))

    self.colorCurve = colorCurve
    return colorCurve
end

function Module:RegisterTags()
    if self.tagsRegistered then
        return true
    end

    if not IsElvUILoaded() then
        return false
    end

    local E = ResolveElvUIEngine()
    if not E or type(E.oUF) ~= "table" or type(E.oUF.Tags) ~= "table" then
        return false
    end

    local Tags = E.oUF.Tags
    if type(Tags.Methods) ~= "table" or type(Tags.Events) ~= "table" then
        return false
    end

    local colorCurve = self:GetColorCurve()

    local healthColorTag = function(unit)
        if type(UnitHealthPercent) == "function" and colorCurve then
            local color = UnitHealthPercent(unit, false, colorCurve)
            if color and type(color.GenerateHexColorMarkup) == "function" then
                return color:GenerateHexColorMarkup()
            end
        end

        return "|cffffffff"
    end

    Tags.Events.healthcolor = "UNIT_HEALTH UNIT_MAXHEALTH"
    Tags.Methods.healthcolor = healthColorTag

    if type(Tags.RefreshMethods) == "function" then
        Tags:RefreshMethods("healthcolor")
    end

    self.tagsRegistered = true
    return true
end

function Module:QueueRetry()
    if self.tagsRegistered or self.retryQueued then
        return
    end

    if not (C_Timer and type(C_Timer.After) == "function") then
        return
    end

    self.retryQueued = true
    C_Timer.After(1, function()
        self.retryQueued = false
        if not self:RegisterTags() then
            self:QueueRetry()
        end
    end)
end

function Module:OnInitialize()
    if not self:RegisterTags() then
        self:QueueRetry()
    end
end

function Module:SetEnabled(enabled)
    Addon.db.modules.ElvUI = Addon.db.modules.ElvUI or {}
    Addon.db.modules.ElvUI.enabled = enabled and true or false

    if enabled then
        if self:RegisterTags() then
            Addon:Print("ElvUI module enabled.")
        else
            self:QueueRetry()
            Addon:Print("ElvUI module could not initialize. Ensure ElvUI is loaded.")
        end
    else
        Addon:Print("ElvUI module disabled.")
    end
end

function Module:OnEnable()
    if not self:RegisterTags() then
        self:QueueRetry()
    end
end

local bootstrap = CreateFrame("Frame")
bootstrap:RegisterEvent("PLAYER_LOGIN")
bootstrap:RegisterEvent("ADDON_LOADED")
bootstrap:SetScript("OnEvent", function(_, event, loadedName)
    if Module.tagsRegistered then
        bootstrap:UnregisterEvent("PLAYER_LOGIN")
        bootstrap:UnregisterEvent("ADDON_LOADED")
        return
    end

    if event == "PLAYER_LOGIN" or loadedName == "ElvUI" then
        if not Module:RegisterTags() then
            Module:QueueRetry()
        end
    end
end)
