local _, ns = ...

local HOST_ADDON_NAME = "Thisnthat_QoL"

function ns.GetAddon()
    return rawget(_G, "Thisnthat_QoL_Addon")
end

ns.HostAddonName = HOST_ADDON_NAME
ns.Addon = ns.GetAddon()