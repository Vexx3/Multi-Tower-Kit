--[[
	Command: /ban <user> <reason> <privateReason> [duration]
	Bans a player from the game.
]]

local Players = game:GetService("Players")

local conch = require("../../../../Packages/conch")

local function resolveUser(userInput: string | number): number?
	if typeof(userInput) == "number" then
		return userInput
	elseif typeof(userInput) == "string" then
		local success, userId = pcall(function()
			return Players:GetUserIdFromNameAsync(userInput)
		end)

		if success then
			return userId
		end
	end

	return nil
end

return function()
	conch.register("ban", {
		description = "Bans a player from the game by UserId or username.",
		permissions = { "ban-player" },
		arguments = function()
			return conch.args.string("user", "UserId or username"),
				conch.args.string("reason", "Display reason for the ban"),
				conch.args.string("privateReason", "Private reason for the ban (moderators only)"),
				conch.args.optional(conch.args.number("duration", "Seconds (default -1 for permanent)"))
		end,

		callback = function(userInput: string | number, reason: string, privateReason: string, duration: number?)
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

			duration = tonumber(duration) or -1

			local userId = resolveUser(userInput)
			if not userId then
				conch.log("warn", "Invalid user or username not found")
				return
			end

			if userId == executorPlayer.UserId then
				conch.log("warn", "You cannot ban yourself.")
				return
			end

			local success, err = pcall(function()
				return Players:BanAsync({
					UserIds = { userId },
					Duration = duration,
					DisplayReason = reason,
					PrivateReason = privateReason,
				})
			end)

			if success then
				conch.log("info", `Banned {userInput} ({userId}) for {duration}s`)
			else
				conch.log("warn", `Failed to ban {userInput} ({userId}): {err}`)
			end
		end,
	})
end
