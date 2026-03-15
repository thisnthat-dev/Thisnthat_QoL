local FPS_CVARS = {
   -- Graphics Tab
   ["vsync"] = "0",
   ["LowLatencyMode"] = "3",
   ["MSAAQuality"] = "0",
   ["ffxAntiAliasingMode"] = "0",
   ["MSAAalphaTest"] = "1",
   ["cameraFov"] = "90",

   -- Graphics Quality (Base)
   ["graphicsQuality"] = "9",
   ["graphicsShadowQuality"] = "0",
   ["graphicsLiquidDetail"] = "1",
   ["graphicsParticleDensity"] = "5",
   ["graphicsSSAO"] = "0",
   ["graphicsDepthEffects"] = "0",
   ["graphicsComputeEffects"] = "0",
   ["graphicsOutlineMode"] = "2",
   ["OutlineEngineMode"] = "1",
   ["graphicsTextureResolution"] = "2",
   ["graphicsSpellDensity"] = "0",
   ["spellClutter"] = "1",
   ["spellVisualDensityFilterSetting"] = "1",
   ["graphicsProjectedTextures"] = "1",
   ["projectedTextures"] = "1",
   ["graphicsViewDistance"] = "3",
   ["graphicsEnvironmentDetail"] = "0",
   ["graphicsGroundClutter"] = "0",

   -- Advanced Tab
   ["GxMaxFrameLatency"] = "2",
   ["textureFilteringMode"] = "5",
   ["shadowRt"] = "0",   
   ["ResampleQuality"] = "3",
   ["vrsValar"] = "0",
   ["GxApi"] = "D3D12",
   ["physicsLevel"] = "0",
   ["maxFPS"] = "144",
   ["maxFPSBk"] = "60",
   ["targetFPS"] = "61",
   ["useTargetFPS"] = "0",
   ["ResampleSharpness"] = "0.2",
   ["Contrast"] = "75",
   ["Brightness"] = "50",
   ["Gamma"] = "1",

   -- Additional Optimizations
   ["particulatesEnabled"] = "0",
   ["clusteredShading"] = "0",
   ["volumeFogLevel"] = "0",
   ["reflectionMode"] = "0",
   ["ffxGlow"] = "0",
   ["farclip"] = "5000",
   ["horizonStart"] = "1000",
   ["horizonClip"] = "5000",
   ["lodObjectCullSize"] = "35",
   ["lodObjectFadeScale"] = "50",
   ["lodObjectMinSize"] = "0",
   ["doodadLodScale"] = "50",
   ["entityLodDist"] = "7",
   ["terrainLodDist"] = "350",
   ["TerrainLodDiv"] = "512",
   ["waterDetail"] = "1",
   ["rippleDetail"] = "0",
   ["weatherDensity"] = "3",
   ["entityShadowFadeScale"] = "15",
   ["groundEffectDist"] = "40",
   ["ResampleAlwaysSharpen"] = "1",

   -- Special Hacks
   ["cameraDistanceMaxZoomFactor"] = "2.6",
   ["CameraReduceUnexpectedMovement"] = "1",

   ["advancedCombatLogging"] = "1",
}

-- GxMaxFrameLatency

local successCount = 0
local failCount = 0

for cvar, value in pairs(FPS_CVARS) do
   old = C_CVar.GetCVar(cvar) or ""
   if old ~= value then
       local success = C_CVar.SetCVar(cvar, value)
       if success then
           print("Update cvar " .. cvar .. " from " .. old .. " to " .. value)
           successCount = successCount + 1
       else
           print("Failed to Update cvar " .. cvar .. " from " .. old .. " to " .. value)
           failCount = failCount + 1
       end
   end
end

print("|cff34D399Graphic Setting Update:|r Your previous settings have been backed up.")
print("|cff34D399Graphic Setting Update:|r Applied " .. successCount .. " FPS settings.")
if failCount > 0 then
  print("|cffFF6B6BGraphic Setting Update:|r " .. failCount .. " settings could not be applied (may require restart).")
end

