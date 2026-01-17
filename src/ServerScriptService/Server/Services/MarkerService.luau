--[[
	Handles initialization of world markers.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared

local PlayerService = require("./PlayerService")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

local MARKERS = workspace:FindFirstChild("Markers") :: Folder?

local function initMarker(marker: BasePart)
	if marker.Name == "LobbyTP" then
		local spawnLocation = MARKERS and MARKERS:WaitForChild("SpawnLocation")
		assert(
			spawnLocation and spawnLocation:IsA("BasePart"),
			"Could not initialize LobbyTP because a SpawnLocation couldn't be found"
		)

		Util.registerTouch(marker, function(playerName)
			local playerInfo: Types.PlayerInfo? = PlayerService.getSession(playerName)
			if not playerInfo then
				return
			end

			playerInfo.player.Team = Teams.Start
			Util.teleportPlayerToPart(playerInfo.player, spawnLocation)
		end)
	end
end

local MarkerService = {}

--- Initializes all markers found in workspace.Markers.
function MarkerService.Start()
	if not MARKERS then
		return
	end

	for _, child in MARKERS:GetChildren() do
		if child:IsA("BasePart") then
			initMarker(child)
		end
	end
end

return MarkerService
