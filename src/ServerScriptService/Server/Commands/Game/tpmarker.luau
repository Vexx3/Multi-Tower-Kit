--[[
	Command: /tpmarker <player> <marker>
	Teleports a player to a named marker.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Packages = ReplicatedStorage.Packages

local ConchTypes = require(Shared.ConchTypes)
local Util = require(Shared.Util)
local conch = require(Packages.conch)

return function()
	conch.register("tpmarker", {
		description = "Teleports to a marker.",
		permissions = { "teleport-player" },
		arguments = function()
			return conch.args.player("player", "The player to teleport"),
				ConchTypes.markerName("marker", "Marker to teleport to")
		end,

		callback = function(who: Player, marker: BasePart)
			Util.teleportPlayerToPart(who, marker)
			conch.log("info", `Teleported {who.Name} to marker {marker.Name}`)
		end,
	})
end
