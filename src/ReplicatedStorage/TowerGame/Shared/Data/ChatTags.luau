--[[
	Chat tags (prefixes) shown before player names.
]]

local Types = require("../Types")

local ChatTags: Types.ChatTagsConfig = {
	-- Available tags
	TAGS = {
		Owner = { Text = "[Owner]", Color = Color3.fromRGB(255, 215, 0) },
		Administrator = { Text = "[Admin]", Color = Color3.fromRGB(255, 85, 85) },
		Developer = { Text = "[Developer]", Color = Color3.fromRGB(85, 170, 255) },
		Moderator = { Text = "[Moderator]", Color = Color3.fromRGB(170, 85, 255) },
		["Verified Builder"] = { Text = "[Verified Builder]", Color = Color3.fromRGB(85, 255, 85) },
		Member = { Text = "[Member]", Color = Color3.fromRGB(31, 34, 255) },
		VIP = { Text = "[VIP]", Color = Color3.fromRGB(255, 255, 0) },
	},

	-- [UserId] = "TagName"
	USER_TAGS = {
		[949649253] = "Owner",
	},

	-- [GamepassId] = "TagName"
	GAMEPASS_TAGS = {
		-- [264906725] = "VIP",
	},

	-- { GroupId = id, Roles = { [rank] = "TagName" } }
	GROUP_TAGS = {
		-- { GroupId = 4777338, Roles = { [255] = "Owner", [250] = "Administrator" } },
	},
}

return ChatTags
