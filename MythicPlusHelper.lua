local addonName, addon = ...

addon.MythicPlusHelper = addon.MythicPlusHelper or {}
T = addon.MythicPlusHelper

local LSM = LibStub("LibSharedMedia-3.0")

local colors = {
   Base = "f3f3f3",
   Champion = "0070dd",
   Hero = "a335ee",
   Myth = "ff8000",
}

local ilevelRange = {
   Champion = {246, 250, 253, 256, 259, 263},
   Hero = {259, 263, 266, 269, 272, 276 },
   Myth = {272, 276, 279, 282, 285, 289 },
}

local track = {
   Champion = {short = "C", name = "Champion", color = colors.Champion, range = ilevelRange.Champion},
   Hero = {short = "H", name = "Hero", color = colors.Hero, range = ilevelRange.Hero},
   Myth = {short = "M", name = "Myth", color = colors.Myth, range = ilevelRange.Myth},
}

local KeyRewards = {
   [1]  = { loot = { track = track.Champion, value = 246}, vault = {track = track.Champion, value = 256 }, crests = {track = track.Champion, value = 8}},
   [2]  = { loot = { track = track.Champion, value = 250}, vault = {track = track.Champion, value = 259 }, crests = {track = track.Champion, value = 10}},
   [3]  = { loot = { track = track.Champion, value = 250}, vault = {track = track.Champion, value = 259 }, crests = {track = track.Champion, value = 12}},
   [4]  = { loot = { track = track.Champion, value = 253}, vault = {track = track.Hero,     value = 263 }, crests = {track = track.Hero,     value = 10}},
   [5]  = { loot = { track = track.Champion, value = 256}, vault = {track = track.Hero,     value = 263 }, crests = {track = track.Hero,     value = 12}},
   [6]  = { loot = { track = track.Champion, value = 259}, vault = {track = track.Hero,     value = 266 }, crests = {track = track.Hero,     value = 14}},
   [7]  = { loot = { track = track.Champion, value = 259}, vault = {track = track.Hero,     value = 269 }, crests = {track = track.Hero,     value = 16}},
   [8]  = { loot = { track = track.Champion, value = 263}, vault = {track = track.Hero,     value = 269 }, crests = {track = track.Hero,     value = 18}},
   [9]  = { loot = { track = track.Champion, value = 263}, vault = {track = track.Hero,     value = 269 }, crests = {track = track.Myth,     value = 10}},
   [10] = { loot = { track = track.Hero,     value = 266}, vault = {track = track.Myth,     value = 272 }, crests = {track = track.Myth,     value = 12}},
   [11] = { loot = { track = track.Hero,     value = 266}, vault = {track = track.Myth,     value = 272 }, crests = {track = track.Myth,     value = 14}},
   [12] = { loot = { track = track.Hero,     value = 266}, vault = {track = track.Myth,     value = 272 }, crests = {track = track.Myth,     value = 16}},
}

function addon.MythicPlusHelper.GetRank(keyReward)
   for i = 1,6 do
      if keyReward.value == keyReward.track.range[i] then
         return i
      end
   end

   return 0
end

function addon.MythicPlusHelper.BuildRewardString()
   local rewardText = ""
   local champtionLabel = "|cff" .. track.Champion.color .. track.Champion.name .. "|r"
   local heroLabel = "|cff" .. track.Hero.color .. track.Hero.name .. "|r"
   local mythLabel = "|cff" .. track.Myth.color .. track.Myth.name .. "|r"
   rewardText = format("%s, %s, %s\n\n", champtionLabel, heroLabel, mythLabel)
   rewardText = rewardText .. format("%10s %12s %9s", "Loot", "Vault", "Crest")

   for i = 2,12 do
      local key = i
      local keyReward = KeyRewards[key]

      local lootRank = addon.MythicPlusHelper.GetRank(keyReward.loot)
      local vaultRank = addon.MythicPlusHelper.GetRank(keyReward.vault)

      local lootText = "|cff" .. keyReward.loot.track.color .. keyReward.loot.value .. " (" .. lootRank .. "/" .. #keyReward.loot.track.range .. ")|r"
      local vaultText = "|cff" .. keyReward.vault.track.color .. keyReward.vault.value .. " (" .. vaultRank .. "/"..  #keyReward.vault.track.range ..")|r"
      local crestCountText = "|cff" .. keyReward.crests.track.color .. keyReward.crests.value .. " (" ..  keyReward.crests.value - 4 .. ")|r"
      --local crestText = "|cff" .. keyReward.crests.track.color .. keyReward.crests.track.name .. "|r"

      rewardText = rewardText .. format("\n|cff%s%2d:|r %-18s | %-18s | %s", colors.Base, key, lootText, vaultText, crestCountText)
   end

   return rewardText
end


function addon.MythicPlusHelper.initialize()
    local parentFrame = PVEFrame

    addon.MythicPlusHelper.frame = CreateFrame("Frame", "MPRFrame", parentFrame, "BackdropTemplate")
    addon.MythicPlusHelper.frame:SetBackdrop({
    bgFile = "Interface\\Addons\\SharedMedia_Naowh\\statusbar\\Armory",
        edgeFile = "Interface\\Addons\\SharedMedia_Naowh\\border\\Naowh2",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    addon.MythicPlusHelper.frame:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
    addon.MythicPlusHelper.frame:SetBackdropBorderColor(0.18,0.18,0.18, 1)
    addon.MythicPlusHelper.frame:Show()
    addon.MythicPlusHelper.frame:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMRIGHT", 0, -1)

    local font = LSM:Fetch(LSM.MediaType.FONT, "Fira") or "2002"
    addon.MythicPlusHelper.frameTitle = addon.MythicPlusHelper.frame:CreateFontString(font, "OVERLAY", "GameFontNormalLarge")
    addon.MythicPlusHelper.frameTitle:SetJustifyH("LEFT")
    addon.MythicPlusHelper.frameTitle:SetTextColor(0.95, 0.95, 0.95, 1)
    addon.MythicPlusHelper.frameTitle:SetPoint("TOPLEFT", 6, -8)
    addon.MythicPlusHelper.frameTitle:SetFontHeight(12)
    addon.MythicPlusHelper.frameTitle:SetFont(font, 12)

    local minFrameSize = max(addon.MythicPlusHelper.frameTitle:GetStringWidth() + 12, 100)
    local minFrameHeight = max(addon.MythicPlusHelper.frameTitle:GetStringHeight() + 16, 100)
    addon.MythicPlusHelper.frame:SetSize(minFrameSize, minFrameHeight)

    addon.MythicPlusHelper.frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    addon.MythicPlusHelper.frame:SetScript("OnEvent", function(self, event, unit, _, eventSpellID)
        if event == "PLAYER_ENTERING_WORLD" then
            addon.MythicPlusHelper.UpdateFrameText()
        end
    end)
end

function addon.MythicPlusHelper.UpdateFrameText()
    local text = addon.MythicPlusHelper.BuildRewardString()
    addon.MythicPlusHelper.frameTitle:SetFormattedText(text)

    local minFrameSize = max(addon.MythicPlusHelper.frameTitle:GetStringWidth() + 12, 100)
    local minFrameHeight = max(addon.MythicPlusHelper.frameTitle:GetStringHeight() + 16, 100)
    addon.MythicPlusHelper.frame:SetSize(minFrameSize, minFrameHeight)
end

addon.MythicPlusHelper.initialize()


-- WOW LUA code for testing
-- local LSM = LibStub("LibSharedMedia-3.0")

-- local font = LSM:Fetch(LSM.MediaType.FONT, "thisnthat")

-- local title = T.frameTitle
-- local frame = T.frame

-- title:SetFont(font, 15)

-- local minFrameSize = max(title:GetStringWidth() + 20, 205)
-- local minFrameHeight = max(title:GetStringHeight() + 20, 205)

-- frame:SetSize(minFrameSize, minFrameHeight)