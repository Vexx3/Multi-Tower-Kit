-- @zylx 2025-11-10
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local conch = require(ReplicatedStorage.Packages.conch_standalone)

local function resolveUser(userInput: string | number): number?
	if typeof(userInput) == "number" then
		return userInput
	elseif typeof(userInput) == "string" then
		local success, userId = pcall(function()
			return Players:GetUserIdFromNameAsync(userInput)
		end)

		if success then
			return userId
		else
			return nil
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
				conch.args.optional(
					conch.args.number("duration", "Seconds (default -1 for permanent)")
				),
				conch.args.optional(conch.args.string("reason", "Reason for the ban"))
		end,

		callback = function(userInput: string | number, duration: number?, reason: string?)
			duration = tonumber(duration) or -1
			reason = reason or "You have been banned from the game"

			local userId = resolveUser(userInput)
			if not userId then
				return
			end

			local success, err = pcall(function()
				Players:BanAsync({
					UserIds = { userId },
					Duration = duration,
					DisplayReason = reason,
					PrivateReason = reason,
				})
			end)

			if success then
				conch.log("info", `Successfully banned: {userInput}`)
			else
				conch.log("warn", `Failed to ban userId {userInput}: {err}`)
			end
		end,
	})
end
