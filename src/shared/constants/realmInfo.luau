--[[
	Realms, rings, and tower definitions for UI/progression.

	## HOW TO ADD YOUR OWN TOWER

	1. Build your tower in workspace.Towers as a Folder or Model.
	   The folder's NAME is the tower's ACRONYM (e.g., "ToH" for "Tower of Hell").

	2. Inside the tower folder, you need AT MINIMUM:
	   - A `SpawnLocation` (BasePart) — where players teleport when entering
	   - A `WinPad` (BasePart) — what players touch to win

	3. Optional items inside the tower folder:
	   - `Checkpoints/` (Folder) — numbered parts ("1", "2", "3"...) for anti-cheat
	   - `ClientSidedObjects/` (Folder) — visual effects only the player sees
	   - `Configuration` (Folder) — with a "MinimumTime" NumberValue attribute

	4. Add an entry to the `towers` table below with:
	   - Key = your tower's acronym (must match the workspace folder name)
	   - name = display name shown to players
	   - badgeId = Roblox badge ID to award on completion (0 = no badge)
	   - rating = difficulty tier (1=Easy, 2=Medium, ... 14=Nil — see difficulties.luau)
	   - numDifficulty = sub-tier placement (0.00=Baseline to 0.99=Peak)
	   - rush = true (ONLY if this entry is a tower rush, not a regular tower)

	## DIFFICULTY RATINGS QUICK REFERENCE

	  1 = Easy         5 = Challenging    9 = Extreme       13 = Unreal
	  2 = Medium       6 = Intense       10 = Terrifying    14 = Nil
	  3 = Hard         7 = Remorseless   11 = Catastrophic
	  4 = Difficult    8 = Insane        12 = Horrific

	## REQUIREMENTS (optional)

	You can gate a ring behind progression:
	  points = minimum total tower points needed
	  difficultyLocks = list of { rating, count } — e.g., "beat 3 Difficult towers"
]]

local Types = require("../types")

local RealmInfo: Types.Realms = {
	-- A "World" is a top-level grouping (your game can have multiple worlds).
	World1 = {
		-- A "Ring" is a section within a world, containing towers.
		["Ring 1"] = {
			title = "Limbo", -- Display name for this ring
			emblem = "rbxassetid://110375453605989", -- Icon shown in UI
			placeId = 0, -- 0 = same server, or a place ID for teleporting

			-- Each key MUST match the folder name in workspace.Towers
			towers = {
				-- Simple tower: just name, badge, and difficulty
				ETV5 = { name = "Example Tower V5", badgeId = 0, rating = 1, numDifficulty = 0.00 },
				ETV6 = { name = "Example Tower V6", badgeId = 0, rating = 8, numDifficulty = 0.01 },

				-- More tower examples
				ToCAP = { name = "Tower of Climbing A Pillar", badgeId = 0, rating = 8, numDifficulty = 0.34 },
				ToDIM = { name = "Tower of Diving Into Madness", badgeId = 0, rating = 6, numDifficulty = 0.45 },
				ToMD = { name = "Tower of Mechanical Disarray", badgeId = 0, rating = 7, numDifficulty = 0.56 },
				ToNC = { name = "Tower of No Context", badgeId = 0, rating = 6, numDifficulty = 0.38 },
				ToUC = { name = "Tower of Ultra Cool", badgeId = 0, rating = 2, numDifficulty = 0.26 },
				ToVP = { name = "Tower of Vela Pulsar", badgeId = 0, rating = 5, numDifficulty = 0.55 },

				-- Tower Rush entries — these use `rush = true` and must also have
				-- a matching entry in `towerRushes.luau`
				TSR = {
					name = "Tower Storage Rush",
					badgeId = 0,
					rating = 7,
					numDifficulty = 0.75,
					rush = true, -- marks this as a rush, not a solo tower
				},
				ETR = {
					name = "Example Tower Rush",
					badgeId = 0,
					rating = 8,
					numDifficulty = 0.37,
					rush = true,
				},
			},

			-- Optional: lock this ring behind progression
			requirements = {
				points = 22, -- total tower points needed to unlock
				difficultyLocks = {
					{ rating = 4, count = 3 }, -- beat 3 towers rated Difficult or higher
					{ rating = 5, count = 1 }, -- beat 1 tower rated Challenging or higher
				},
			},
		},
	},
}

return RealmInfo
