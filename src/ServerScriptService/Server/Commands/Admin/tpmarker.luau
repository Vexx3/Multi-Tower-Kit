-- @zylx 2025-12-6
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local Util = require(Shared.Util)
local args = require(Shared.ConchTypes)
local conch = require(ReplicatedStorage.Packages.conch)

return function()
	conch.register("tpmarker", {
		description = "Teleports to a marker.",
		permissions = { "teleport-player" },
		arguments = function()
			return conch.args.player("player", "The player to teleport"),
				args.marker_name("marker", "Marker to teleport to")
		end,

		callback = function(who: Player, marker: BasePart)
			Util:TeleportPlayerToPart(who, marker)
			conch.log("info", `Teleported {who.Name} to marker {marker.Name}`)
		end,
	})
end
