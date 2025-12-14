--[=[
	Handles per-player state transitions such as resetting run data, updating
	attributes, and sending players to the winroom after a win.

	@class PlayerState
]=]

local Teams = game:GetService("Teams")

local Types = require("../../../ReplicatedStorage/Shared/Types")
local Util = require("../../../ReplicatedStorage/Shared/Util")
local ZapServer = require("../../ZapServer")

type PlayerInfo = Types.PlayerInfo

local MARKERS = workspace.Markers

local PlayerState = {}

--[=[
	Pushes the latest tower/rush/timer data into player attributes for client
	consumption.

	@within PlayerState
	@server
]=]
function PlayerState:UpdatePlayerInfoStats(player: PlayerInfo)
	local boostList = Util:FormatBoosts(player.BoostItemNames)

	player.Player:SetAttribute("CurrentTower", player.CurrentTower)
	player.Player:SetAttribute("AllJumpsMode", player.AllJumpsMode)
	player.Player:SetAttribute("PracticeMode", player.PracticeMode)
	player.Player:SetAttribute("CurrentTowerRush", player.CurrentTowerRush)
	player.Player:SetAttribute("CurrentTowerRushIndex", player.CurrentTowerRushIndex)
	player.Player:SetAttribute("TowerTimer", Util:FormatTimer(player.TowerTimer))
	player.Player:SetAttribute("BoostItemUsed", player.BoostItemUsed)
	player.Player:SetAttribute("BoostItemNames", boostList)
end

--[=[
	Resets in-memory player state for a new run and re-syncs attributes.

	@within PlayerState
]=]
function PlayerState:ResetPlayerInfo(player: PlayerInfo)
	player.TowerTimer = 0
	player.CurrentTower = ""
	player.AllJumpsMode = false
	player.PracticeMode = false
	player.CurrentTowerCheckpoint = 0
	player.CurrentTowerRush = ""
	player.CurrentTowerRushIndex = 0
	player.BoostItemNames = {}
	player.BoostItemUsed = false
	player.DebugItemUsed = false

	--------------------------------------------

	PlayerState:UpdatePlayerInfoStats(player)
end

--[=[
	Teleports a player to the winroom, unloads their current tower, and clears
	their run state.

	@within PlayerState
	@param winroomMarker string -- Optional marker name; defaults to WinroomSpawn
]=]
function PlayerState:TeleportToWinroom(player: PlayerInfo, winroomMarker: string?)
	winroomMarker = winroomMarker or ""
	player.TouchEventBusy = true

	-- Send player to the winner team and unload the current tower
	player.Player.Team = Teams.Winners
	ZapServer.UnloadTower.Fire(player.Player)

	-- Clean up the player info
	PlayerState:ResetPlayerInfo(player)

	-- Find the winroom
	local winroomPart
	if winroomMarker ~= "" then
		winroomPart = MARKERS:FindFirstChild(winroomMarker, true)
	else
		winroomPart = MARKERS:FindFirstChild("WinroomSpawn", true)
	end

	-- Teleport to the winroom
	if winroomPart and winroomPart:IsA("BasePart") then
		Util:RespawnAndTeleport(player.Player, winroomPart)
	end

	player.TouchEventBusy = false
end

return PlayerState
