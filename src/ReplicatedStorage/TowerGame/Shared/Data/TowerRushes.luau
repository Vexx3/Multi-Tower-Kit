--[[
	Tower rush configurations (multi-tower challenges).
]]

local Types = require("../Types")

type TowerRush = Types.TowerRush

local TowerRushes: Types.Dictionary<TowerRush> = {
	ETR = {
		winroomMarker = "WinroomSpawn",
		towers = { "ETV5", "ETV6" },
		noBoosts = false,
	},

	TSR = {
		winroomMarker = "WinroomSpawn",
		towers = { "ToUC", "ToVP", "ToNC", "ToDIM", "ToMD" },
		noBoosts = true,
	},
}

return TowerRushes
