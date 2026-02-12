--[[
	Client-side configuration for Multi-Tower Kit.
]]

local Types = require("../shared/types")

local Config: Types.ClientConfig = {
	--== Win Message Templates ==--

	-- Win announcement format.
	winMessage = "{PlayerName} has beaten {EndingName} in {Time}",

	-- All-jumps win announcement format.
	winMessageAj = "{PlayerName} has all-jumped {EndingName} in {Time}",

	-- Boost usage display format. Empty string disables boost display.
	winMessageBoostsUsed = "\nUsed: {BoostList}",

	--== Chat System ==--

	-- Chat channel for system messages.
	chatChannel = "RBXSystem",

	-- Normal system message font settings.
	chatFontFace = "SourceSansBold",
	chatFontSize = 18,

	-- Fancy system message font settings (for special difficulties).
	chatFancyFontFace = "Fantasy",
	chatFancyFontSize = 22,
}

return Config
