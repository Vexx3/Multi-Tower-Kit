--[[
	Tower rush configurations (multi-tower challenges).

	A "Tower Rush" is a sequence of towers the player must beat
	back-to-back without resetting. Great for competitive challenges!

	## HOW TO ADD A TOWER RUSH

	1. Create a portal in workspace.Portals with a StringValue child
	   named "TowerRush" whose Value matches the key below (e.g., "ETR").

	2. Add an entry here with:
	   - Key = rush acronym (must also be defined in realmInfo.luau with `rush = true`)
	   - winroomMarker = name of a BasePart in workspace.Markers to teleport to on completion
	   - towers = ordered list of tower acronyms the player must complete
	   - noBoosts = true to prohibit boost items during the rush

	3. Make sure every tower acronym in the `towers` list exists in
	   workspace.Towers and is registered in realmInfo.luau.

	## EXAMPLE

	```luau
	MyRush = {
	    winroomMarker = "WinroomSpawn",  -- where to teleport after beating all towers
	    towers = { "ToUC", "ToVP" },     -- play these towers in order
	    noBoosts = false,                 -- allow boost items?
	},
	```
]]

local Types = require("../types")

type TowerRush = Types.TowerRush

local TowerRushes: Types.Dictionary<TowerRush> = {
	-- Example Tower Rush: beat ETV5 then ETV6
	ETR = {
		winroomMarker = "WinroomSpawn", -- marker in workspace.Markers
		towers = { "ETV5", "ETV6" }, -- towers to beat, in order
		noBoosts = false, -- allow boost items
	},

	-- Tower Storage Rush: 5 towers, no boosts allowed
	TSR = {
		winroomMarker = "WinroomSpawn",
		towers = { "ToUC", "ToVP", "ToNC", "ToDIM", "ToMD" },
		noBoosts = true, -- boosts kill the player in this rush
	},
}

return TowerRushes
