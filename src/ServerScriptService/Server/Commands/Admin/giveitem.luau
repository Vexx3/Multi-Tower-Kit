-- @zylx 2025-12-09
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local args = require(Shared.ConchTypes)
local conch = require(ReplicatedStorage.Packages.conch)

return function()
	conch.register("giveitem", {
		description = "Gives a Tool from ReplicatedStorage.Tools to a player",
		permissions = { "give-item" },
		arguments = function()
			return conch.args.player("target", "Player to receive the tool"),
				args.tool_name("tool", "Tool to give")
		end,

		callback = function(target: Player, tool: Tool)
			local cloneBackpack = tool:Clone()
			cloneBackpack.Parent = target.Backpack

			local cloneGear = tool:Clone()
			cloneGear.Parent = target.StarterGear
			conch.log("info", `Gave tool '{tool.Name}' to {target.Name}`)
		end,
	})
end
