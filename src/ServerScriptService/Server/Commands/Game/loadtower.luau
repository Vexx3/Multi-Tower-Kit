-- Command: /loadtower <target> <tower>
-- Loads a tower for a player.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Packages = ReplicatedStorage.Packages

local ConchTypes = require(Shared.ConchTypes)
local PlayerService = require("../../Services/PlayerService")
local TowerService = require("../../Services/TowerService")
local conch = require(Packages.conch)

return function()
	conch.register("loadtower", {
		description = "Loads a tower for a player",
		permissions = { "manage-tower" },
		arguments = function()
			return conch.args.player("target", "Player to load the tower for"),
				ConchTypes.towerName("tower", "Tower to load")
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
