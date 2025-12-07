local Teams = game:GetService("Teams")

local Teleport = require(".././Utils/Teleport")
local Types = require("../../../ReplicatedStorage/Shared/Types")
local Util = require("../../../ReplicatedStorage/Shared/Util")
local ZapServer = require("../../ZapServer")

type PlayerInfo = Types.PlayerInfo

local Markers = workspace.Markers

local PlayerState = {}

function PlayerState:UpdatePlayerInfoStats(player: PlayerInfo)
	local boostList = Util:FormatBoosts(player.BoostItemNames)

	player.Player:SetAttribute("CurrentTower", player.CurrentTower)
	player.Player:SetAttribute("CurrentTowerRush", player.CurrentTowerRush)
	player.Player:SetAttribute("CurrentTowerRushIndex", player.CurrentTowerRushIndex)
	player.Player:SetAttribute("TowerTimer", Util:FormatTimer(player.TowerTimer))
	player.Player:SetAttribute("BoostItemUsed", player.BoostItemUsed)
	player.Player:SetAttribute("BoostItemNames", boostList)
end

function PlayerState:ResetPlayerInfo(player: PlayerInfo)
	player.TowerTimer = 0
	player.CurrentTower = ""
	player.CurrentTowerCheckpoint = 0
	player.CurrentTowerRush = ""
	player.CurrentTowerRushIndex = 0
	player.BoostItemNames = {}
	player.BoostItemUsed = false
	player.DebugItemUsed = false

	--------------------------------------------

	PlayerState:UpdatePlayerInfoStats(player)
end

function PlayerState:TeleportToWinroom(player: PlayerInfo, winroomMarker: string)
	player.TouchEventBusy = true

	-- Send player to the winner team and unload the current tower
	player.Player.Team = Teams.Winners
	ZapServer.UnloadTower.Fire(player.Player)

	-- Clean up the player info
	PlayerState:ResetPlayerInfo(player)

	-- Find the winroom
	local winroomPart
	if winroomMarker ~= "" then
		winroomPart = Markers:FindFirstChild(winroomMarker, true)
	else
		winroomPart = Markers:FindFirstChild("WinroomSpawn", true)
	end

	-- Teleport to the winroom
	if winroomPart and winroomPart:IsA("BasePart") then
		Teleport:TeleportPlayerToPartWithWait(player.Player, winroomPart)
	end

	player.TouchEventBusy = false
end

return PlayerState
