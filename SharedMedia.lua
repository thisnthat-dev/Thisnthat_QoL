local LSM = LibStub("LibSharedMedia-3.0")

local MediaType_BACKGROUND = LSM.MediaType.BACKGROUND
local MediaType_BORDER     = LSM.MediaType.BORDER
local MediaType_FONT       = LSM.MediaType.FONT
local MediaType_STATUSBAR  = LSM.MediaType.STATUSBAR
local MediaType_SOUND      = LSM.MediaType.SOUND

local SOUND_PATH     = [[Interface\Addons\Thisnthat_QoL\Media\Sounds\]]
local TEXTURE_PATH   = [[Interface\Addons\Thisnthat_QoL\Media\Textures\Arrows\]]
local STATUSBAR_PATH = [[Interface\Addons\Thisnthat_QoL\Media\Textures\Statusbar\]]
local BORDER_PATH    = [[Interface\Addons\Thisnthat_QoL\Media\Textures\Border\]]
local FONT_PATH      = [[Interface\Addons\Thisnthat_QoL\Media\Fonts\]]

-- -----
--   STATUSBAR
-- -----
LSM:Register(MediaType_STATUSBAR, "Thisnthat", STATUSBAR_PATH .. "Thisnthat.tga")
LSM:Register(MediaType_FONT, "Thisnthat", FONT_PATH .. "Thisnthat.ttf")
LSM:Register(MediaType_FONT, "Fira", FONT_PATH .. "FiraMono-Medium.ttf")


LSM:Register(MediaType_BORDER, "Thisnthat_1px", BORDER_PATH .. "thisnthat_1px.tga")
LSM:Register(MediaType_BORDER, "Thisnthat_2px", BORDER_PATH .. "thisnthat_2px.tga")
LSM:Register(MediaType_BORDER, "Thisnthat_W_2px", BORDER_PATH .. "thisnthat_w_2px.tga")


LSM:Register(MediaType_FONT, "|cFF00FF00Thisnthat - Expressway|r", FONT_PATH .. "Expressway.ttf")

LSM:Register(MediaType_BACKGROUND, "|cFF00FF00Thisnthat - EthricArrow|r",    TEXTURE_PATH .. "EthricArrow")
LSM:Register(MediaType_BACKGROUND, "|cFF00FF00Thisnthat - EthricArrow2|r",   TEXTURE_PATH .. "EthricArrow2")
LSM:Register(MediaType_BACKGROUND, "|cFF00FF00Thisnthat - EthricArrow3|r",   TEXTURE_PATH .. "EthricArrow3")
LSM:Register(MediaType_BACKGROUND, "|cFF00FF00Thisnthat - EthricArrow4|r",   TEXTURE_PATH .. "EthricArrow4")
LSM:Register(MediaType_BACKGROUND, "|cFF00FF00Thisnthat - EthricArrow5|r",   TEXTURE_PATH .. "EthricArrow5")
LSM:Register(MediaType_BACKGROUND, "|cFF00FF00Thisnthat - EthricArrow6|r",   TEXTURE_PATH .. "EthricArrow6")
LSM:Register(MediaType_BACKGROUND, "|cFF00FF00Thisnthat - EthricArrow7|r",   TEXTURE_PATH .. "EthricArrow7")
LSM:Register(MediaType_BACKGROUND, "|cFF00FF00Thisnthat - EthricArrow8|r",   TEXTURE_PATH .. "EthricArrow8")
LSM:Register(MediaType_BACKGROUND, "|cFF00FF00Thisnthat - EthricArrow9|r",   TEXTURE_PATH .. "EthricArrow9")
LSM:Register(MediaType_BACKGROUND, "|cFF00FF00Thisnthat - EthricArrow10|r",  TEXTURE_PATH .. "EthricArrow10")

LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Apex|r",             SOUND_PATH .. "apex.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Proc|r",             SOUND_PATH .. "proc.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Tank Hit|r",         SOUND_PATH .. "tankhit.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Dispel|r",           SOUND_PATH .. "dispel.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Cheat Death|r",      SOUND_PATH .. "cheatdeath.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Use|r",              SOUND_PATH .. "use.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Ravage|r",           SOUND_PATH .. "ravage.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - DRW|r",              SOUND_PATH .. "drw.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Battle Stance|r",    SOUND_PATH .. "battlestance.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Rebuff|r",           SOUND_PATH .. "rebuff.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Dwarf|r",            SOUND_PATH .. "dwarf.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Cheat Death Back|r", SOUND_PATH .. "cheatdeathback.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Bloodlust|r",        SOUND_PATH .. "bloodlust.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - External|r",         SOUND_PATH .. "external.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Noob|r",             SOUND_PATH .. "noob.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Bear Form|r",        SOUND_PATH .. "bearform.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Wings|r",            SOUND_PATH .. "wings.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Wings Out|r",        SOUND_PATH .. "wingsout.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Bubble|r",           SOUND_PATH .. "bubble.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Spellward|r",        SOUND_PATH .. "spellward.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Bubble Out|r",       SOUND_PATH .. "bubbleout.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Spellward Out|r",    SOUND_PATH .. "spellwardout.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Potion|r",           SOUND_PATH .. "potion.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Soak|r",             SOUND_PATH .. "soak.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Heal|r",             SOUND_PATH .. "heal.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Watch|r",            SOUND_PATH .. "watch.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Run|r",              SOUND_PATH .. "run.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Move|r",             SOUND_PATH .. "move.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Dodge|r",            SOUND_PATH .. "dodge.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Dispell|r",          SOUND_PATH .. "dispell.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Ress|r",             SOUND_PATH .. "ress.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Dead|r",             SOUND_PATH .. "dead.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Add|r",              SOUND_PATH .. "add.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Adds|r",             SOUND_PATH .. "adds.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Intermission|r",     SOUND_PATH .. "intermission.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Damage Amp|r",       SOUND_PATH .. "damageamp.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Kick|r",             SOUND_PATH .. "kick.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Jump|r",             SOUND_PATH .. "jump.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Bait|r",             SOUND_PATH .. "bait.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Knock|r",            SOUND_PATH .. "knock.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Hide|r",             SOUND_PATH .. "hide.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Clean|r",            SOUND_PATH .. "clean.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Debuffs|r",          SOUND_PATH .. "debuffs.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - AoE|r",              SOUND_PATH .. "aoe.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Frontal|r",          SOUND_PATH .. "frontal.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Spread|r",           SOUND_PATH .. "spread.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Shields|r",          SOUND_PATH .. "shields.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Kite|r",             SOUND_PATH .. "kite.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Buff|r",             SOUND_PATH .. "buff.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Debuff|r",           SOUND_PATH .. "debuff.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Targeted|r",         SOUND_PATH .. "targeted.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - On You|r",           SOUND_PATH .. "onyou.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Fixate|r",           SOUND_PATH .. "fixate.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Time Spiral|r",      SOUND_PATH .. "timespiral.ogg")
LSM:Register(MediaType_SOUND, "|cFF00FF00Thisnthat - Remove|r",           SOUND_PATH .. "remove.ogg")