--[[
	Player data lifecycle: load on join, unload on leave, close on shutdown.
	Also handles Blink data requests.
]]

local Players = game:GetService("Players")

local BlinkServer = require("../Network/BlinkServer")
local accountStore = require("../stores/accountStore")
local playerLifecycle = require("../../shared/utils/playerLifecycle")
local store = require("./store")

type PlayerData = store.PlayerData

playerLifecycle.onPlayerAdded(function(player)
	store.loadAsync(player)
end, function(player)
	store.unloadAsync(player)
	accountStore.removeAccount(player.Name)
end)

game:BindToClose(function()
	store.closeAsync()
end)

BlinkServer.GetPlayerData.On(function(_player: Player, targetUserId: number)
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		return store.getData(targetPlayer)
	end
	return store.peekAsync(targetUserId)
end)

BlinkServer.UpdateSettings.On(function(player: Player, settings: any)
	store.updateAsync(player, function(data: PlayerData)
		data.settings = settings
		return true
	end)
end)
