-- @zylx 2025-12-6
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local MTK = require("../../MTK")
local args = require(Shared.ConchTypes)
local conch = require(ReplicatedStorage.Packages.conch_standalone)

return function()
	conch.register("loadtower", {
		description = "Loads a tower for a player",
		permissions = { "manage-tower" },
		arguments = function()
			return conch.args.player("target", "Player to load the tower for"),
				args.tower_name("tower", "Tower to load")
		end,

		callback = function(target: Player, towerName: string)
			MTK.TowerManager:LoadTower(target.Name, towerName, true)
			conch.log("info", `Loaded tower '{towerName}' for {target.Name}`)
		end,
	})
end
