local LSM = LibStub("LibSharedMedia-3.0")

local MediaType_BACKGROUND = LSM.MediaType.BACKGROUND
local MediaType_BORDER = LSM.MediaType.BORDER
local MediaType_FONT = LSM.MediaType.FONT
local MediaType_STATUSBAR = LSM.MediaType.STATUSBAR

-- -----
--   STATUSBAR
-- -----
LSM:Register(MediaType_STATUSBAR, "Thisnthat", [[Interface\Addons\Thisnthat_QoL\Statusbar\Thisnthat.tga]])
LSM:Register(MediaType_FONT, "Thisnthat", [[Interface\Addons\Thisnthat_QoL\Fonts\Thisnthat.ttf]])
LSM:Register(MediaType_FONT, "Fira", [[Interface\Addons\Thisnthat_QoL\Fonts\FiraMono-Medium.ttf]])


LSM:Register(MediaType_BORDER, "Thisnthat_1px", [[Interface\Addons\Thisnthat_QoL\Border\thisnthat_1px.tga]])
LSM:Register(MediaType_BORDER, "Thisnthat_2px", [[Interface\Addons\Thisnthat_QoL\Border\thisnthat_2px.tga]])
LSM:Register(MediaType_BORDER, "Thisnthat_W_2px", [[Interface\Addons\Thisnthat_QoL\Border\thisnthat_w_2px.tga]])