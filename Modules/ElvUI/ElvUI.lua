local _, ns = ...

local Addon = ns.Addon
local Module = {
    tagsRegistered = false,
    colorCurve = nil,
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
    if not E or type(E.AddTag) ~= "function" then
        return false
    end

    local colorCurve = self:GetColorCurve()
    if not colorCurve then
        return false
    end

    E:AddTag("health:percent-curvedcolor", "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH", function(unit)
        local color = UnitHealthPercent(unit, false, colorCurve)
        local value = UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)
        local text = string.format("%.0f", value)
        return color and color:WrapTextInColorCode(text) or text
    end)

    E:AddTag("healthcolor", "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH", function(unit)
        local color = UnitHealthPercent(unit, false, colorCurve)
        return color and color:GenerateHexColorMarkup() or ""
    end)

    self.tagsRegistered = true
    return true
end

function Module:SetEnabled(enabled)
    Addon.db.modules.ElvUI = Addon.db.modules.ElvUI or {}
    Addon.db.modules.ElvUI.enabled = enabled and true or false

    if enabled then
        if self:RegisterTags() then
            Addon:Print("ElvUI module enabled.")
        else
            Addon:Print("ElvUI module could not initialize. Ensure ElvUI is loaded.")
        end
    else
        Addon:Print("ElvUI module disabled.")
    end
end

function Module:OnEnable()
    self:RegisterTags()
end
