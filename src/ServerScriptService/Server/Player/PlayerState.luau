-- Handles per-player state transitions such as resetting run data and winroom teleports.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared

local BlinkServer = require("../Network/BlinkServer")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type PlayerInfo = Types.PlayerInfo

local MARKERS = workspace.Markers

local PlayerState = {}

-- Pushes the latest tower/rush/timer data into player attributes for client consumption.
function PlayerState.updatePlayerInfoStats(player: PlayerInfo): ()
	local boostList: string = Util.formatBoosts(player.boostItemNames)

	player.player:SetAttribute("CurrentTower", player.currentTower)
	player.player:SetAttribute("AllJumpsMode", player.mode == "AllJumps")
	player.player:SetAttribute("PracticeMode", player.mode == "Practice")
	player.player:SetAttribute("CurrentTowerRush", player.currentTowerRush)
	player.player:SetAttribute("CurrentTowerRushIndex", player.currentTowerRushIndex)
	player.player:SetAttribute("TowerTimer", Util.formatTimer(player.towerTimer))
	player.player:SetAttribute("BoostItemUsed", player.boostItemUsed)
	player.player:SetAttribute("BoostItemNames", boostList)
end

-- Resets in-memory player state for a new run and re-syncs attributes.
function PlayerState.resetPlayerInfo(player: PlayerInfo): ()
	player.towerTimer = 0
	player.currentTower = ""
	player.currentCheckpoint = 0
	player.currentTowerRush = ""
	player.currentTowerRushIndex = 0
	player.currentTowerRushSplitTime = 0
	player.boostItemNames = {}
	player.boostItemUsed = false
	player.debugItemUsed = false

	PlayerState.updatePlayerInfoStats(player)
end

-- Teleports a player to the winroom, unloads their current tower, and clears their run state.
function PlayerState.teleportToWinroom(player: PlayerInfo, winroomMarker: string?): ()
	local actualMarker: string = winroomMarker or ""
	player.touchEventBusy = true

	player.player.Team = Teams.Winners
	BlinkServer.UnloadTower.Fire(player.player)

	PlayerState.resetPlayerInfo(player)

	local winroomPart: BasePart?
	if actualMarker ~= "" then
		winroomPart = MARKERS:FindFirstChild(actualMarker, true) :: BasePart?
	else
		winroomPart = MARKERS:FindFirstChild("WinroomSpawn", true) :: BasePart?
	end

	if winroomPart and winroomPart:IsA("BasePart") then
		Util.respawnAndTeleport(player.player, winroomPart)
	end

	player.touchEventBusy = false
end

return PlayerState
