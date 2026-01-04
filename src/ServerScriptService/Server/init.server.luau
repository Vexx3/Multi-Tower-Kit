--[=[
	Main server entry point for Multi-Tower Kit. Handles player state, tower loading,
	winpad detection, and coordinates all MTK subsystems.

	@server
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")
local Teams = game:GetService("Teams")

local GameData = ReplicatedStorage.GameData
local Shared = ReplicatedStorage.Shared

local BlinkServer = require("@self/Network/BlinkServer")
local Config = require(GameData.Config)
local DataInfo = require("@self/Game/DataInfo")
local LeaderstatsManager = require("@self/Player/LeaderstatsManager")
local ModuleLoader = require(Shared.ModuleLoader)
local PlayerState = require("@self/Player/PlayerState")
local PortalHandler = require("@self/Game/PortalHandler")
local ToolManager = require("@self/Helpers/ToolManager")
local TowerData = require("@self/Player/PlayerData/TowerData")
local TowerManager = require("@self/Game/TowerManager")
local TowerRushManager = require("@self/Game/TowerRushManager")
local TowerRushes = require(ReplicatedStorage.RealmData.TowerRushes)
local TowerSignManager = require("@self/Game/TowerSignManager")
local Types = require(Shared.Types)
local Util = require(Shared.Util)
local WinpadManager = require("@self/Game/WinpadManager")

type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local TOWERS = workspace:FindFirstChild("Towers")
local MARKERS = workspace:FindFirstChild("Markers")
local STARTER_PACK_STUDIO = ServerStorage:FindFirstChild("StarterPackStudio")
local EVERPRESENT_COS = TOWERS:FindFirstChild("EverpresentCOs")
local WINPAD_MATERIALS = Enum.Material:GetEnumItems()

local function onEverpresentCOsRequested(playerInstance: Player): (boolean, Folder?)
	local player: PlayerInfo? = DataInfo.PlayerInfo[playerInstance.Name]
	if not player then
		return false, nil
	end

	if player.HasEverpresentCOs then
		return false, nil
	end

	local playerECOs = EVERPRESENT_COS:Clone() :: Folder
	playerECOs.Parent = playerInstance
	player.HasEverpresentCOs = true

	return true, playerECOs
end

local function onPlayerRestartRequested(playerInstance: Player)
	local player: PlayerInfo = DataInfo.PlayerInfo[playerInstance.Name]
	if not player then
		return
	end

	-- If the player is attempting to restart after the cooldown has ended
	if player.GameTimer - player.LastRestart >= Config.RESTART_COOLDOWN then
		player.LastRestart = player.GameTimer
		-- The player isn't even in a tower
		if player.CurrentTower == "" then
			return
		end

		TowerData:AddTowerTimeSpent(player.Player, player.CurrentTower, player.TowerTimer)

		if player.CurrentTowerRush == "" then
			TowerManager:LoadTower(playerInstance.Name, player.CurrentTower, true)
		else
			TowerRushManager:LoadTowerRush(playerInstance.Name, player.CurrentTowerRush)
		end
	end
end

local function onPlayerEquippedTool(player: PlayerInfo, item: Tool)
	if player.CurrentTower == "" then
		return
	end

	local isDebugItem = item:GetAttribute("DebugItem") :: boolean?
	local boostName = item:GetAttribute("BoostName") :: string?
	local hasBoost = boostName ~= nil and boostName ~= ""

	if isDebugItem or hasBoost then
		player.DebugItemUsed = true
	end

	if not hasBoost then
		return
	end

	player.BoostItemUsed = true
	player.BoostItemNames[item.Name] = boostName or "Boost Item"

	if player.CurrentTowerRush ~= "" then
		local rush = TowerRushes[player.CurrentTowerRush]
		if rush and rush.NoBoostItems then
			local character = player.Player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
	end
end

local function initMarker(marker: BasePart)
	if marker.Name == "LobbyTP" then
		local spawnLocation = MARKERS:WaitForChild("SpawnLocation")
		assert(
			spawnLocation and spawnLocation:IsA("BasePart"),
			"Could not initialize LobbyTP because a SpawnLocation couldn't be found"
		)

		Util:RegisterTouch(marker, function(playerName)
			local player: PlayerInfo = DataInfo.PlayerInfo[playerName]
			player.Player.Team = Teams.Start
			Util:TeleportPlayerToPart(player.Player, spawnLocation)
		end)
	end
end

local function initMarkers()
	for _, child in MARKERS:GetChildren() do
		if child:IsA("BasePart") then
			initMarker(child)
		end
	end
end

local function onCharacterAdded(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 and Config.R15_WARNING then
		Util:Warn(
			"Character spawned with R15 rig type, most obbying techniques are impossible. Ensure that the rig type is R6 in game settings."
		)
	end

	local player: PlayerInfo? = DataInfo.PlayerInfo[character.Name]
	if player then
		if player.Player.Team ~= Teams.Winners then
			player.Player.Team = Teams.Start
		end

		character.ChildAdded:Connect(function(item)
			if item:IsA("Tool") then
				onPlayerEquippedTool(player, item)
			end
		end)

		if player.IsLoadingTower then
			return
		end

		BlinkServer.UnloadTower.Fire(player.Player)
		PlayerState:ResetPlayerInfo(player)
	end
end

local function onPlayerAdded(player: Player)
	local info: PlayerInfo = {
		Player = player,
		GameTimer = 0,
		LastRestart = 0,

		CurrentTower = "",
		CurrentTowerCheckpoint = 0,
		BoostItemNames = {},
		BoostItemUsed = false,
		TowerTimer = 0,
		AllJumpsMode = false,
		PracticeMode = false,

		CurrentTowerRush = "",
		CurrentTowerRushIndex = 0,

		TouchEventBusy = false,
		IsLoadingTower = false,
		HasEverpresentCOs = false,
		DebugItemUsed = false,
	}

	PlayerState:UpdatePlayerInfoStats(info)

	DataInfo.PlayerInfo[player.Name] = info

	LeaderstatsManager:InitPlayer(player)
	TowerSignManager:UpdateCompletedTowersForPlayer(player)
	ToolManager:GiveAllCompletedTowerTools(player)

	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.Team = Teams.Start
	player.CharacterAdded:Connect(onCharacterAdded)
end

local function onPlayerRemoving(player: Player)
	DataInfo.PlayerInfo[player.Name] = nil
end

local function onStepped(_time: number, deltaTime: number)
	for _, v in DataInfo.PlayerInfo do
		-- Increment the time spent ingame..
		-- and the time spend in the tower, if in one
		v.GameTimer += deltaTime
		if v.CurrentTower ~= "" then
			local oldTowerTimer = v.TowerTimer
			v.TowerTimer += deltaTime

			local i = Config.TIMER_SYNC_INTERVAL
			local a = math.floor(oldTowerTimer / i) * i
			local b = math.floor(v.TowerTimer / i) * i
			if b > a then
				BlinkServer.UpdateTowerTimer.Fire(v.Player, v.TowerTimer)
			end
		end

		-- Update the Player Attributes
		PlayerState:UpdatePlayerInfoStats(v)

		-- Checkpoint detection
		local prevInterval = math.floor((_time - deltaTime) / Config.CHECKPOINT_INTERVAL) * Config.CHECKPOINT_INTERVAL
		local currentInterval = math.floor(_time / Config.CHECKPOINT_INTERVAL) * Config.CHECKPOINT_INTERVAL
		if prevInterval < currentInterval then
			local Character = v.Player.Character
			-- If the player is in a tower
			if v.CurrentTower ~= "" and Character then
				local tower: TowerInfo = DataInfo.TowerInfo[v.CurrentTower]
				local checkpoint: BasePart? = tower.Checkpoints[v.CurrentTowerCheckpoint]
				if checkpoint then
					local point = Character:GetPivot().Position
					local touching = Util:IsPointInPart(point, checkpoint)
					if touching then
						v.CurrentTowerCheckpoint += 1
					end
				end
			end
		end
	end

	-- Winpad animation
	do
		-- If the animation time of a winpad has passed
		local prevInterval = math.floor((_time - deltaTime) / Config.WINPAD_INTERVAL) * Config.WINPAD_INTERVAL
		local currentInterval = math.floor(_time / Config.WINPAD_INTERVAL) * Config.WINPAD_INTERVAL
		if prevInterval < currentInterval then
			for _, winpad in WinpadManager.Winpads do
				if Config.WINPADS_CHANGE_COLOR then
					winpad.Color = Color3.fromHSV(math.random(0, 100) / 100, 1, 1)
				end

				if Config.WINPADS_CHANGE_MATERIAL then
					winpad.Material = WINPAD_MATERIALS[math.random(1, #WINPAD_MATERIALS)]
				end
			end
		end
	end
end

-- Initialize all systems
local function init()
	if RunService:IsStudio() then
		for _, tool in STARTER_PACK_STUDIO:GetChildren() do
			tool:SetAttribute("DebugItem", true)
			tool.Parent = StarterPack
		end
	end

	for _, tool in StarterPack:GetChildren() do
		if not tool:IsA("Tool") then
			continue
		end

		local boostNameValue = tool:FindFirstChild("BoostName")
		if boostNameValue and boostNameValue:IsA("StringValue") then
			Util:Warn(
				`Boost item {tool.Name} uses a StringValue for BoostName, please change it to an attribute, as a StringValue can be manipulated (or even deleted by client)`
			)
			tool:SetAttribute("BoostName", boostNameValue.Value)
		end
	end

	EVERPRESENT_COS.Parent = ServerStorage

	TowerManager:InitTowers()
	WinpadManager:InitWinpads()
	PortalHandler:InitPortals()
	initMarkers()

	-- Load and initialize all other modules (excluding Network folder)
	ModuleLoader.LoadAndInit(script, { script.Network })

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	BlinkServer.RestartRequested.On(onPlayerRestartRequested)
	BlinkServer.RequestEverpresentCOs.On(onEverpresentCOsRequested)
	RunService.Stepped:Connect(onStepped)
end

init()
