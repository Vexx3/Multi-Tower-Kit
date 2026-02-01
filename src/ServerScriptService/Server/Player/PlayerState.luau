--[[
	Handles per-player state transitions.
	Manages attribute syncing and winroom teleportation.
	Uses Session for state management.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared

local BlinkServer = require("../Network/BlinkServer")
local Session = require("../Producers/SessionManager")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type PlayerInfo = Types.PlayerInfo

local MARKERS = workspace.Markers

local PlayerState = {}

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

function PlayerState.resetPlayerInfo(player: PlayerInfo): ()
	Session.resetRun(player.player.Name)

	-- Re-fetch the updated session after reset
	local session = Session.get(player.player.Name)
	if session then
		PlayerState.updatePlayerInfoStats(session)
	end
end

function PlayerState.teleportToWinroom(player: PlayerInfo, winroomMarker: string?): ()
	local actualMarker: string = winroomMarker or ""
	Session.setTouchBusy(player.player.Name, true)

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

	Session.setTouchBusy(player.player.Name, false)
end

return PlayerState
