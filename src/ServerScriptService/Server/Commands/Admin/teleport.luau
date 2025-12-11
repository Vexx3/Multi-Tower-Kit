-- @zylx 2025-11-10
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local conch = require(ReplicatedStorage.Packages.conch)

return function()
	conch.register("teleport", {
		description = "Teleports a player to another player or a vector3 position.",
		permissions = { "teleport-player" },
		arguments = function()
			return conch.args.players("targets", "Players to teleport"),
				conch.args.optional(conch.args.player("destinationPlayer", "Player to teleport to")),
				conch.args.optional(conch.args.vector("destinationPosition", "Vector3 position"))
		end,

		callback = function(
			targets: { Player },
			destinationPlayer: Player?,
			destinationPosition: Vector3?
		)
			if #targets == 0 then
				return conch.log("warn", "No players to teleport")
			end

			local destCFrame

			if destinationPlayer then
				local destChar = destinationPlayer.Character
				local destHRP: Part = destChar:FindFirstChild("HumanoidRootPart")
				if not destHRP then
					return conch.log(
						"warn",
						`Destination player {destinationPlayer.Name} has no character`
					)
				end
				destCFrame = destHRP.CFrame
			elseif destinationPosition then
				destCFrame = CFrame.new(destinationPosition)
			else
				return conch.log(
					"warn",
					"No valid destination provided (player or vector3 required)"
				)
			end

			for _, player in targets do
				local character = player.Character
				local hrp: Part = character and character:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = destCFrame
				else
					conch.log("warn", `Player {player.Name} has no character/HumanoidRootPart`)
				end
			end

			conch.log("info", `Teleported {#targets} player(s)`)
		end,
	})
end
