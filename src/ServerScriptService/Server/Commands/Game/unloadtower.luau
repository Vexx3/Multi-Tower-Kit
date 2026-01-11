local BlinkServer = require("../../Network/BlinkServer")
local conch = require("@game/ReplicatedStorage/Packages/conch")

return function()
	conch.register("unloadtower", {
		description = "Unloads currently playing tower for a player",
		permissions = { "manage-tower" },
		arguments = function()
			return conch.args.player("target", "Player to unload the tower for")
		end,

		callback = function(target: Player)
			BlinkServer.UnloadTower.Fire(target)
			conch.log("info", `Unloaded tower for {target.Name}`)
		end,
	})
end
