--!strict
-- Written by fanofpixels

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")
local Teams = game:GetService("Teams")

local Shared = ReplicatedStorage.Shared

-- Get the cool types
local Types = require(Shared.Types)
type List<T> = Types.List<T>
type Dictionary<T> = Types.Dictionary<T>
type PlayerInfo = Types.PlayerInfo
type TowerRush = Types.TowerRush
type TowerInfo = Types.TowerInfo
type EndingInfo = Types.EndingInfo
type Difficulty = Types.DifficultyInfo

-- Modules
local LeaderstatsManager = require(".././Core/LeaderstatsManager")
local PlayerData = require(".././Core/PlayerData")
local PlayerState = require(".././Core/PlayerState")
local PortalHandler = require("@self/PortalHandler")
local Teleport = require(".././Utils/Teleport")
local TowerManager = require("@self/TowerManager")
local Util = require(Shared.Util)
local WinpadManager = require("@self/WinpadManager")
local ZapServer = require(ServerScriptService.ZapServer)

-- Folders
local TowerFolder = workspace:FindFirstChild("Towers")
local Markers = workspace:FindFirstChild("Markers")
local StarterPackStudio = ServerStorage:FindFirstChild("StarterPackStudio")
local EverpresentCOs = TowerFolder:FindFirstChild("EverpresentCOs")

-- Game data (including modules supplying)
local Config = require(ReplicatedStorage.GameData.Config)
local DataInfo = require("@self/DataInfo")
local WinpadMaterials: List<Enum.Material> = Enum.Material:GetEnumItems()

local MTK = {}
MTK.TowerManager = TowerManager

local function EverpresentCOsRequested(playerInstance: Player): (boolean, Folder?)
	local player: PlayerInfo? = DataInfo.PlayerInfo[playerInstance.Name]
	if not player then
		return false, nil
	end

	-- Prevent prevent potential DOS attack lol
	if player.HasEverpresentCOs then
		return false, nil
	end

	local playerECOs = EverpresentCOs:Clone() :: Folder
	playerECOs.Parent = playerInstance
	player.HasEverpresentCOs = true

	return true, playerECOs
end

local function PlayerRequestedRestart(playerInstance: Player)
	local player: PlayerInfo = DataInfo.PlayerInfo[playerInstance.Name]

	-- If the player is attempting to restart after the cooldown has ended
	if player.GameTimer - player.LastRestart >= Config.RESTART_COOLDOWN then
		player.LastRestart = player.GameTimer
		-- The player isn't even in a tower
		if player.CurrentTower == "" then
			return
		end

		if player.CurrentTowerRush == "" then
			TowerManager:PlayerLoadTower(playerInstance.Name, player.CurrentTower, true)
		else
			TowerManager:PlayerLoadTowerRush(playerInstance.Name, player.CurrentTowerRush)
		end
	end
end

local function PlayerEquippedTool(player: PlayerInfo, item: Tool)
	local isDebugItem = item:GetAttribute("DebugItem") :: boolean?
	local boostName = item:GetAttribute("BoostName") :: string?

	local boostUsed = if boostName ~= "" then true else false
	-- If this is a debug item OR a boost item, we should effectively disable checkpoints
	-- Because boosts and debug items let a player fairly bypass checkpoints, so if they do equip an item, it would be unreasonable to kick them
	if isDebugItem or boostUsed then
		player.DebugItemUsed = true
	end
	if boostUsed then
		player.BoostItemUsed = true
		player.BoostItemNames[item.Name] = boostName or "Boost Item"
	end
end

local function InitMarker(marker: BasePart)
	if marker.Name == "LobbyTP" then
		-- Find the lobby spawn
		local spawnLocation = Markers:WaitForChild("SpawnLocation")
		assert(spawnLocation and spawnLocation:IsA("BasePart"), "Could not intialize LobbyTP because a SpawnLocation couldn't be found")

		-- When touched, teleport the player to the lobby spawn
		Util:RegisterTouch(marker, function(playerName)
			local player: PlayerInfo = DataInfo.PlayerInfo[playerName]
			player.Player.Team = Teams.Start
			Teleport:TeleportPlayerToPart(player.Player, spawnLocation)
		end)
	end
end

local function InitMarkers()
	for _, v in Markers:GetChildren() do
		if v:IsA("BasePart") then
			InitMarker(v)
		end
	end
end

local function CharacterAdded(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 and Config.R15_WARNING then
		Util:Warn(
			"Character spawned with R15 rig type, most obbying techniques are impossible. Ensure that the rig type is R6 in game settings."
		)
	end

	local player: PlayerInfo? = DataInfo.PlayerInfo[character.Name]
	if player then
		player.Player.Team = Teams.Start

		-- When the player equips a tool
		character.ChildAdded:Connect(function(item)
			if item:IsA("Tool") then
				PlayerEquippedTool(player, item)
			end
		end)

		-- If the player is simply loading a tower in, we shouldn't be immediately unloading stuff, so don't
		if player.IsLoadingTower then
			return
		end

		-- No need to call other events like UpdateTowerRush as the client will do so automatically
		ZapServer.UnloadTower.Fire(player.Player)
		PlayerState:ResetPlayerInfo(player)
	end
end

local function PlayerAdded(player: Player)
	local info: PlayerInfo = {
		Player = player,
		GameTimer = 0,
		LastRestart = 0,

		CurrentTower = "",
		CurrentTowerCheckpoint = 0,
		BoostItemNames = {},
		BoostItemUsed = false,
		TowerTimer = 0,

		CurrentTowerRush = "",
		CurrentTowerRushIndex = 0,

		TouchEventBusy = false,
		IsLoadingTower = false,
		HasEverpresentCOs = false,
		DebugItemUsed = false,
	}

	PlayerState:UpdatePlayerInfoStats(info)

	DataInfo.PlayerInfo[player.Name] = info

	-- wait for data
	while not PlayerData:GetData(player) do
		task.wait()
	end

	LeaderstatsManager:InitPlayer(player)

	if player.Character then
		CharacterAdded(player.Character)
	end
	player.Team = Teams.Start
	player.CharacterAdded:Connect(CharacterAdded)
end

local function PlayerRemoving(player: Player)
	DataInfo.PlayerInfo[player.Name] = nil
end

local function Stepped(_time: number, deltaTime: number)
	-- For every player
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
				ZapServer.UpdateTowerTimer.Fire(v.Player, v.TowerTimer)
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
			for _, v in WinpadManager.Winpads do
				if Config.WINPADS_CHANGE_COLOR then
					v.Color = Color3.fromHSV(math.random(0, 100) / 100, 1, 1)
				end

				if Config.WINPADS_CHANGE_MATERIAL then
					v.Material = WinpadMaterials[math.random(1, #WinpadMaterials)]
				end
			end
		end
	end
end

function MTK:Init()
	if RunService:IsStudio() then
		for _, v in StarterPackStudio:GetChildren() do
			v:SetAttribute("DebugItem", true)
			v.Parent = StarterPack
		end
	end
	
	-- Make sure all tools are tagged with the attribute, since a StringValue isn't secure
	for _, v in StarterPack:GetChildren() do
		if not v:IsA("Tool") then
			continue
		end

		local boostNameValue = v:FindFirstChild("BoostName")
		if boostNameValue and boostNameValue:IsA("StringValue") then
			Util:Warn(
				`Boost item {v.Name} uses a StringValue for BoostName, please change it to an attribute, as a StringValue can be manipulated (or even deleted by client)`
			)
			v:SetAttribute("BoostName", boostNameValue.Value)
		end
	end

	EverpresentCOs.Parent = ServerStorage :: any

	TowerManager:InitTowers()
	PortalHandler:InitPortals()
	InitMarkers()

	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(PlayerRemoving)
	ZapServer.RestartRequested.SetCallback(PlayerRequestedRestart)
	ZapServer.RequestEverpresentCOs.SetCallback(EverpresentCOsRequested)
	RunService.Stepped:Connect(Stepped)
end

return MTK
