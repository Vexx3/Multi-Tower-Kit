-- A config module containing every tower rush in this realm.
-- More info: https://vexx3.github.io/MTK-Dev/docs/Configuration#adding-a-tower-rush

return table.freeze({
	ETR = {
		WinroomMarker = "WinroomSpawn",
		Towers = {
			"ETV5",
			"ETV6",
		},
		NoBoosts = false,
	},

	TSR = {
		WinroomMarker = "WinroomSpawn",
		Towers = {
			"ToUC",
			"ToVP",
			"ToNC",
			"ToDIM",
			"ToMD",
			"ToCAP",
		},
		NoBoosts = true,
	},

	ETR2 = {
		WinroomMarker = "SCWinroom",
		Towers = table.create(100, "ETV5"),
		NoBoosts = false,
	},
})
