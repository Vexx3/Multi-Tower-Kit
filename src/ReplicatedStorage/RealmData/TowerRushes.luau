-- Licensed under the MIT License
-- Original Copyright (c) 2023 fanofpixels
-- Modifications Copyright (c) 2025 Zylx

-- A config module containing every tower rush in this realm.
-- More info in the manual @ 2.3.1 - Adding a tower rush.

return table.freeze{
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
}
