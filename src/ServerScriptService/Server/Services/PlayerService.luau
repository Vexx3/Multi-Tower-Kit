-- Handles per-player lifecycle (Joining, Leaving, State Updates) and player-related remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Data = Shared.Data

local Framework = ReplicatedStorage.Framework
local Log = require(Framework.Log)

local BlinkServer = require("../Network/BlinkServer")
local Config = require(Data.Config)
local LeaderstatsService = require("./LeaderstatsService")
local PlayerData = require("../Player/PlayerData")
local PlayerState = require("../Player/PlayerState")
local ToolService = require("./ToolService")
local TowerData = require("../Player/PlayerData/TowerData")
local TowerRushService = require("./TowerRushService")
local TowerService = require("./TowerService")
local Types = require(Shared.Types)

local EVERPRESENT_COS = ServerStorage:WaitForChild("EverpresentCOs")

local sessions: { [string]: Types.PlayerInfo } = {}

local PlayerService = {}

local function onEverpresentCOsRequested(playerInstance: Player): (boolean, Folder?)
	local player: Types.PlayerInfo? = sessions[playerInstance.Name]
	if not player then
		return false, nil
	end

	if player.hasEverpresentCOs then
		return false, nil
	end

	local playerECOs = EVERPRESENT_COS:Clone() :: Folder
	playerECOs.Parent = playerInstance
	player.hasEverpresentCOs = true

	return true, playerECOs
end

local function onPlayerRestartRequested(playerInstance: Player)
	local player: Types.PlayerInfo = sessions[playerInstance.Name]
	if not player then
		return
	end

	-- If the player is attempting to restart after the cooldown has ended
	if player.gameTimer - player.lastRestart >= Config.restartCooldown then
		player.lastRestart = player.gameTimer
		-- The player isn't even in a tower
		if player.currentTower == "" then
			return
		end

		TowerData.addTowerTimeSpent(player.player, player.currentTower, player.towerTimer)

		if player.currentTowerRush == "" then
			TowerService.loadTower(player, player.currentTower, true)
		else
			TowerRushService.loadTowerRush(player, player.currentTowerRush)
		end
	end
end

local function onExitTowerRequest(playerInstance: Player)
	local player: Types.PlayerInfo = sessions[playerInstance.Name]
	if not player then
		return
	end

	if player.currentTower ~= "" then
		player.player:LoadCharacterAsync()
	end
end

local function setPlayerMode(playerInstance: Player, mode: Types.PlayerMode)
	local player: Types.PlayerInfo = sessions[playerInstance.Name]
	if not player then
		return
	end

	-- If they toggle mode while in a tower, we reset their run to apply it correctly
	if player.currentTower ~= "" then
		TowerData.addTowerTimeSpent(player.player, player.currentTower, player.towerTimer)
		player.mode = mode

		if player.currentTowerRush == "" then
			TowerService.loadTower(player, player.currentTower, true)
		else
			TowerRushService.loadTowerRush(player, player.currentTowerRush)
		end
	else
		player.mode = mode
	end

	PlayerState.updatePlayerInfoStats(player)
end

local function onPlayerSetAllJumpsMode(playerInstance: Player, enabled: boolean)
	setPlayerMode(playerInstance, if enabled then "AllJumps" else "Normal")
end

local function onPlayerSetPracticeMode(playerInstance: Player, enabled: boolean)
	setPlayerMode(playerInstance, if enabled then "Practice" else "Normal")
end

local function onCharacterAdded(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 and Config.r15Warning then
		Log({
			type = "warn",
			[1] = "Character spawned with R15 rig type, most obbying techniques are impossible. Ensure that the rig type is R6 in game settings.",
		})
	end

	local player: Types.PlayerInfo? = sessions[character.Name]
	if player then
		if player.player.Team ~= Teams.Winners then
			player.player.Team = Teams.Start
		end

		character.ChildAdded:Connect(function(item)
			if item:IsA("Tool") then
				ToolService.handleToolEquipped(player, item)
			end
		end)

		if player.isLoadingTower then
			player.isLoadingTower = false
			return
		end

		if player.currentTower ~= "" then
			TowerData.addTowerTimeSpent(player.player, player.currentTower, player.towerTimer)
		end

		BlinkServer.UnloadTower.Fire(player.player)
		PlayerState.resetPlayerInfo(player)
	end
end

local function onPlayerAdded(player: Player)
	local info: Types.PlayerInfo = {
		player = player,
		gameTimer = 0,
		lastRestart = 0,

		currentTower = "",
		currentCheckpoint = 0,
		boostItemNames = {},
		boostItemUsed = false,
		towerTimer = 0,
		mode = "Normal",

		currentTowerRush = "",
		currentTowerRushIndex = 0,
		currentTowerRushSplitTime = 0,

		touchEventBusy = false,
		isLoadingTower = false,
		hasEverpresentCOs = false,
		debugItemUsed = false,
	}

	PlayerState.updatePlayerInfoStats(info)
	sessions[player.Name] = info

	PlayerData.waitForData(player)

	LeaderstatsService.initPlayer(player)
	ToolService.giveAllCompletedTowerTools(player)

	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.Team = Teams.Start
	player.CharacterAdded:Connect(onCharacterAdded)
end

local function onPlayerRemoving(player: Player)
	sessions[player.Name] = nil
end

function PlayerService.init()
	EVERPRESENT_COS.Parent = ServerStorage

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(onPlayerRemoving)

	BlinkServer.SetAllJumpsMode.On(onPlayerSetAllJumpsMode)
	BlinkServer.SetPracticeMode.On(onPlayerSetPracticeMode)
	BlinkServer.RequestEverpresentCOs.On(onEverpresentCOsRequested)
	BlinkServer.RestartRequested.On(onPlayerRestartRequested)
	BlinkServer.ExitTowerRequest.On(onExitTowerRequest)
end

function PlayerService.getSession(playerName: string)
	return sessions[playerName]
end

function PlayerService.getAllSessions()
	return sessions
end

return PlayerService
