--[=[
	Core server manager for individual tower lifecycle: registers tower metadata,
	loads client objects, teleports players, and exposes simple APIs for other
	systems to load towers.

	@class TowerManager
	@server
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local TowerGame = ReplicatedStorage.TowerGame
local GameData = TowerGame.GameData
local Shared = TowerGame.Shared

local Attributes = require("../Helpers/Attributes")
local BlinkServer = require("../Network/BlinkServer")
local Config = require(GameData.Config)
local DataInfo = require("./DataInfo")
local TowerData = require("../Player/PlayerData/TowerData")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local TOWERS = workspace.Towers
local CLIENT_OBJECTS_FOLDER = ServerStorage.TowerClientObjects
local TOWER_CHECKPOINTS = ServerStorage.TowerCheckpoints

local TowerManager = {}

--[=[
	Load a tower for a player, cloning client objects, teleporting them to the
	spawn, and optionally resetting their timers and boost state.

	@within TowerManager
	@param resetTimer boolean -- true to reset tower timer and boost flags
]=]
function TowerManager.loadTower(playerName: string, towerName: string, resetTimer: boolean)
	-- Get the player and tower info objects being referenced
	local player: PlayerInfo? = DataInfo.PlayerInfo[playerName]
	if not player then
		return
	end

	local tower: TowerInfo? = DataInfo.TowerInfo[towerName]
	if not tower then
		Util.warn(`Unknown tower "{towerName}"`)
		return
	end

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

	TowerData.incrementTowerAttempt(player.Player, towerName)

	-- Forcefully load the character
	-- should disrupt natural respawning
	Util.respawnAndTeleport(player.Player, tower.SpawnLocation)

	-- Delete the ClientSidedObjects folder from the player if it exists, which in this case, shouldn't
	local oldCOFolder = player.Player:FindFirstChild("ClientSidedObjects")
	if oldCOFolder then
		oldCOFolder:Destroy()
	end

	-- Send over the client objects if they exist
	-- (If they don't, the tower is truely purist)
	local purist = tower.ClientObjects == nil
	if not purist and tower.ClientObjects then
		local coFolder = tower.ClientObjects:Clone()
		coFolder.Name = "ClientSidedObjects"
		coFolder.Parent = player.Player
	end

	BlinkServer.LoadTower.Fire(player.Player, towerName, purist, resetTimer)

	task.wait()
	player.IsLoadingTower = false
end

local function initTower(towerFolder: Instance)
	local acronym = towerFolder.Name

	-- Get the SpawnLocation
	local spawnLocation = towerFolder:FindFirstChild("SpawnLocation")
	assert(spawnLocation and spawnLocation:IsA("BasePart"), `{acronym} does not have a SpawnLocation!`)

	-- Get the ClientSidedObjects folder
	local clientObjects = (
		towerFolder:FindFirstChild("ClientSidedObjects") or CLIENT_OBJECTS_FOLDER:FindFirstChild(acronym)
	)

	-- Get the Checkpoints
	local checkpointsFolder = (towerFolder:FindFirstChild("Checkpoints") or TOWER_CHECKPOINTS:FindFirstChild(acronym))
	-- The checkpoints exist but isn't in ServerStorage
	if checkpointsFolder and checkpointsFolder.Parent ~= TOWER_CHECKPOINTS then
		checkpointsFolder.Name = acronym
		checkpointsFolder.Parent = TOWER_CHECKPOINTS

		if Config.CHECKPOINTS_WORKSPACE_WARNING then
			Util.warn(
				`{acronym} is storing its checkpoints in the workspace! consider moving the checkpoints folder to ServerStorage.TowerCheckpoints`
			)
		end
	end

	local checkpointsList = {}
	local checkpointCount = 0

	if checkpointsFolder then
		for index, _ in checkpointsFolder:GetChildren() do
			local checkpointIndex = tostring(index)
			local checkpoint = checkpointsFolder:FindFirstChild(checkpointIndex)
			assert(checkpoint, `Could not find checkpoint {checkpointIndex}`)
			assert(checkpoint:IsA("BasePart"), `Checkpoint {checkpointIndex} is not a BasePart`)

			table.insert(checkpointsList, checkpoint)
			checkpointCount += 1
		end
	end
	-- No checkpoints found, throw a warning
	if (checkpointCount == 0) and Config.CHECKPOINTS_MISSING_WARNING then
		Util.warn(`{acronym} has no checkpoints!`)
	end

	local realmTower = Util.getRealmTowerInfo(acronym)

	local towerName = acronym
	local towerDifficulty = "default"
	local towerBadgeID = 0

	if realmTower then
		if realmTower.Name then
			towerName = realmTower.Name
		end
		if realmTower.Rating then
			local difficultyName = Util.getDifficultyByRating(realmTower.Rating)
			if difficultyName then
				towerDifficulty = difficultyName
			end
		end
		if realmTower.BadgeID then
			towerBadgeID = realmTower.BadgeID
		end
	end

	-- Construct the tower object
	local tower: TowerInfo = {
		Name = towerName,
		Difficulty = towerDifficulty,
		BadgeID = towerBadgeID,
		AJBadgeID = Attributes.getInt(towerFolder, "AJBadgeID") or 0,
		TowerPoints = Attributes.getInt(towerFolder, "TowerPoints") or 1,
		AllJumpsPoints = Attributes.getInt(towerFolder, "AllJumpsPoints"),
		NoBoosts = towerFolder:HasTag("NoBoosts"),

		Folder = towerFolder,
		SpawnLocation = spawnLocation :: BasePart,
		ClientObjects = clientObjects,

		Endings = {},

		MinimumTime = Attributes.getNumber(towerFolder, "MinimumTime") or 0,
		Checkpoints = checkpointsList,
		CheckpointCount = checkpointCount,
	}
	-- If the tower has client objects (which it most likely has), send it to the COFolder
	if tower.ClientObjects then
		tower.ClientObjects.Name = acronym

		for _, instance in tower.ClientObjects:GetDescendants() do
			if instance:IsA("BasePart") and instance.CollisionGroup == "Default" then
				instance.CollisionGroup = "ClientObjects"
			end
		end

		tower.ClientObjects.Parent = CLIENT_OBJECTS_FOLDER
	end

	-- Having no minimum time is a security risk
	if tower.MinimumTime == 0 and Config.NO_MINIMUM_TIME_WARNING then
		Util.warn(`{acronym} has no minimum time, it is vulnerable to being cheesed!`)
	end

	-- Register the tower object
	DataInfo.TowerInfo[acronym] = tower

	return tower
end

-- Register all towers found in `workspace.Towers`, building the runtime
-- metadata used elsewhere by MTK.
function TowerManager.initTowers()
	for _, v in TOWERS:GetChildren() do
		initTower(v)
	end
end

return TowerManager
