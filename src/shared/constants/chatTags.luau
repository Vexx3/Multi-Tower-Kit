--[[
	Chat tags — colored prefixes shown before player names in chat.

	## HOW TO ADD A NEW TAG

	1. Define the tag in TAGS with a display text and color:
	   `MyTag = { Text = "[MyTag]", Color = Color3.fromRGB(R, G, B) }`

	2. Assign it to players using ONE of these methods:

	   a) BY USER ID — always shows for that specific player:
	      `[123456789] = "MyTag"` in USER_TAGS

	   b) BY GAMEPASS — shows for anyone who owns the gamepass:
	      `[GAMEPASS_ID] = "MyTag"` in GAMEPASS_TAGS

	   c) BY GROUP RANK — shows for group members at specific ranks:
	      `{ GroupId = GROUP_ID, Roles = { [255] = "MyTag" } }` in GROUP_TAGS

	## PRIORITY ORDER

	If someone qualifies for multiple tags, they get the first match in this order:
	  1. USER_TAGS (highest priority)
	  2. GAMEPASS_TAGS
	  3. GROUP_TAGS (lowest priority)
]]

local Types = require("../types")

local ChatTags: Types.ChatTagsConfig = {
	-- Step 1: Define your tags here (name, display text, color)
	TAGS = {
		Owner = { Text = "[Owner]", Color = Color3.fromRGB(255, 215, 0) },
		Administrator = { Text = "[Admin]", Color = Color3.fromRGB(255, 85, 85) },
		Developer = { Text = "[Developer]", Color = Color3.fromRGB(85, 170, 255) },
		Moderator = { Text = "[Moderator]", Color = Color3.fromRGB(170, 85, 255) },
		["Verified Builder"] = { Text = "[Verified Builder]", Color = Color3.fromRGB(85, 255, 85) },
		Member = { Text = "[Member]", Color = Color3.fromRGB(31, 34, 255) },
		VIP = { Text = "[VIP]", Color = Color3.fromRGB(255, 255, 0) },
	},

	-- Step 2a: Assign tags to specific users by UserId
	USER_TAGS = {
		[949649253] = "Owner",
		-- [YOUR_USER_ID] = "Owner",
	},

	-- Step 2b: Assign tags to gamepass owners
	GAMEPASS_TAGS = {
		-- [264906725] = "VIP",
	},

	-- Step 2c: Assign tags by Roblox group rank
	GROUP_TAGS = {
		-- { GroupId = 4777338, Roles = { [255] = "Owner", [250] = "Administrator" } },
	},
}

return ChatTags
