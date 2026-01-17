--[[
	Initializes lobby teleporters and tower portals.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
type TowerInfo = Types.TowerInfo

local MARKERS = workspace.Markers
local PORTALS = workspace.Portals

local function canEnter(playerName: string, targetTower: string?): boolean
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

local function registerStringPortal(
	part: BasePart,
	value: StringValue,
	onTouch: (playerName: string, value: string) -> ()
)
	Util.registerTouch(part, function(playerName)
		onTouch(playerName, value.Value)
	end)
end

local function setupPortal(portalPart: BasePart)
	local towerPortal = portalPart:FindFirstChild("TowerPortal") :: StringValue
	if towerPortal then
		registerStringPortal(portalPart, towerPortal, function(playerName, value)
			if canEnter(playerName, value) then
				local player = PlayerService.getSession(playerName)
				if player then
					TowerService.loadTower(player, value, true)
				end
			end
		end)
		return
	end

	local towerRush = portalPart:FindFirstChild("TowerRush") :: StringValue
	if towerRush then
		registerStringPortal(portalPart, towerRush, function(playerName, value)
			if canEnter(playerName) then
				local player = PlayerService.getSession(playerName)
				if player then
					TowerRushService.loadTowerRush(player, value)
				end
			end
		end)
		return
	end

	local lobbyTeleporter = portalPart:FindFirstChild("LobbyTeleporter") :: StringValue
	if not lobbyTeleporter then
		Log({
			type = "warn",
			[1] = `Part "{portalPart.Name}" was found in the portal folder but it isn't a portal`,
		})
		return
	end

	local targetPart = MARKERS:FindFirstChild(lobbyTeleporter.Value, true) :: BasePart
	if targetPart and targetPart:IsA("BasePart") then
		Util.registerTouch(portalPart, function(playerName)
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

local PortalService = {}

--- Initializes all portals found in workspace.Portals.
function PortalService.Start()
	for _, child in PORTALS:GetChildren() do
		if child:IsA("BasePart") then
			setupPortal(child)
		end
	end
end

return PortalService
