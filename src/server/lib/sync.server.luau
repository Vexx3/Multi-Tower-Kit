local Players = game:GetService("Players")

local BlinkServer = require("../../server/Network/BlinkServer")
local Charm = require("../../../Packages/charm")
local CharmSync = require("../../../Packages/charmsync")
local sessionStore = require("../stores/sessionStore")

local function onPlayerAdded(player: Player)
	CharmSync.server.addSignalsToClient(player, {
		[`session-{player.Name}`] = Charm.computed(function()
			return sessionStore.get(player.Name)
		end),
	})
end

local function onPlayerRemoving(player: Player)
	CharmSync.server.removeClient(player)
end

CharmSync.server.connect(function(player, patches)
	BlinkServer.SyncState.Fire(player, patches)
end)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
