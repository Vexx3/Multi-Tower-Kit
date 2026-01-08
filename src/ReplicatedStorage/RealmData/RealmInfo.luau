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
    - PlaceId: The Roblox Place ID for teleportation.

	[RATING REFERENCE]
    [1] Easy          [2] Medium        [3] Hard         [4] Difficult
    [5] Challenging   [6] Intense       [7] Remorseless  [8] Insane
    [9] Extreme       [10] Terrifying   [11] Catastrophic [12] Horrific
    [13] Unreal       [14] nil
]]

return {
	World1 = {
		["Ring 1: Limbo"] = {
			Towers = {
				ETV5 = {  Name = "Example Tower V5", BadgeID = 0, Rating = 1, NumDifficulty = 0.00 },
				ETV6 = { Name = "Example Tower V6", BadgeID = 0, Rating = 8, NumDifficulty = 0.00 },
				ToCAP = { Name = "Tower of Climbing A Pillar", BadgeID = 0, Rating = 8, NumDifficulty = 0.00 },
				ToDIM = { Name = "Tower of Diving Into Madness", BadgeID = 0, Rating = 6, NumDifficulty = 0.52 },
				ToMD = { Name = "Tower of Mechanical Disarray", BadgeID = 0, Rating = 7, NumDifficulty = 0.00 },
				ToNC = { Name = "Tower of No Context", BadgeID = 0, Rating = 6, NumDifficulty = 0.00 },
				ToUC = { Name = "Tower of Ultra Cool", BadgeID = 0, Rating = 2, NumDifficulty = 0.00 },
				ToVP = { Name = "Tower of Vela Pulsar", BadgeID = 0, Rating = 5, NumDifficulty = 0.00 },
			},
			Requirements = {
				Points = 22,
				DifficultyLocks = {
					{ Rating = 4, Count = 3 }, -- Beat 3 Difficult Difficulty Towers+
					{ Rating = 5, Count = 1 }, -- Beat 1 Challenging Difficulty Tower+
				},
			},
			PlaceId = 0,
		},
	},

	-- World2 = {
	-- 	["Zone 1: Sea"] = {
	-- 		Towers = {
	-- 			ToU = { Name = "Tower of Unreal", BadgeID = 0, Rating = 13, NumDifficulty = 0.95 },
	-- 		},
	-- 		Requirements = {
	-- 			Points = 7,
	-- 			DifficultyLocks = {
	-- 				{ Rating = 2, Count = 1 }, -- Beat 1 Medium Difficulty Tower+
	-- 			},
	-- 		},
	-- 		PlaceId = 0,
	-- 	},
	-- },
}
