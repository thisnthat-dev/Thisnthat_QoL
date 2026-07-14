local _, ns = ...

local Addon = ns.Addon
local Module = {}

Addon:RegisterModule("PerformanceSettings", Module)

local CATEGORY_ORDER = {
    { key = "graphics_tab",   name = "Graphics Tab" },
    { key = "graphics",       name = "Graphics Quality" },
    { key = "advanced",       name = "Advanced" },
    { key = "optimization",   name = "Additional Optimizations" },
    { key = "special",        name = "Special" },
    { key = "logging",        name = "Logging" },
}

local FPS_CVAR_DEFS = {
    { cvar = "vsync",                           recommended = "0",   label = "VSync",                       category = "graphics_tab" },
    { cvar = "LowLatencyMode",                  recommended = "3",   label = "Low Latency Mode",            category = "graphics_tab" },
    { cvar = "MSAAQuality",                     recommended = "0",   label = "MSAA Quality",                category = "graphics_tab" },
    { cvar = "ffxAntiAliasingMode",             recommended = "0",   label = "Anti-Aliasing",               category = "graphics_tab" },
    { cvar = "MSAAalphaTest",                   recommended = "1",   label = "MSAA Alpha Test",             category = "graphics_tab" },
    { cvar = "cameraFov",                       recommended = "90",  label = "Camera FOV",                  category = "graphics_tab" },

    { cvar = "graphicsQuality",                 recommended = "9",   label = "Graphics Quality",            category = "graphics" },
    { cvar = "graphicsShadowQuality",           recommended = "0",   label = "Shadow Quality",              category = "graphics" },
    { cvar = "graphicsLiquidDetail",            recommended = "1",   label = "Liquid Detail",               category = "graphics" },
    { cvar = "graphicsParticleDensity",         recommended = "5",   label = "Particle Density",            category = "graphics" },
    { cvar = "graphicsSSAO",                    recommended = "0",   label = "SSAO",                        category = "graphics" },
    { cvar = "graphicsDepthEffects",            recommended = "0",   label = "Depth Effects",               category = "graphics" },
    { cvar = "graphicsComputeEffects",          recommended = "0",   label = "Compute Effects",             category = "graphics" },
    { cvar = "graphicsOutlineMode",             recommended = "2",   label = "Outline Mode",                category = "graphics" },
    { cvar = "OutlineEngineMode",               recommended = "1",   label = "Outline Engine Mode",         category = "graphics" },
    { cvar = "graphicsTextureResolution",       recommended = "2",   label = "Texture Resolution",          category = "graphics" },
    { cvar = "graphicsSpellDensity",            recommended = "0",   label = "Spell Density",               category = "graphics" },
    { cvar = "spellClutter",                    recommended = "1",   label = "Spell Clutter",               category = "graphics" },
    { cvar = "spellVisualDensityFilterSetting", recommended = "1",   label = "Spell Visual Density Filter", category = "graphics" },
    { cvar = "graphicsProjectedTextures",       recommended = "1",   label = "Projected Textures",          category = "graphics" },
    { cvar = "projectedTextures",               recommended = "1",   label = "Projected Textures (Legacy)", category = "graphics" },
    { cvar = "graphicsViewDistance",            recommended = "3",   label = "View Distance",               category = "graphics" },
    { cvar = "graphicsEnvironmentDetail",       recommended = "0",   label = "Environment Detail",          category = "graphics" },
    { cvar = "graphicsGroundClutter",           recommended = "0",   label = "Ground Clutter",              category = "graphics" },

    { cvar = "GxMaxFrameLatency",               recommended = "2",   label = "Max Frame Latency",           category = "advanced" },
    { cvar = "textureFilteringMode",            recommended = "5",   label = "Texture Filtering",           category = "advanced" },
    { cvar = "shadowRt",                        recommended = "0",   label = "Ray Traced Shadows",          category = "advanced" },
    { cvar = "ResampleQuality",                 recommended = "3",   label = "Resample Quality",            category = "advanced" },
    { cvar = "vrsValar",                        recommended = "0",   label = "Variable Rate Shading",       category = "advanced" },
    { cvar = "GxApi",                           recommended = "D3D12",label = "Graphics API",                category = "advanced" },
    { cvar = "physicsLevel",                    recommended = "0",   label = "Physics Level",               category = "advanced" },
    { cvar = "maxFPS",                          recommended = "144", label = "Max FPS",                     category = "advanced" },
    { cvar = "maxFPSBk",                        recommended = "60",  label = "Background Max FPS",          category = "advanced" },
    { cvar = "targetFPS",                       recommended = "61",  label = "Target FPS",                  category = "advanced" },
    { cvar = "useTargetFPS",                    recommended = "0",   label = "Use Target FPS",              category = "advanced" },
    { cvar = "ResampleSharpness",               recommended = "0.2", label = "Resample Sharpness",          category = "advanced" },
    { cvar = "Contrast",                        recommended = "75",  label = "Contrast",                    category = "advanced" },
    { cvar = "Brightness",                      recommended = "50",  label = "Brightness",                  category = "advanced" },
    { cvar = "Gamma",                           recommended = "1",   label = "Gamma",                       category = "advanced" },

    { cvar = "particulatesEnabled",             recommended = "0",   label = "Particulates",                category = "optimization" },
    { cvar = "clusteredShading",                recommended = "0",   label = "Clustered Shading",           category = "optimization" },
    { cvar = "volumeFogLevel",                  recommended = "0",   label = "Volume Fog",                  category = "optimization" },
    { cvar = "reflectionMode",                  recommended = "0",   label = "Reflection Mode",             category = "optimization" },
    { cvar = "ffxGlow",                         recommended = "0",   label = "Glow Effect",                 category = "optimization" },
    { cvar = "farclip",                         recommended = "5000",label = "Far Clip",                    category = "optimization" },
    { cvar = "horizonStart",                    recommended = "1000",label = "Horizon Start",               category = "optimization" },
    { cvar = "horizonClip",                     recommended = "5000",label = "Horizon Clip",                category = "optimization" },
    { cvar = "lodObjectCullSize",               recommended = "35",  label = "LOD Object Cull Size",        category = "optimization" },
    { cvar = "lodObjectFadeScale",              recommended = "50",  label = "LOD Object Fade Scale",       category = "optimization" },
    { cvar = "lodObjectMinSize",                recommended = "0",   label = "LOD Object Min Size",         category = "optimization" },
    { cvar = "doodadLodScale",                  recommended = "50",  label = "Doodad LOD Scale",            category = "optimization" },
    { cvar = "entityLodDist",                   recommended = "7",   label = "Entity LOD Distance",         category = "optimization" },
    { cvar = "terrainLodDist",                  recommended = "350", label = "Terrain LOD Distance",        category = "optimization" },
    { cvar = "TerrainLodDiv",                   recommended = "512", label = "Terrain LOD Divisor",         category = "optimization" },
    { cvar = "waterDetail",                     recommended = "1",   label = "Water Detail",                category = "optimization" },
    { cvar = "rippleDetail",                    recommended = "0",   label = "Ripple Detail",               category = "optimization" },
    { cvar = "weatherDensity",                  recommended = "3",   label = "Weather Density",             category = "optimization" },
    { cvar = "entityShadowFadeScale",           recommended = "15",  label = "Entity Shadow Fade",          category = "optimization" },
    { cvar = "groundEffectDist",                recommended = "40",  label = "Ground Effect Distance",      category = "optimization" },
    { cvar = "ResampleAlwaysSharpen",           recommended = "1",   label = "Always Sharpen",              category = "optimization" },

    { cvar = "cameraDistanceMaxZoomFactor",     recommended = "2.6", label = "Max Camera Zoom",             category = "special" },
    { cvar = "CameraReduceUnexpectedMovement",  recommended = "1",   label = "Reduce Unexpected Movement",  category = "special" },

    { cvar = "advancedCombatLogging",           recommended = "1",   label = "Advanced Combat Logging",     category = "logging" },
}

local CVAR_BY_NAME = {}
for _, def in ipairs(FPS_CVAR_DEFS) do
    CVAR_BY_NAME[def.cvar] = def
end

local function GetCVarValue(name)
    if C_CVar and type(C_CVar.GetCVar) == "function" then
        return tostring(C_CVar.GetCVar(name) or "")
    end

    if type(GetCVar) == "function" then
        return tostring(GetCVar(name) or "")
    end

    return ""
end

local function SetCVarValue(name, value)
    if C_CVar and type(C_CVar.SetCVar) == "function" then
        return C_CVar.SetCVar(name, value) ~= false
    end

    if type(SetCVar) == "function" then
        SetCVar(name, value)
        return true
    end

    return false
end

local function GetBackupDB()
    Addon.db.PerformanceSettings = type(Addon.db.PerformanceSettings) == "table" and Addon.db.PerformanceSettings or {}

    if type(Addon.db.performanceSettings) == "table" and type(Addon.db.performanceSettings.backup) == "table" and type(Addon.db.PerformanceSettings.backup) ~= "table" then
        Addon.db.PerformanceSettings.backup = Addon.db.performanceSettings.backup
    end

    if type(Addon.db.fps) == "table" and type(Addon.db.fps.backup) == "table" and type(Addon.db.PerformanceSettings.backup) ~= "table" then
        Addon.db.PerformanceSettings.backup = Addon.db.fps.backup
    end

    Addon.db.PerformanceSettings.backup = type(Addon.db.PerformanceSettings.backup) == "table" and Addon.db.PerformanceSettings.backup or {}
    return Addon.db.PerformanceSettings.backup
end

local function SaveBackupIfMissing(cvarName)
    local backup = GetBackupDB()
    if backup[cvarName] == nil then
        backup[cvarName] = GetCVarValue(cvarName)
    end
end

local BOOLEAN_CVARS = {
    vsync = true,
    useTargetFPS = true,
    graphicsProjectedTextures = true,
    projectedTextures = true,
    particulatesEnabled = true,
    clusteredShading = true,
    ResampleAlwaysSharpen = true,
    CameraReduceUnexpectedMovement = true,
    advancedCombatLogging = true,
}

local VALUE_LABELS = {
    LowLatencyMode = {
        ["0"] = "None",
        ["1"] = "Built-In",
        ["2"] = "Reflex",
        ["3"] = "Reflex+Boost",
        ["4"] = "XeLL",
    },
    GxApi = {
        ["D3D11"] = "DX11",
        ["D3D12"] = "DX12",
        ["OPENGL"] = "OpenGL",
        ["VULKAN"] = "Vulkan",
        ["AUTO"] = "Auto",
    },
    graphicsQuality = {
        ["0"] = "Custom",
        ["1"] = "Low",
        ["2"] = "Fair",
        ["3"] = "Good",
        ["4"] = "High",
        ["5"] = "Ultra",
    },
    graphicsProjectedTextures = {
        ["0"] = "Disabled",
        ["1"] = "Enabled",
    },
    projectedTextures = {
        ["0"] = "Disabled",
        ["1"] = "Enabled",
    },
    graphicsShadowQuality = {
        ["0"] = "Low",
        ["1"] = "Fair",
        ["2"] = "Good",
        ["3"] = "High",
        ["4"] = "Ultra",
        ["5"] = "Ultra High",
    },
    graphicsLiquidDetail = {
        ["0"] = "Low",
        ["1"] = "Fair",
        ["2"] = "Good",
        ["3"] = "High",
    },
    graphicsSSAO = {
        ["0"] = "Disabled",
        ["1"] = "Low",
        ["2"] = "Good",
        ["3"] = "High",
        ["4"] = "Ultra",
    },
    graphicsDepthEffects = {
        ["0"] = "Disabled",
        ["1"] = "Low",
        ["2"] = "Good",
        ["3"] = "High",
    },
    graphicsComputeEffects = {
        ["0"] = "Disabled",
        ["1"] = "Low",
        ["2"] = "Good",
        ["3"] = "High",
    },
    graphicsOutlineMode = {
        ["0"] = "Off",
        ["1"] = "On",
        ["2"] = "High",
    },
    OutlineEngineMode = {
        ["0"] = "Disabled",
        ["1"] = "Enabled",
    },
    graphicsTextureResolution = {
        ["0"] = "Low",
        ["1"] = "Low",
        ["2"] = "High",
        ["3"] = "Ultra",
    },
    graphicsSpellDensity = {
        ["0"] = "Essential",
        ["1"] = "Low",
        ["2"] = "Fair",
        ["3"] = "Good",
        ["4"] = "High",
        ["5"] = "Ultra",
    },
    spellClutter = {
        ["0"] = "Disabled",
        ["1"] = "Enabled",
    },
    spellVisualDensityFilterSetting = {
        ["0"] = "Low",
        ["1"] = "High",
    },
    graphicsViewDistance = {
        ["0"] = "1",
        ["1"] = "2",
        ["2"] = "3",
        ["3"] = "4",
        ["4"] = "5",
        ["5"] = "6",
    },
    graphicsEnvironmentDetail = {
        ["0"] = "1",
        ["1"] = "2",
        ["2"] = "3",
        ["3"] = "4",
        ["4"] = "5",
        ["5"] = "6",
        ["6"] = "7",
        ["7"] = "8",
        ["8"] = "9",
        ["9"] = "10",
    },
    graphicsGroundClutter = {
        ["0"] = "1",
        ["1"] = "2",
        ["2"] = "3",
        ["3"] = "4",
        ["4"] = "5",
        ["5"] = "6",
        ["6"] = "7",
        ["7"] = "8",
        ["8"] = "9",
        ["9"] = "10",
    },
    GxMaxFrameLatency = {
        ["0"] = "Disabled",
        ["1"] = "Disabled",
        ["2"] = "Disabled",
        ["3"] = "Enabled",
    },
    textureFilteringMode = {
        ["0"] = "Bilinear",
        ["1"] = "Trilinear",
        ["2"] = "2x Anisotropic",
        ["3"] = "4x Anisotropic",
        ["4"] = "8x Anisotropic",
        ["5"] = "16x Anisotropic",
    },
    shadowRt = {
        ["0"] = "Disabled",
        ["1"] = "Low",
        ["2"] = "Good",
        ["3"] = "High",
        ["4"] = "Ultra",
    },
    ResampleQuality = {
        ["0"] = "Point",
        ["1"] = "Bilinear",
        ["2"] = "Bicubic",
        ["3"] = "FidelityFX SR 1.0",
    },
    vrsValar = {
        ["0"] = "Disabled",
        ["1"] = "Enabled",
    },
    physicsLevel = {
        ["0"] = "None",
        ["1"] = "Player Only",
        ["2"] = "Full",
    },
}

local function DisplayValue(cvarName, value)
    if value == nil then return "" end
    if BOOLEAN_CVARS[cvarName] then
        return (value == "1" or value == "true") and "Enabled" or "Disabled"
    end
    local labelMap = VALUE_LABELS[cvarName]
    if labelMap then
        local labeledValue = labelMap[tostring(value)]
        if labeledValue then
            return labeledValue
        end
    end
    if cvarName == "maxFPS" or cvarName == "maxFPSBk" or cvarName == "targetFPS" then
        return tostring(value) .. " FPS"
    end
    return tostring(value)
end

function Module:GetCVarEntries()
    local entries = {}

    for _, def in ipairs(FPS_CVAR_DEFS) do
        local cvarName = def.cvar
        local recommended = tostring(def.recommended)
        local current = GetCVarValue(cvarName)
        entries[#entries + 1] = {
            cvar = cvarName,
            label = def.label or cvarName,
            category = def.category,
            current = current,
            recommended = recommended,
            matches = current == recommended,
        }
    end

    return entries
end

function Module:GetRecommendedValue(cvarName)
    local def = CVAR_BY_NAME[cvarName]
    if not def then
        return nil
    end

    return tostring(def.recommended)
end

function Module:GetCurrentValue(cvarName)
    if not CVAR_BY_NAME[cvarName] then
        return nil
    end

    return GetCVarValue(cvarName)
end

function Module:GetDisplayCurrentValue(cvarName)
    local value = self:GetCurrentValue(cvarName)
    if value == nil then return nil end
    return DisplayValue(cvarName, value)
end

function Module:GetDisplayRecommendedValue(cvarName)
    local value = self:GetRecommendedValue(cvarName)
    if value == nil then return nil end
    return DisplayValue(cvarName, value)
end

function Module:GetCategoryGroups()
    local groups = {}

    for _, category in ipairs(CATEGORY_ORDER) do
        local entries = {}
        for _, def in ipairs(FPS_CVAR_DEFS) do
            if def.category == category.key then
                local current = GetCVarValue(def.cvar)
                local recommended = tostring(def.recommended)
                entries[#entries + 1] = {
                    cvar = def.cvar,
                    label = def.label or def.cvar,
                    current = current,
                    recommended = recommended,
                    matches = current == recommended,
                }
            end
        end

        if #entries > 0 then
            groups[#groups + 1] = {
                key = category.key,
                name = category.name,
                entries = entries,
            }
        end
    end

    return groups
end

function Module:IsCVarDifferent(cvarName)
    local def = CVAR_BY_NAME[cvarName]
    if not def then
        return false
    end

    local current = GetCVarValue(cvarName)
    return current ~= tostring(def.recommended)
end

function Module:ApplyCVar(cvarName)
    local def = CVAR_BY_NAME[cvarName]
    if not def then
        return false
    end

    local recommendedValue = tostring(def.recommended)
    if not self:IsCVarDifferent(cvarName) then
        return true
    end

    SaveBackupIfMissing(cvarName)
    return SetCVarValue(cvarName, recommendedValue)
end

function Module:HasBackup(cvarName)
    return GetBackupDB()[cvarName] ~= nil
end

function Module:RevertCVar(cvarName)
    local backup = GetBackupDB()
    local previous = backup[cvarName]
    if previous == nil then
        return false
    end

    if SetCVarValue(cvarName, tostring(previous)) then
        backup[cvarName] = nil
        return true
    end

    return false
end

function Module:HasAnyBackup()
    local backup = GetBackupDB()
    for _ in pairs(backup) do
        return true
    end
    return false
end

function Module:RestoreAll()
    local backup = GetBackupDB()
    local restored = 0
    local failed = 0

    for cvarName, previous in pairs(backup) do
        if SetCVarValue(cvarName, tostring(previous)) then
            backup[cvarName] = nil
            restored = restored + 1
        else
            failed = failed + 1
        end
    end

    return restored, failed
end

function Module:ApplyAll()
    local updated = 0
    local failed = 0

    for _, def in ipairs(FPS_CVAR_DEFS) do
        local cvarName = def.cvar
        if self:IsCVarDifferent(cvarName) then
            if self:ApplyCVar(cvarName) then
                updated = updated + 1
            else
                failed = failed + 1
            end
        end
    end

    return updated, failed
end
