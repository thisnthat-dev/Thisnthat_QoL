local ADDON_NAME, ns = ...
local OPTIONS_TITLE = ns.HostAddonName or "Thisnthat_QoL"

-- Options.lua: minimal Blizzard interface panel registration.
-- All settings are handled by the custom window (open with /tnt).

local addonFrame = CreateFrame("Frame")
addonFrame:RegisterEvent("ADDON_LOADED")
addonFrame:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON_NAME then return end

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local W = ns.OptionsWidgets
        local function ApplyFont(target, offset)
            if W and W.ApplyFont then
                W.ApplyFont(target, offset)
            end
        end

        local panel = CreateFrame("Frame")
        panel.name  = OPTIONS_TITLE

        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText(OPTIONS_TITLE)
        ApplyFont(title, 2)

        local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
        desc:SetText("Type  /tnt  or  /thisnthat_qol  to open the settings window.")
        desc:SetTextColor(0.67, 0.67, 0.67, 1)
        ApplyFont(desc, -1)

        local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btn:SetSize(180, 32)
        btn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -14)
        btn:SetText("Open " .. OPTIONS_TITLE)
        btn:SetScript("OnClick", function()
            local showOptions = rawget(_G, "Thisnthat_QoL_ShowOptions")
            if type(showOptions) == "function" then
                showOptions("addon_settings")
            elseif ns.OptionsFrame then
                ns.OptionsFrame:Show()
            end
        end)

        local category = Settings.RegisterCanvasLayoutCategory(panel, OPTIONS_TITLE)
        Settings.RegisterAddOnCategory(category)
    end
end)
