-- @zylx 2025-12-6
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local args = require(Shared.ConchTypes)
local conch = require(ReplicatedStorage.Packages.conch_standalone)
local Teleport = require("../.././Utils/Teleport")

return function()
	conch.register("tpmarker", {
		description = "Teleports to a marker.",
		permissions = { "teleport" },
		arguments = function()
			return
				conch.args.player("player", "The player to teleport"),
				args.marker_name("marker", "Marker to teleport to")
		end,
		
		callback = function(who: Player, marker: BasePart)
			Teleport:TeleportPlayerToPart(who, marker)
			conch.log("info", `Teleported {who.Name} to {marker.Name}`)
		end,
	})
end
