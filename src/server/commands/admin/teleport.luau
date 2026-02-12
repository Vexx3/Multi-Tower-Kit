--[[
	Command: /teleport <targets> [destinationPlayer] [destinationPosition]
	Teleports players to another player or position.
]]

local conch = require("../../../../Packages/conch")

return function()
	conch.register("teleport", {
		description = "Teleports a player to another player or a vector3 position.",
		permissions = { "teleport-player" },
		arguments = function()
			return conch.args.players("targets", "Players to teleport"),
				conch.args.optional(conch.args.player("destinationPlayer", "Player to teleport to")),
				conch.args.optional(conch.args.vector("destinationPosition", "Vector3 position"))
		end,

		callback = function(targets: { Player }, destinationPlayer: Player?, destinationPosition: vector?)
			if #targets == 0 then
				return conch.log("warn", "No players to teleport")
			end

			local destCFrame: CFrame

			if destinationPlayer then
				local destChar = destinationPlayer.Character
				local destHRP = destChar and destChar:FindFirstChild("HumanoidRootPart") :: Part
				if not destHRP then
					return conch.log("warn", `Destination player {destinationPlayer.Name} has no character`)
				end
				destCFrame = destHRP.CFrame
			elseif destinationPosition then
				destCFrame = CFrame.new(destinationPosition.x, destinationPosition.y, destinationPosition.z)
			else
				return conch.log("warn", "No valid destination provided (player or vector3 required)")
			end

			for _, player in targets do
				local character = player.Character
				local hrp = character and character:FindFirstChild("HumanoidRootPart") :: Part
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
