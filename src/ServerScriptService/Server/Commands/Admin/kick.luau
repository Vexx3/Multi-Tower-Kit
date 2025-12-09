-- @zylx 2025-11-10
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local conch = require(ReplicatedStorage.Packages.conch_standalone)

return function()
	conch.register("kick", {
		description = "Kicks a player from the server",
		permissions = { "kick-player" },
		arguments = function()
			return conch.args.player("player", "The player to kick"),
				conch.args.optional(
					conch.args.string("reason", "The reason why the player is kicked")
				)
		end,

		callback = function(player: Player, reason: string?)
			local context = conch.get_command_context()
			local executor = context.executor
			local executorPlayer = executor.player

			if player.UserId == executorPlayer.UserId then
				conch.log("warn", "You cannot kick yourself.")
				return
			end

			reason = reason or "Kicked by admin."
			player:Kick(reason)

			conch.log("info", `Kicked {player.Name} ({player.UserId})`)
		end,
	})
end
