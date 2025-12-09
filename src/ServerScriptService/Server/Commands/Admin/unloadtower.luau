-- @zylx 2025-12-6
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ZapServer = require(ServerScriptService.ZapServer)
local conch = require(ReplicatedStorage.Packages.conch_standalone)

return function()
	conch.register("unloadtower", {
		description = "Unloads currently playing tower for a player",
		permissions = { "manage-tower" },
		arguments = function()
			return conch.args.player("target", "Player to unload the tower for")
		end,

		callback = function(target: Player)
			ZapServer.UnloadTower.Fire(target)
			conch.log("info", `Unloaded tower for {target.Name}`)
		end,
	})
end
