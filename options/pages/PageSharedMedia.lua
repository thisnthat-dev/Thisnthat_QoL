local ADDON_NAME, ns = ...

function ns:InitSharedMediaPage()
    local parent = ns.OptionsFrame.Content
    local W      = ns.OptionsWidgets
    local Addon  = ns.Addon

    local b = W.Builder(parent)

    b:Header("Shared Media Module")
    b:Desc("Registers custom fonts, textures, sounds, and borders with LibSharedMedia so they become available to other addons.")

    b:Toggle("Enable Shared Media Module",
        function() return Addon:IsModuleEnabled("shared_media") end,
        function(v)
            Addon.db.modules.shared_media.enabled = v and true or false
            Addon:Print("Shared Media module " .. (v and "enabled" or "disabled") .. ". Reload UI to apply.")
        end)

    b:Spacer(8)
    b:Header("Module Media Override")
    b:Desc("When 'Use Global' is off, this module uses its own media settings instead of the global ones.")

    b:Toggle("Use Global Addon Media",
        function()
            Addon.db.moduleMedia = Addon.db.moduleMedia or {}
            Addon.db.moduleMedia.shared_media = Addon.db.moduleMedia.shared_media or {}
            local cfg = Addon.db.moduleMedia.shared_media
            return cfg.useGlobal ~= false
        end,
        function(v)
            Addon.db.moduleMedia = Addon.db.moduleMedia or {}
            Addon.db.moduleMedia.shared_media = Addon.db.moduleMedia.shared_media or {}
            Addon.db.moduleMedia.shared_media.useGlobal = v and true or false
        end)

    b:Finalize()
end
