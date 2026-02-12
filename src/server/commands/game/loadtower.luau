--[[
	Command: /loadtower <target> <tower>
	Loads a tower for a player.
]]

local ConchTypes = require("../../../shared/conchTypes")
local conch = require("../../../../Packages/conch")
local players = require("../../lib/players")
local towers = require("../../gameplay/towers")

return function()
	conch.register("loadtower", {
		description = "Loads a tower for a player",
		permissions = { "manage-tower" },
		arguments = function()
			return conch.args.player("target", "Player to load the tower for"),
				ConchTypes.towerName("tower", "Tower to load")
		end,

		callback = function(target: Player, towerName: string)
			local player = players.getSession(target.Name)
			if player then
				towers.loadTower(player, towerName, true)
				conch.log("info", `Loaded tower '{towerName}' for {target.Name}`)
			else
				conch.log("error", `Could not find session for player {target.Name}`)
			end
		end,
	})
end
