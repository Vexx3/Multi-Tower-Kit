--[[
	Client state synchronization using Charm-Sync.
]]
local Players = game:GetService("Players")

local BlinkClient = require("../../shared/Network/BlinkClient")
local CharmSync = require("../../../Packages/charmsync")
local sessionState = require("../stores/sessionState")

CharmSync.client.addSignals({
	[`session-{Players.LocalPlayer.Name}`] = sessionState.setSession :: any,
} :: any)

BlinkClient.SyncState.On(function(patches)
	CharmSync.client.patch(patches)
end)
