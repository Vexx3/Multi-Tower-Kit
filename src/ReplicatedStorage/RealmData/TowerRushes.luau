-- A config module containing every tower rush in this realm.
-- More info: https://vexx3.github.io/MTK-Dev/docs/Configuration#adding-a-tower-rush

return table.freeze({
	ETR = {
		BadgeID = 0,
		Title = "Example Tower Rush",
		Difficulty = "Medium",
		WinroomMarker = "WinroomSpawn",
		Towers = {
			"ETV5",
			"ETV6",
		},
		NoBoostItems = false,
	},

	TSR = {
		BadgeID = 0,
		Title = "Tower Storage Rush",
		Difficulty = "Remorseless",
		WinroomMarker = "WinroomSpawn",
		Towers = {
			"ToUC",
			"ToVP",
			"ToNC",
			"ToDIM",
			"ToMD",
			"ToCAP",
		},
		NoBoostItems = true,
	},

	ETR2 = {
		BadgeID = 0,
		Title = "Example Tower Rush 2",
		Difficulty = "Catastrophic",
		WinroomMarker = "SCWinroom",
		Towers = table.create(100, "ETV5"),
		NoBoostItems = false,
	},
})
