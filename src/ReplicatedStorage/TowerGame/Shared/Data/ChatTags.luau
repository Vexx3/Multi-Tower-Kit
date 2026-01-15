-- Chat tag configuration for player prefixes.
-- Tags can be assigned by UserId, gamepass ownership, or group rank.

local Types = require("../Types")

local ChatTags: Types.ChatTagsConfig = {
	TAGS = {
		Owner = { Text = "[Owner]", Color = Color3.fromRGB(255, 215, 0) },
		Administrator = { Text = "[Admin]", Color = Color3.fromRGB(255, 85, 85) },
		Developer = { Text = "[Developer]", Color = Color3.fromRGB(85, 170, 255) },
		Moderator = { Text = "[Moderator]", Color = Color3.fromRGB(170, 85, 255) },
		["Verified Builder"] = { Text = "[Verified Builder]", Color = Color3.fromRGB(85, 255, 85) },
		Member = { Text = "[Member]", Color = Color3.fromRGB(31, 34, 255) },
		VIP = { Text = "[VIP]", Color = Color3.fromRGB(255, 255, 0) },
	},

	USER_TAGS = {
		[949649253] = "Owner",
	},

	GAMEPASS_TAGS = {
		-- [264906725] = "VIP",
	},

	GROUP_TAGS = {
		-- {
		-- 	GroupId = 4777338,
		-- 	Roles = {
		-- 		[255] = "Owner",
		-- 		[250] = "Administrator",
		-- 		[201] = "Developer",
		-- 		[200] = "Moderator",
		-- 		[50] = "Verified Builder",
		-- 	},
		-- },
	},
}

return ChatTags
