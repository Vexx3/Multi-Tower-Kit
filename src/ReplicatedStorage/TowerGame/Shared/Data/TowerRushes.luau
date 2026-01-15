-- Configures tower rushes for the current realm.

return {
	ETR = {
		winroomMarker = "WinroomSpawn",
		towers = {
			"ETV5",
			"ETV6",
		},
		noBoosts = false,
	},

	TSR = {
		winroomMarker = "WinroomSpawn",
		towers = {
			"ToUC",
			"ToVP",
			"ToNC",
			"ToDIM",
			"ToMD",
		},
		noBoosts = true,
	},

	ETR2 = {
		winroomMarker = "SCWinroom",
		towers = table.create(100, "ETV5"),
		noBoosts = false,
	},
}
