--[[
    REALM CONFIGURATION GUIDE
    
    [STRUCTURE]
    World -> ["Area Name"] -> Towers & Requirements
    
    [TOWER FIELDS]
    - Name: The full display name of the tower.
	- BadgeID: The ID of the Badge awarded for beating the tower.
    - Rating: The difficulty ID (1 = Easy, 13 = Unreal).
    - NumDifficulty: Decimal (0.00 = Baseline, 0.99 = Peak).

    [REQUIREMENTS TEMPLATE]
    - Points: Total points required.
    - DifficultyLocks: A list of difficulty-based requirements.
        {Rating = 3, Count = 1} -> "Beat 1 Hard (Rating 3) or higher"
        {Rating = 6, Count = 4} -> "Beat 4 Intense (Rating 6) or higher"
    
    [AREA FIELDS]
    - Towers: Table containing all towers in this area.
    - Requirements: Values needed to enter (Points and DifficultyLocks).
    - PlaceID: The Roblox Place ID for teleportation.
	- Emblem: The Image ID for the Ring/Zone icon (Used in UIs)

	[RATING REFERENCE]
    [1] Easy          [2] Medium        [3] Hard         [4] Difficult
    [5] Challenging   [6] Intense       [7] Remorseless  [8] Insane
    [9] Extreme       [10] Terrifying   [11] Catastrophic [12] Horrific
    [13] Unreal       [14] nil
]]

return {
	World1 = {
		["Ring 1"] = {
			Title = "Limbo",
			Emblem = "rbxassetid://110375453605989",
			PlaceID = 0,

			Towers = {
				ETV5 = { Name = "Example Tower V5", BadgeID = 0, Rating = 1, NumDifficulty = 0.00 },
				ETV6 = { Name = "Example Tower V6", BadgeID = 0, Rating = 8, NumDifficulty = 0.01 },
				ToCAP = { Name = "Tower of Climbing A Pillar", BadgeID = 0, Rating = 8, NumDifficulty = 0.34 },
				ToDIM = { Name = "Tower of Diving Into Madness", BadgeID = 0, Rating = 6, NumDifficulty = 0.45 },
				ToMD = { Name = "Tower of Mechanical Disarray", BadgeID = 0, Rating = 7, NumDifficulty = 0.56 },
				ToNC = { Name = "Tower of No Context", BadgeID = 0, Rating = 6, NumDifficulty = 0.38 },
				ToUC = { Name = "Tower of Ultra Cool", BadgeID = 0, Rating = 2, NumDifficulty = 0.26 },
				ToVP = { Name = "Tower of Vela Pulsar", BadgeID = 0, Rating = 5, NumDifficulty = 0.55 },
				TSR = { Name = "Tower Storage Rush", BadgeID = 0, Rating = 7, NumDifficulty = 0.75, Rush = true },
			},
			Requirements = {
				Points = 22,
				DifficultyLocks = {
					{ Rating = 4, Count = 3 }, -- Beat 3 Difficult Difficulty Towers+
					{ Rating = 5, Count = 1 }, -- Beat 1 Challenging Difficulty Tower+
				},
			},
		},
	},

	-- World2 = {
	-- 	["Zone 1: Sea"] = {
	-- 		Title = "Sea",
	-- 		Emblem = "rbxassetid://0",
	-- 		PlaceID = 0,

	-- 		Towers = {
	-- 			ToU = { Name = "Tower of Unreal", BadgeID = 0, Rating = 13, NumDifficulty = 0.95 },
	-- 		},
	-- 		Requirements = {
	-- 			Points = 7,
	-- 			DifficultyLocks = {
	-- 				{ Rating = 2, Count = 1 }, -- Beat 1 Medium Difficulty Tower+
	-- 			},
	-- 		},
	-- 	},
	-- },
}
