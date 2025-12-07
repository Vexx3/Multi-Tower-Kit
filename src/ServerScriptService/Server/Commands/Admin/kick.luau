-- @zylx 2025-11-10
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local conch = require(ReplicatedStorage.Packages.conch_standalone)

return function()
	conch.register("kick", {
		description = "Kicks a player from the server",
		permissions = { "shutdown-server" },
		arguments = function()
			return
				conch.args.player("player", "The player to kick"),
				conch.args.optional(conch.args.string("reason", "The reason why the player is kicked"))
		end,

		callback = function(player: Player, reason: string?)
			reason = reason or "Kicked by admin."
			player:Kick(reason)
			
			conch.log("info", `Kicked {player.Name}.`)
		end,
	})
end
