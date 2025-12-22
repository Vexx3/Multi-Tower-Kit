return {
	-- Tag definitions: name -> { Text, Color }
	TAGS = {
		Owner = { Text = "[Owner]", Color = "#FFD700" },
		Administrator = { Text = "[Admin]", Color = "#FF5555" },
		Developer = { Text = "[Developer]", Color = "#55AAFF" },
		Moderator = { Text = "[Moderator]", Color = "#AA55FF" },
		["Verified Builder"] = { Text = "[Verified Builder]", Color = "#55FF55" },
		Member = { Text = "[Member]", Color = "#1f22ff" },
	},

	-- UserId -> TagName
	USER_TAGS = {
		[949649253] = "Owner",
		-- [3471772640] = "Administrator",
	},

	-- Group-based tags: { GroupId, Roles = { [RankId] = "TagName" } }
	GROUP_TAGS = {
		{
			-- GroupId = 4777338,
			-- Roles = {
			-- 	[255] = "Owner",
			-- 	[250] = "Administrator",
			-- 	[201] = "Developer",
			-- 	[200] = "Moderator",
			-- 	[50] = "Verified Builder",
			-- 	[1] = "Member",
			-- },
		},
	},
}
