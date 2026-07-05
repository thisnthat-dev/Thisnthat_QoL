local ADDON_NAME, ns = ...

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
        panel.name  = ADDON_NAME

        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText(ADDON_NAME)
        ApplyFont(title, 2)

        local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
        desc:SetText("Type  /tnt  or  /thisnthat_qol  to open the settings window.")
        desc:SetTextColor(0.67, 0.67, 0.67, 1)
        ApplyFont(desc, -1)

        local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btn:SetSize(180, 32)
        btn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -14)
        btn:SetText("Open " .. ADDON_NAME)
        btn:SetScript("OnClick", function()
            if ns.OptionsFrame then ns.OptionsFrame:Show() end
        end)

        local category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_NAME)
        Settings.RegisterAddOnCategory(category)
    end
end)
