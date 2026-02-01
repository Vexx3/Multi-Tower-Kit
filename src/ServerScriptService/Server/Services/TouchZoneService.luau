--[[
	TouchZoneService - Unified handler for all touch-based interactions.
	Manages portals, markers, and teleporters.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Framework = ReplicatedStorage.Framework

local Log = require(Framework.Log)
local PlayerService = require("./PlayerService")
local TowerRushService = require("./TowerRushService")
local TowerService = require("./TowerService")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type PlayerInfo = Types.PlayerInfo

type ZoneData = {
	part: BasePart,
	connection: RBXScriptConnection?,
}

local MARKERS = workspace:FindFirstChild("Markers") :: Folder?
local PORTALS = workspace:FindFirstChild("Portals") :: Folder?

local zones: { ZoneData } = {}

local function registerZone(part: BasePart, onTouch: (playerName: string, part: BasePart) -> ())
	Util.registerTouch(part, onTouch)
	table.insert(zones, { part = part } :: ZoneData)
end

local function canEnterTower(playerName: string, targetTower: string?): boolean
	local player = PlayerService.getSession(playerName)
	if not player then
		return false
	end

	if player.currentTowerRush ~= "" then
		return false
	end

	if player.currentTower ~= "" and targetTower and player.currentTower ~= targetTower then
		return false
	end

	return true
end

local function setupPortal(portalPart: BasePart)
	local towerPortal = portalPart:FindFirstChild("TowerPortal") :: StringValue?
	if towerPortal then
		registerZone(portalPart, function(playerName)
			if canEnterTower(playerName, towerPortal.Value) then
				local player = PlayerService.getSession(playerName)
				if player then
					TowerService.loadTower(player, towerPortal.Value, true)
				end
			end
		end)
		return
	end

	local towerRush = portalPart:FindFirstChild("TowerRush") :: StringValue?
	if towerRush then
		registerZone(portalPart, function(playerName)
			if canEnterTower(playerName) then
				local player = PlayerService.getSession(playerName)
				if player then
					TowerRushService.loadTowerRush(player, towerRush.Value)
				end
			end
		end)
		return
	end

	local lobbyTeleporter = portalPart:FindFirstChild("LobbyTeleporter") :: StringValue?
	if not lobbyTeleporter then
		Log({
			type = "warn",
			[1] = `Part "{portalPart.Name}" was found in the portal folder but it isn't a portal`,
		})
		return
	end

	local targetPart = MARKERS and MARKERS:FindFirstChild(lobbyTeleporter.Value, true) :: BasePart?
	if targetPart and targetPart:IsA("BasePart") then
		registerZone(portalPart, function(playerName)
			local player = PlayerService.getSession(playerName)
			if player and not player.touchEventBusy then
				player.touchEventBusy = true
				Util.teleportPlayerToPart(player.player, targetPart)
				player.touchEventBusy = false
			end
		end)
	else
		Log({
			type = "warn",
			[1] = `Could not setup teleporter "{portalPart:GetFullName()}" because it does not reference a BasePart`,
		})
	end
end

local function setupMarker(marker: BasePart)
	if marker.Name == "LobbyTP" then
		local spawnLocation = MARKERS and MARKERS:FindFirstChild("SpawnLocation") :: BasePart?
		if spawnLocation and spawnLocation:IsA("BasePart") then
			registerZone(marker, function(playerName)
				local playerInfo = PlayerService.getSession(playerName)
				if playerInfo then
					playerInfo.player.Team = Teams.Start
					Util.teleportPlayerToPart(playerInfo.player, spawnLocation)
				end
			end)
		else
			Log({
				type = "error",
				[1] = "Could not initialize LobbyTP because a SpawnLocation couldn't be found",
			})
		end
	end
end

local TouchZoneService = {}

function TouchZoneService.Start()
	if PORTALS then
		for _, child in PORTALS:GetChildren() do
			if child:IsA("BasePart") then
				setupPortal(child)
			end
		end
	end

	if MARKERS then
		for _, child in MARKERS:GetChildren() do
			if child:IsA("BasePart") then
				setupMarker(child)
			end
		end
	end

	Log({ `TouchZoneService initialized with {#zones} zones` })
end

return TouchZoneService
