-- @zylx 2025-12-6
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local args = require(Shared.ConchTypes)
local conch = require(ReplicatedStorage.Packages.conch_standalone)

return function()
	conch.register("givebadge", {
		description = "Awards a badge to a player",
		permissions = { "give-badge" },
		arguments = function()
			return conch.args.player("target", "Player to receive a badge"),
				args.badge_name("badge", "Badge to award")
		end,

		callback = function(target: Player, badge: { Name: string, BadgeId: number })
			local success, result =
				pcall(BadgeService.AwardBadgeAsync, BadgeService, target.UserId, badge.BadgeId)
			if success and result then
				conch.log(
					"info",
					`Awarded badge '{badge.Name}' (ID {badge.BadgeId}) to {target.Name}`
				)
			else
				conch.log(
					"warn",
					`Failed to award badge '{badge.Name}' (ID {badge.BadgeId}) to {target.Name}`
				)
			end
		end,
	})
end
