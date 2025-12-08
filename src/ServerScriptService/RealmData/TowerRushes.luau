-- A config module containing every tower rush in this realm.
-- More info in the manual @ 2.3.1 - Adding a tower rush.

return {
	ExampleTowerRush = {
		BadgeID = 0,
		Title = "Example Tower Rush",
		Difficulty = "Medium",
		WinroomMarker = "WinroomSpawn",
		Towers = {
			"ETV5",
			"ETV6",
		},
	},

	TowersStorageRush = {
		BadgeID = 0,
		Title = "Towers Storage Rush",
		Difficulty = "Remorseless",
		WinroomMarker = "WinroomSpawn",
		Towers = {
			"ToSaME",
			"ToUC",
			"ToQP",
			"ToNC",
			"ToCAP",
		},
	},

	ExampleTowerRush2 = {
		BadgeID = 0,
		Title = "Example Tower Rush 2",
		Difficulty = "Catastrophic",
		WinroomMarker = "SCWinroom",
		Towers = table.create(1000, "ETV5"),
	},
}
