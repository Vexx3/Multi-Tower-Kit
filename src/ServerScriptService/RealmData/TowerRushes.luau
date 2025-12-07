-- A config module containing every tower rush in this realm.
-- More info in the manual @ 2.3.1 - Adding a tower rush.

return {
	ExampleTowerRush = {
		BadgeID = 0,
		Title = "Example Tower Rush",
		Difficulty = "Medium",
		WinroomMarker = "",
		Towers = {
			"ETV5",
			"ETV6",
		},
	},
	
	ExampleTowerRush2 = {
		BadgeID = 0,
		Title = "Example Tower Rush 2",
		Difficulty = "Insane",
		WinroomMarker = "",
		Towers = table.create(100, "ETV5")
	}
}
