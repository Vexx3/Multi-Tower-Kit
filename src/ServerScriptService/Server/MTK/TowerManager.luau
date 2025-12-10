--!strict
--[=[
	Core server manager for individual tower lifecycle: registers tower metadata,
	loads client objects, teleports players, and exposes simple APIs for other
	systems to load towers.

	@class TowerManager
	@server
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameData = ReplicatedStorage.GameData
local Shared = ReplicatedStorage.Shared

local Attributes = require("../Utils/Attributes")
local Config = require(GameData.Config)
local DataInfo = require("./DataInfo")
local TowerData = require("../Core/PlayerData/TowerData")
local Types = require(Shared.Types)
local Util = require(Shared.Util)
local ZapServer = require("../../ZapServer")

type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local Towers = workspace.Towers
local ClientObjectsFolder = ServerStorage.TowerClientObjects
local TowerCheckpoints = ServerStorage.TowerCheckpoints

local TowerManager = {}

--[=[
	Load a tower for a player, cloning client objects, teleporting them to the
	spawn, and optionally resetting their timers and boost state.

	@within TowerManager
	@param resetTimer boolean -- true to reset tower timer and boost flags
]=]
function TowerManager:LoadTower(playerName: string, towerName: string, resetTimer: boolean)
	-- Get the player and tower info objects being referenced
	local player: PlayerInfo? = DataInfo.PlayerInfo[playerName]
	local tower: TowerInfo? = DataInfo.TowerInfo[towerName]
	if player and tower then
		-- If the player is already currently loading a tower, don't do it twice
		if player.IsLoadingTower then
			return
		end

		-- Set the player object's properties appropriately
		if resetTimer then
			player.TowerTimer = 0
			player.BoostItemUsed = false
			player.BoostItemNames = {}
		end
		player.CurrentTower = towerName
		player.CurrentTowerCheckpoint = 1
		-- "this player is currently loading a tower, do not attempt to load a tower while this tower loading is in progress"
		player.IsLoadingTower = true

		TowerData:IncrementTowerAttempt(player.Player, towerName)

		-- Forcefully load the character
		-- should disrupt natural respawning
		Util:RespawnAndTeleport(player.Player, tower.SpawnLocation)

		-- Delete the ClientSidedObjects folder from the player if it exists, which in this case, shouldn't
		local oldCOFolder = player.Player:FindFirstChild("ClientSidedObjects")
		if oldCOFolder then
			oldCOFolder:Destroy()
		end

		-- Send over the client objects if they exist
		-- (If they don't, the tower is truely purist)
		local purist = true
		if tower.ClientObjects then
			purist = false
			local coFolder = tower.ClientObjects:Clone()
			coFolder.Name = "ClientSidedObjects"
			coFolder.Parent = player.Player
		end

		ZapServer.LoadTower.Fire(player.Player, towerName, purist, resetTimer)
		player.IsLoadingTower = false
	end

	if not tower then
		Util:Warn(`Unknown tower "{towerName}"`)
	end
end

local function InitTower(towerFolder: Instance)
	local acronym = towerFolder.Name

	-- Get the SpawnLocation
	local spawnLocation = towerFolder:FindFirstChild("SpawnLocation")
	assert(
		spawnLocation and spawnLocation:IsA("BasePart"),
		`{acronym} does not have a SpawnLocation!`
	)

	-- Get the ClientSidedObjects folder
	local clientObjects = (
		towerFolder:FindFirstChild("ClientSidedObjects")
		or ClientObjectsFolder:FindFirstChild(acronym)
	)

	-- Get the Checkpoints
	local checkpointsFolder = (
		towerFolder:FindFirstChild("Checkpoints") or TowerCheckpoints:FindFirstChild(acronym)
	)
	-- The checkpoints exist but isn't in ServerStorage
	if checkpointsFolder and checkpointsFolder.Parent ~= TowerCheckpoints then
		checkpointsFolder.Name = acronym
		checkpointsFolder.Parent = TowerCheckpoints

		if Config.CHECKPOINTS_WORKSPACE_WARNING then
			Util:Warn(
				`{acronym} is storing it's checkpoints in the workspace! consider moving the checkpoints folder to ServerStorage.TowerCheckpoints`
			)
		end
	end

	local checkpointsList = {}
	local checkpointCount = 0

	if checkpointsFolder then
		-- There is a checkpoints folder! get it's contents
		for k, _ in checkpointsFolder:GetChildren() do
			local checkpointName = tostring(k)
			local checkpoint = checkpointsFolder:FindFirstChild(checkpointName)
			assert(checkpoint, `Could not find checkpoint {checkpointName}`)
			assert(checkpoint:IsA("BasePart"), `Checkpoint {checkpointName} is not a BasePart`)

			table.insert(checkpointsList, checkpoint)
			checkpointCount += 1
		end
	end
	-- No checkpoints found, throw a warning
	if (checkpointCount == 0) and Config.CHECKPOINTS_MISSING_WARNING then
		Util:Warn(`{acronym} has no checkpoints!`)
	end

	-- Construct the tower object
	local tower: TowerInfo = {
		Name = Attributes:GetString(towerFolder, "ProperName") or acronym,
		Difficulty = Attributes:GetString(towerFolder, "Difficulty") or "default",
		BadgeID = Attributes:GetInt(towerFolder, "BadgeID") or 0,
		AJBadgeID = Attributes:GetInt(towerFolder, "AJBadgeID") or 0,
		TowerPoints = Attributes:GetInt(towerFolder, "TowerPoints") or 1,
		NoBoostItems = towerFolder:FindFirstChild("NoBoostItems") ~= nil,

		Folder = towerFolder,
		SpawnLocation = spawnLocation :: BasePart,
		ClientObjects = clientObjects,

		Endings = {},

		MinimumTime = Attributes:GetNumber(towerFolder, "MinimumTime") or 0,
		Checkpoints = checkpointsList,
		CheckpointCount = checkpointCount,
	}
	-- If the tower has client objects (which it most likely has), send it to the COFolder
	if tower.ClientObjects then
		tower.ClientObjects.Name = acronym

		-- v6 collision groups
		for _, instance in tower.ClientObjects:GetDescendants() do
			if instance:IsA("BasePart") then
				if instance.CollisionGroup == "Default" then
					instance.CollisionGroup = "ClientObjects"
				end
			end
		end

		tower.ClientObjects.Parent = ClientObjectsFolder
	end

	-- Having no minimum time is a security risk, warn the user for that
	if tower.MinimumTime == 0 and Config.NO_MINIMUM_TIME_WARNING then
		Util:Warn(`{acronym} has no minumum time, it is vulnerable to being cheesed!`)
	end

	-- Register the tower object
	DataInfo.TowerInfo[acronym] = tower

	return tower
end

-- Register all towers found in `workspace.Towers`, building the runtime
-- metadata used elsewhere by MTK.
function TowerManager:InitTowers()
	for _, v in Towers:GetChildren() do
		InitTower(v)
	end
end

return TowerManager
