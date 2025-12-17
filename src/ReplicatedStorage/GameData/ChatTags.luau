-- Licensed under the MIT License
-- Copyright (c) 2025 Zylx

return {
	-- Tag definitions: name -> { Text, Color }
	TAGS = {
		Owner = { Text = "[Owner]", Color = "#FFD700" },
		Administrator = { Text = "[Admin]", Color = "#FF5555" },
		Developer = { Text = "[Dev]", Color = "#55AAFF" },
		Moderator = { Text = "[Mod]", Color = "#AA55FF" },
		["Verified Builder"] = { Text = "[Builder]", Color = "#55FF55" },
	},

	-- UserId -> TagName
	USER_TAGS = {
		[949649253] = "Owner",
		-- [3471772640] = "Administrator",
	},

	-- Group-based tags: { GroupId, Roles = { [RankId] = "TagName" } }
	GROUP_TAGS = {
		-- {
		-- 	GroupId = 123456,
		-- 	Roles = {
		-- 		[255] = "Owner",
		-- 		[254] = "Administrator",
		-- 		[200] = "Developer",
		-- 		[100] = "Moderator",
		-- 		[50] = "Verified Builder",
		-- 	},
		-- },
	},
}
