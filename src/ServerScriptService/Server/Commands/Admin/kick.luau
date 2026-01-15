-- Command: /kick <player> [reason]
-- Kicks a player from the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local conch = require(Packages.conch)

return function()
	conch.register("kick", {
		description = "Kicks a player from the server",
		permissions = { "kick-player" },
		arguments = function()
			return conch.args.player("player", "The player to kick"),
				conch.args.optional(conch.args.string("reason", "The reason why the player is kicked"))
		end,

		callback = function(player: Player, reason: string?)
			local context = conch.get_command_context()
			if not context then
				conch.log("warn", "No command context available")
				return
			end

			local executor = context.executor
			local executorPlayer = executor and executor.player
			if not executorPlayer then
				conch.log("warn", "Could not determine executor")
				return
			end

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
