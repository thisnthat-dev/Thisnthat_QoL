local _, ns = ...

local HOST_ADDON_NAME = "Thisnthat"

function ns.GetAddon()
    return rawget(_G, "Thisnthat_Addon")
end

ns.HostAddonName = HOST_ADDON_NAME
ns.Addon = ns.GetAddon()