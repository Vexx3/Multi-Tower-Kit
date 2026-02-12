--[[
	Command: /tpmarker <player> <marker>
	Teleports a player to a named marker.
]]

local ConchTypes = require("../../../shared/conchTypes")
local Util = require("../../../shared/utils/util")
local conch = require("../../../../Packages/conch")

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
