-- Configuration for realms, areas, and towers.

local Types = require("../Types")

local RealmInfo: Types.Realms = {
	World1 = {
		["Ring 1"] = {
			title = "Limbo",
			emblem = "rbxassetid://110375453605989",
			placeId = 0,

			towers = {
				ETV5 = { name = "Example Tower V5", badgeId = 0, rating = 1, numDifficulty = 0.00 },
				ETV6 = { name = "Example Tower V6", badgeId = 0, rating = 8, numDifficulty = 0.01 },
				ToCAP = { name = "Tower of Climbing A Pillar", badgeId = 0, rating = 8, numDifficulty = 0.34 },
				ToDIM = { name = "Tower of Diving Into Madness", badgeId = 0, rating = 6, numDifficulty = 0.45 },
				ToMD = { name = "Tower of Mechanical Disarray", badgeId = 0, rating = 7, numDifficulty = 0.56 },
				ToNC = { name = "Tower of No Context", badgeId = 0, rating = 6, numDifficulty = 0.38 },
				ToUC = { name = "Tower of Ultra Cool", badgeId = 0, rating = 2, numDifficulty = 0.26 },
				ToVP = { name = "Tower of Vela Pulsar", badgeId = 0, rating = 5, numDifficulty = 0.55 },
				TSR = { name = "Tower Storage Rush", badgeId = 0, rating = 7, numDifficulty = 0.75, rush = true },
				ETR = { name = "Example Tower Rush", badgeId = 0, rating = 8, numDifficulty = 0.37, rush = true },
			},
			requirements = {
				points = 22,
				difficultyLocks = {
					{ rating = 4, count = 3 }, -- Beat 3 Difficult Difficulty Towers+
					{ rating = 5, count = 1 }, -- Beat 1 Challenging Difficulty Tower+
				},
			},
		},
	},
}

return RealmInfo
