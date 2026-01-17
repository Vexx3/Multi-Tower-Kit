--[=[
	Handles per-player lifecycle and player-related remotes.

	Manages player sessions (join/leave), processes restart/exit requests,
	and provides session lookup APIs for other services.

	@class PlayerService
	@server
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Data = Shared.Data
local Framework = ReplicatedStorage.Framework

local AllJumpsService = require("./AllJumpsService")
local BlinkServer = require("../Network/BlinkServer")
local Config = require(Data.Config)
local LeaderstatsService = require("./LeaderstatsService")
local Log = require(Framework.Log)
local PlayerData = require("../Player/PlayerData")
local PlayerState = require("../Player/PlayerState")
local ToolService = require("./ToolService")
local TowerData = require("../Player/PlayerData/TowerData")
local TowerRushService = require("./TowerRushService")
local TowerService = require("./TowerService")
local Types = require(Shared.Types)

local EVERPRESENT_COS = ServerStorage:WaitForChild("EverpresentCOs")

local sessions: { [string]: Types.PlayerInfo } = {}

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
	local player = sessions[playerInstance.Name]
	if not player or (player.gameTimer - player.lastRestart < Config.restartCooldown) then
		return
	end

	player.lastRestart = player.gameTimer

	TowerData.addTowerTimeSpent(player.player, player.currentTower, player.towerTimer)
	AllJumpsService.clearCheckpoint(playerInstance.Name)

	if player.currentTowerRush == "" then
		TowerService.loadTower(player, player.currentTower, true)
	else
		TowerRushService.loadTowerRush(player, player.currentTowerRush)
	end
end

local function onExitTowerRequest(playerInstance: Player)
	local player = sessions[playerInstance.Name]
	if not player then
		return
	end

	if player.currentTower ~= "" then
		player.player:LoadCharacterAsync()
	end
end

local function setPlayerMode(playerInstance: Player, mode: Types.PlayerMode)
	local player = sessions[playerInstance.Name]
	if not player then
		return
	end

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

local function setupHealthMonitoring(playerInfo: Types.PlayerInfo, humanoid: Humanoid)
	humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		if playerInfo.mode ~= "AllJumps" or humanoid.Health > 0 then
			return
		end

		-- Prevent the player from actually dying/respawning
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		humanoid.Health = humanoid.MaxHealth

		-- Teleport player back to their last jump checkpoint
		local tower = TowerService.getTower(playerInfo.currentTower)
		if tower then
			AllJumpsService.teleportToCheckpoint(playerInfo, tower)
		end

		-- Re-enable Dead state after a frame to allow manual Roblox menu resets to still work
		task.defer(function()
			if humanoid and humanoid.Parent then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
			end
		end)
	end)
end

local function onCharacterAdded(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local player = sessions[character.Name]
	if not player or not humanoid then
		return
	end

	if humanoid.RigType == Enum.HumanoidRigType.R15 and Config.r15Warning then
		Log({
			type = "warn",
			[1] = "Character spawned with R15 rig type, most obbying techniques are impossible.",
		})
	end
	if player.player.Team ~= Teams.Winners then
		player.player.Team = Teams.Start
	end

	character.ChildAdded:Connect(function(item)
		if item:IsA("Tool") then
			ToolService.handleToolEquipped(player, item)
		end
	end)

	setupHealthMonitoring(player, humanoid)

	if player.isLoadingTower then
		player.isLoadingTower = false
		return
	end

	-- Recovery teleport for All Jumps Mode
	if player.mode == "AllJumps" and player.currentTower ~= "" then
		local tower = TowerService.getTower(player.currentTower)
		if tower then
			AllJumpsService.teleportToCheckpoint(player, tower)
		end
		return
	end

	if player.currentTower ~= "" then
		TowerData.addTowerTimeSpent(player.player, player.currentTower, player.towerTimer)
	end

	BlinkServer.UnloadTower.Fire(player.player)
	PlayerState.resetPlayerInfo(player)
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

	sessions[player.Name] = info
	PlayerState.updatePlayerInfoStats(info)
	PlayerData.waitForData(player)
	LeaderstatsService.initPlayer(player)
	ToolService.giveAllCompletedTowerTools(player)

	player.Team = Teams.Start
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end

local function onPlayerRemoving(player: Player)
	sessions[player.Name] = nil
end

local PlayerService = {}

--- Initializes the player service, connects lifecycle events and remote handlers.
function PlayerService.Start()
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

--- Gets the session info for a player by name.
--- @param playerName string -- The name of the player
--- @return PlayerInfo? -- The player's session info, or nil if not found
function PlayerService.getSession(playerName: string): Types.PlayerInfo?
	return sessions[playerName]
end

--- Gets all active player sessions.
--- @return {[string]: PlayerInfo} -- Map of player names to their session info
function PlayerService.getAllSessions()
	return sessions
end

return PlayerService
