local Players = game:GetService("Players")

local conch = require("@game/ReplicatedStorage/Packages/conch")

local function resolveUser(userInput: string | number): number?
	if type(userInput) == "number" then
		return userInput
	elseif type(userInput) == "string" then
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
	conch.register("unban", {
		description = "Unban a player by UserId or username.",
		permissions = { "ban-player" },
		arguments = function()
			return conch.args.string("user", "UserId or username")
		end,

		callback = function(userInput: string | number)
			local userId = resolveUser(userInput)
			if not userId then
				conch.log("warn", "Invalid user or username not found")
				return
			end

			local success, err = pcall(function()
				Players:UnbanAsync({
					UserIds = { userId },
					ApplyToUniverse = true,
				})
			end)

			if success then
				conch.log("info", `Unbanned {userInput} ({userId})`)
			else
				conch.log("warn", `Failed to unban {userInput} ({userId}): {err}`)
			end
		end,
	})
end
