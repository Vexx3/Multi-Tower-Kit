--[[
	Per-player state transitions.
	Manages attribute syncing and winroom teleportation.

	You don't normally need to edit this file — use Hooks instead to react
	to events like tower loads, wins, etc.
]]

local Teams = game:GetService("Teams")

local BlinkServer = require("../Network/BlinkServer")
local Types = require("../../shared/types")
local Util = require("../../shared/utils/util")
local sessionStore = require("../stores/sessionStore")

type PlayerInfo = Types.PlayerInfo

local MARKERS = workspace.Markers

local playerState = {}

function playerState.updatePlayerInfoStats(player: PlayerInfo): ()
	local boostList = Util.formatBoosts(player.boostItemNames)

	player.player:SetAttribute("CurrentTower", player.currentTower)
	player.player:SetAttribute("AllJumpsMode", player.mode == "AllJumps")
	player.player:SetAttribute("PracticeMode", player.mode == "Practice")
	player.player:SetAttribute("CurrentTowerRush", player.currentTowerRush)
	player.player:SetAttribute("CurrentTowerRushIndex", player.currentTowerRushIndex)
	player.player:SetAttribute("BoostItemNames", boostList)
end

function playerState.resetPlayerInfo(player: PlayerInfo): ()
	sessionStore.resetRun(player.player.Name)

	local session = sessionStore.get(player.player.Name)
	if session then
		playerState.updatePlayerInfoStats(session)
	end
end

function playerState.teleportToWinroom(player: PlayerInfo, winroomMarker: string?): ()
	local actualMarker = winroomMarker or ""
	sessionStore.setTouchBusy(player.player.Name, true)

	player.player.Team = Teams.Winners
	BlinkServer.UnloadTower.Fire(player.player)

	playerState.resetPlayerInfo(player)

	local winroomPart: BasePart?
	if actualMarker ~= "" then
		winroomPart = MARKERS:FindFirstChild(actualMarker, true) :: BasePart?
	else
		winroomPart = MARKERS:FindFirstChild("WinroomSpawn", true) :: BasePart?
	end

	if winroomPart and winroomPart:IsA("BasePart") then
		Util.respawnAndTeleport(player.player, winroomPart)
	end

	sessionStore.setTouchBusy(player.player.Name, false)
end

return playerState
