local ADDON_NAME, ns = ...

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

function ns:InitElvUIPage()
    if ns.OptionsFrame and ns.OptionsFrame.ResetContent then
        ns.OptionsFrame:ResetContent()
    end

    local parent = ns.OptionsFrame.Content
    local W = ns.OptionsWidgets
    local Addon = (type(ns.GetAddon) == "function" and ns.GetAddon()) or ns.Addon
    local module = Addon and Addon.GetModule and Addon:GetModule("ElvUI") or nil
    local elvuiLoaded = IsAddOnLoadedByName("ElvUI")

    local b = W.Builder(parent)

    b:Header("ElvUI Integration")
    if elvuiLoaded then
        b:Desc("ElvUI detected. Enable this module to register health color tags.")
    else
        b:Desc("ElvUI is not currently loaded. The module stays disabled until ElvUI is available.")
    end

    b:Toggle("Enable ElvUI module",
        function()
            if not Addon or not Addon.db or not Addon.db.modules or not Addon.db.modules.ElvUI then
                return false
            end
            return Addon.db.modules.ElvUI.enabled and true or false
        end,
        function(v)
            if module and type(module.SetEnabled) == "function" then
                module:SetEnabled(v and true or false)
            else
                Addon.db.modules.ElvUI = Addon.db.modules.ElvUI or {}
                Addon.db.modules.ElvUI.enabled = v and true or false
            end

            if ns.RefreshCurrentPage then
                ns.RefreshCurrentPage()
            end
        end)

    b:Finalize()

    ns.RefreshCurrentPage = function()
        ns:InitElvUIPage()
    end
end
