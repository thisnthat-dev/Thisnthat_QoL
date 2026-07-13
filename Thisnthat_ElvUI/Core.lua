local ADDON_NAME = ...

local Addon = {}

local ElvUI = rawget(_G, "ElvUI")
local E = unpack(ElvUI)
local CurveConstants = rawget(_G, "CurveConstants")

local C_CurveUtil = C_CurveUtil
local UnitHealthPercent = UnitHealthPercent

local function ParseMajorVersion(versionText)
    if type(versionText) ~= "string" then
        return nil
    end

    local major = string.match(versionText, "^(%d+)")
    return tonumber(major)
end

local function Print(msg)
    local prefix = "|cff4ec9b0" .. ADDON_NAME .. "|r"
    print(prefix .. ": " .. tostring(msg))
end

function Addon:GetColorCurve()
    if Addon.color_curve then
        return Addon.color_curve
    end

    if not (C_CurveUtil and Enum and Enum.LuaCurveType and CreateColor and CurveConstants and UnitHealthPercent) then
        return
    end

    local colorCurve = C_CurveUtil.CreateColorCurve()
    colorCurve:SetType(Enum.LuaCurveType.Linear)
    colorCurve:AddPoint(0.0, CreateColor(1, 0.3, 0.31))
    colorCurve:AddPoint(0.3, CreateColor(1, 0.3, 0.31))
    colorCurve:AddPoint(0.5, CreateColor(1, 0.93, 0.43))
    colorCurve:AddPoint(0.8, CreateColor(0.38, 0.87, 0.23))
    colorCurve:AddPoint(1.0, CreateColor(0.38, 0.87, 0.23))

    Addon.color_curve = colorCurve
    return colorCurve
end

function Addon:AddColoredHealthPercertTag()
    local colorCurve = Addon:GetColorCurve()
    if not colorCurve then
        return
    end

    if not E or type(E.AddTag) ~= "function" then
        return
    end

    E:AddTag("health:percent-curvedcolor", "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH", function(unit)
        local color = UnitHealthPercent(unit, false, colorCurve)
        local value = UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)
        local text = string.format("%.0f", value)
        return color and color:WrapTextInColorCode(text) or text
    end)
end

function Addon:AddHealthColorTag()
    local colorCurve = Addon:GetColorCurve()
    if not colorCurve then
        return
    end

    if not E or type(E.AddTag) ~= "function" then
        return
    end

    E:AddTag("healthcolor", "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH", function(unit)
        local color = UnitHealthPercent(unit, false, colorCurve)
        return color and color:GenerateHexColorMarkup() or ""
    end)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, loadedName)
    if loadedName ~= ADDON_NAME then
        return
    end
    
    Addon:AddColoredHealthPercertTag()
    Addon:AddHealthColorTag()
    loader:UnregisterEvent("ADDON_LOADED")
end)
