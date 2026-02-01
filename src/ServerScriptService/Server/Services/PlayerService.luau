--[[
	PlayerService - Handles per-player lifecycle and session management.
	Uses SessionManager for state, events, and Observers for lifecycle.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Data = Shared.Data
local Framework = ReplicatedStorage.Framework
local Packages = ReplicatedStorage.Packages

local AllJumpsService = require("./AllJumpsService")
local BlinkServer = require("../Network/BlinkServer")
local Config = require(Data.Config)
local LeaderstatsService = require("./LeaderstatsService")
local Log = require(Framework.Log)
local Observers = require(Packages.observers)
local PlayerData = require("../Player/PlayerData")
local PlayerState = require("../Player/PlayerState")
local Promise = require(Packages.promise)
local Session = require("../Producers/SessionManager")
local ToolService = require("./ToolService")
local TowerData = require("../Player/PlayerData/TowerData")
local TowerRushService = require("./TowerRushService")
local TowerService = require("./TowerService")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

local EVERPRESENT_COS = ServerStorage:WaitForChild("EverpresentCOs")
local MARKERS = workspace:WaitForChild("Markers") :: Folder

local function onEverpresentCOsRequested(playerInstance: Player): (boolean, Folder?)
	local player = Session.get(playerInstance.Name)
	if not player or player.hasEverpresentCOs then
		return false, nil
	end

	local playerECOs = EVERPRESENT_COS:Clone() :: Folder
	playerECOs.Parent = playerInstance
	Session.update(playerInstance.Name, { hasEverpresentCOs = true })

	return true, playerECOs
end

local function onPlayerRestartRequested(playerInstance: Player)
	local player = Session.get(playerInstance.Name)
	if not player or (player.gameTimer - player.lastRestart < Config.restartCooldown) then
		return
	end

	Session.update(playerInstance.Name, { lastRestart = player.gameTimer })

	TowerData.addTowerTimeSpent(player.player, player.currentTower, player.towerTimer)
	AllJumpsService.clearCheckpoint(playerInstance.Name)

	if player.currentTowerRush == "" then
		TowerService.loadTower(player, player.currentTower, true)
	else
		TowerRushService.loadTowerRush(player, player.currentTowerRush)
	end
end

local function onExitTowerRequest(playerInstance: Player)
	local player = Session.get(playerInstance.Name)
	if not player or player.currentTower == "" then
		return
	end

	TowerData.addTowerTimeSpent(player.player, player.currentTower, player.towerTimer)
	AllJumpsService.clearCheckpoint(playerInstance.Name)

	local spawnLocation = MARKERS:FindFirstChild("SpawnLocation", true) :: BasePart?

	player.player.Team = Teams.Start
	BlinkServer.UnloadTower.Fire(player.player)
	Session.resetRun(playerInstance.Name)
	PlayerState.updatePlayerInfoStats(player)

	if spawnLocation and spawnLocation:IsA("BasePart") then
		Util.respawnAndTeleport(player.player, spawnLocation)
	else
		player.player:LoadCharacterAsync()
	end
end

local function setPlayerMode(playerInstance: Player, mode: Types.PlayerMode)
	local player = Session.get(playerInstance.Name)
	if not player then
		return
	end

	if player.currentTower ~= "" then
		TowerData.addTowerTimeSpent(player.player, player.currentTower, player.towerTimer)
		Session.setMode(playerInstance.Name, mode)

		if player.currentTowerRush == "" then
			TowerService.loadTower(player, player.currentTower, true)
		else
			TowerRushService.loadTowerRush(player, player.currentTowerRush)
		end
	else
		Session.setMode(playerInstance.Name, mode)
	end

	PlayerState.updatePlayerInfoStats(player)
end

local function onPlayerSetAllJumpsMode(playerInstance: Player, enabled: boolean)
	setPlayerMode(playerInstance, if enabled then "AllJumps" else "Normal")
end

local function onPlayerSetPracticeMode(playerInstance: Player, enabled: boolean)
	setPlayerMode(playerInstance, if enabled then "Practice" else "Normal")
end

local function setupHealthMonitoring(playerName: string, humanoid: Humanoid)
	humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		local playerInfo = Session.get(playerName)
		if not playerInfo or playerInfo.mode ~= "AllJumps" or humanoid.Health > 0 then
			return
		end

		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		humanoid.Health = humanoid.MaxHealth

		local tower = TowerService.getTower(playerInfo.currentTower)
		if tower then
			AllJumpsService.teleportToCheckpoint(playerInfo, tower)
		end

		task.defer(function()
			if humanoid and humanoid.Parent then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
			end
		end)
	end)
end

local function onCharacterAdded(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local player = Session.get(character.Name)
	if not player or not humanoid then
		return
	end

	if humanoid.RigType == Enum.HumanoidRigType.R15 and Config.r15Warning then
		Log({ type = "warn", [1] = "Character spawned with R15 rig type." })
	end

	if player.player.Team ~= Teams.Winners then
		player.player.Team = Teams.Start
	end

	character.ChildAdded:Connect(function(item)
		if item:IsA("Tool") then
			ToolService.handleToolEquipped(player, item)
		end
	end)

	setupHealthMonitoring(character.Name, humanoid)

	if player.isLoadingTower then
		Session.finishLoading(character.Name)
		return
	end

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
	Session.resetRun(character.Name)
	PlayerState.updatePlayerInfoStats(player)
end

local DEFAULT_PLAYER_INFO: Types.PlayerInfo = {
	player = nil :: any,
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

local function initializePlayer(player: Player)
	local info: Types.PlayerInfo = table.clone(DEFAULT_PLAYER_INFO)
	info.player = player

	Session.add(player.Name, info)
	PlayerState.updatePlayerInfoStats(info)

	Promise.new(function(resolve)
		PlayerData.waitForData(player)
		resolve()
	end):andThen(function()
		if player.Parent then
			LeaderstatsService.initPlayer(player)
			ToolService.giveAllCompletedTowerTools(player)
		end
	end)

	player.Team = Teams.Start
end

local PlayerService = {}

function PlayerService.Start()
	EVERPRESENT_COS.Parent = ServerStorage

	-- Use Observers for cleaner lifecycle management
	Observers.observePlayer(function(player)
		initializePlayer(player)

		-- Observe character spawns
		return Observers.observeCharacter(function(_, character)
			onCharacterAdded(character)
			return function() end
		end, { player })
	end, function(player)
		Session.remove(player.Name)
	end)

	-- Register network handlers
	BlinkServer.SetAllJumpsMode.On(onPlayerSetAllJumpsMode)
	BlinkServer.SetPracticeMode.On(onPlayerSetPracticeMode)
	BlinkServer.RequestEverpresentCOs.On(onEverpresentCOsRequested)
	BlinkServer.RestartRequested.On(onPlayerRestartRequested)
	BlinkServer.ExitTowerRequest.On(onExitTowerRequest)
end

function PlayerService.getSession(playerName: string): Types.PlayerInfo?
	return Session.get(playerName)
end

function PlayerService.getAllSessions()
	return Session.getAll()
end

function PlayerService.updateSession(playerName: string, updates: { [string]: any })
	Session.update(playerName, updates)
end

return PlayerService
