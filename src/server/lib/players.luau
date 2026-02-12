--[[
	Player lifecycle and session management.
	Uses sessionStore for state, Observers for lifecycle.
]]

local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local BlinkServer = require("../Network/BlinkServer")
local Config = require("../../shared/constants/config")
local Log = require("../../../Framework/Log")
local Observers = require("../../../Packages/observers")
local Promise = require("../../../Packages/promise")
local Types = require("../../shared/types")
local Util = require("../../shared/utils/util")
local accounts = require("../accounts")
local allJumps = require("../gameplay/allJumps")
local leaderstats = require("./leaderstats")
local playerState = require("./playerState")
local sessionStore = require("../stores/sessionStore")
local tools = require("../gameplay/tools")
local towerRush = require("../gameplay/towerRush")
local towers = require("../gameplay/towers")

local EVERPRESENT_COS: Folder
local MARKERS = workspace:WaitForChild("Markers") :: Folder

local function onEverpresentCOsRequested(playerInstance: Player): (boolean, Folder?)
	local player = sessionStore.get(playerInstance.Name)
	if not player or player.hasEverpresentCOs then
		return false, nil
	end

	local playerECOs = EVERPRESENT_COS:Clone() :: Folder
	playerECOs.Parent = playerInstance
	sessionStore.update(playerInstance.Name, { hasEverpresentCOs = true })

	return true, playerECOs
end

local function onPlayerRestartRequested(playerInstance: Player)
	local player = sessionStore.get(playerInstance.Name)
	if not player or (player.gameTimer - player.lastRestart < Config.restartCooldown) then
		return
	end

	sessionStore.update(playerInstance.Name, { lastRestart = player.gameTimer })

	accounts.addTowerTimeSpent(player.player, player.currentTower, player.towerTimer)
	allJumps.clearCheckpoint(playerInstance.Name)

	if player.currentTowerRush == "" then
		towers.loadTower(player, player.currentTower, true)
	else
		towerRush.loadTowerRush(player, player.currentTowerRush)
	end
end

local function onExitTowerRequest(playerInstance: Player)
	local player = sessionStore.get(playerInstance.Name)
	if not player or player.currentTower == "" then
		return
	end

	accounts.addTowerTimeSpent(player.player, player.currentTower, player.towerTimer)
	allJumps.clearCheckpoint(playerInstance.Name)

	local spawnLocation = MARKERS:FindFirstChild("SpawnLocation", true) :: BasePart?

	player.player.Team = Teams.Start
	BlinkServer.UnloadTower.Fire(player.player)
	sessionStore.resetRun(playerInstance.Name)
	playerState.updatePlayerInfoStats(player)

	if spawnLocation and spawnLocation:IsA("BasePart") then
		Util.respawnAndTeleport(player.player, spawnLocation)
	else
		player.player:LoadCharacterAsync()
	end
end

local function setPlayerMode(playerInstance: Player, mode: Types.PlayerMode)
	local player = sessionStore.get(playerInstance.Name)
	if not player then
		return
	end

	if player.currentTower ~= "" then
		accounts.addTowerTimeSpent(player.player, player.currentTower, player.towerTimer)
		sessionStore.setMode(playerInstance.Name, mode)

		if player.currentTowerRush == "" then
			towers.loadTower(player, player.currentTower, true)
		else
			towerRush.loadTowerRush(player, player.currentTowerRush)
		end
	else
		sessionStore.setMode(playerInstance.Name, mode)
	end

	playerState.updatePlayerInfoStats(player)
end

local function onPlayerSetAllJumpsMode(playerInstance: Player, enabled: boolean)
	setPlayerMode(playerInstance, if enabled then "AllJumps" else "Normal")
end

local function onPlayerSetPracticeMode(playerInstance: Player, enabled: boolean)
	setPlayerMode(playerInstance, if enabled then "Practice" else "Normal")
end

local function setupHealthMonitoring(playerName: string, humanoid: Humanoid)
	humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		local playerInfo = sessionStore.get(playerName)
		if not playerInfo or playerInfo.mode ~= "AllJumps" or humanoid.Health > 0 then
			return
		end

		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		humanoid.Health = humanoid.MaxHealth

		local tower = towers.getTower(playerInfo.currentTower)
		if tower then
			allJumps.teleportToCheckpoint(playerInfo, tower)
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
	local player = sessionStore.get(character.Name)
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
			tools.handleToolEquipped(player, item)
		end
	end)

	setupHealthMonitoring(character.Name, humanoid)

	if player.isLoadingTower then
		sessionStore.finishLoading(character.Name)
		return
	end

	if player.mode == "AllJumps" and player.currentTower ~= "" then
		local tower = towers.getTower(player.currentTower)
		if tower then
			allJumps.teleportToCheckpoint(player, tower)
		end
		return
	end

	if player.currentTower ~= "" then
		accounts.addTowerTimeSpent(player.player, player.currentTower, player.towerTimer)
	end

	BlinkServer.UnloadTower.Fire(player.player)
	sessionStore.resetRun(character.Name)
	playerState.updatePlayerInfoStats(player)
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

	sessionStore.add(player.Name, info)
	playerState.updatePlayerInfoStats(info)

	Promise.new(function(resolve)
		accounts.waitForData(player)
		resolve()
	end):andThen(function()
		if player.Parent then
			leaderstats.initPlayer(player)
			tools.giveAllCompletedTowerTools(player)
		end
	end)

	player.Team = Teams.Start
end

local players = {}

--- Initializes player lifecycle management.
function players.init()
	EVERPRESENT_COS = ServerStorage:WaitForChild("EverpresentCOs") :: Folder

	Observers.observePlayer(function(player)
		initializePlayer(player)

		return Observers.observeCharacter(function(_, character)
			onCharacterAdded(character)
			return function() end
		end, { player })
	end, function(player)
		sessionStore.remove(player.Name)
	end)

	BlinkServer.SetAllJumpsMode.On(onPlayerSetAllJumpsMode)
	BlinkServer.SetPracticeMode.On(onPlayerSetPracticeMode)
	BlinkServer.RequestEverpresentCOs.On(onEverpresentCOsRequested)
	BlinkServer.RestartRequested.On(onPlayerRestartRequested)
	BlinkServer.ExitTowerRequest.On(onExitTowerRequest)
end

function players.getSession(playerName: string): Types.PlayerInfo?
	return sessionStore.get(playerName)
end

function players.getAllSessions()
	return sessionStore.getAll()
end

function players.updateSession(playerName: string, updates: { [string]: any })
	sessionStore.update(playerName, updates)
end

return players
