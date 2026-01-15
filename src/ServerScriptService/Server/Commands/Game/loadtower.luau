local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.TowerGame.Shared

local PlayerService = require("../../Services/PlayerService")
local TowerService = require("../../Services/TowerService")
local args = require(Shared.ConchTypes)
local conch = require("@game/ReplicatedStorage/Packages/conch")

return function()
	conch.register("loadtower", {
		description = "Loads a tower for a player",
		permissions = { "manage-tower" },
		arguments = function()
			return conch.args.player("target", "Player to load the tower for"), args.towerName("tower", "Tower to load")
		end,

		callback = function(target: Player, towerName: string)
			local player = PlayerService.getSession(target.Name)
			if player then
				TowerService.loadTower(player, towerName, true)
				conch.log("info", `Loaded tower '{towerName}' for {target.Name}`)
			else
				conch.log("error", `Could not find session for player {target.Name}`)
			end
		end,
	})
end
