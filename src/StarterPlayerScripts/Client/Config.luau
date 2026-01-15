--== Multi-Tower Kit Client Config ==--

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.TowerGame.Shared.Types)

local Config: Types.ClientConfig = {
	-- What does the win announcement look like?
	winMessage = "{PlayerName} has beaten {EndingName} in {Time}",

	-- What does the all-jump win announcement look like?
	winMessageAj = "{PlayerName} has all-jumped {EndingName} in {Time}",

	-- How will it display what boosts the player used?
	-- Setting this to an empty string effectively disables showing boosts used
	winMessageBoostsUsed = "\nUsed: {BoostList}",

	--== CHAT SYSTEM CONFIG==--

	-- The chat channel to use for system messages
	chatChannel = "RBXSystem",

	-- The font to use for normal system messages
	chatFontFace = "SourceSansBold",
	chatFontSize = 18,

	-- The font to use for fancy system messages
	chatFancyFontFace = "Fantasy",
	chatFancyFontSize = 22,
}

return Config
