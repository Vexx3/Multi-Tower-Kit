--[=[
	Core server manager for individual tower lifecycle.

	Registers tower metadata from workspace folders, loads client objects,
	teleports players to tower spawn points, and exposes APIs for other
	services to trigger tower loads.

	@class TowerService
	@server
]=]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Data = Shared.Data

local Attributes = require(Shared.Attributes)
local BlinkServer = require("../Network/BlinkServer")
local Config = require(Data.Config)
local Log = require(ReplicatedStorage.Framework.Log)
local TowerData = require("../Player/PlayerData/TowerData")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local TOWERS = workspace.Towers
local CLIENT_OBJECTS_FOLDER = ServerStorage.TowerClientObjects
local TOWER_CHECKPOINTS = ServerStorage.TowerCheckpoints
local POINTER_TAG = "OBJ_POINTER"

local towers: { [string]: TowerInfo } = {}

local pointerTemplate: ObjectValue = Instance.new("ObjectValue")
pointerTemplate:AddTag(POINTER_TAG)

local pointerContainer = ReplicatedStorage:FindFirstChild("__POINTER_STORAGE")
if not pointerContainer then
	pointerContainer = Instance.new("Folder")
	pointerContainer.Name = "__POINTER_STORAGE"
	pointerContainer.Parent = ReplicatedStorage
end

local TowerService = {}

--- Loads a tower for a player, initializing their state and teleporting them.
--- @param player PlayerInfo -- The player to load the tower for
--- @param towerName string -- The acronym of the tower to load
--- @param resetTimer boolean -- Whether to reset the player's tower timer
function TowerService.loadTower(player: PlayerInfo, towerName: string, resetTimer: boolean)
	-- Get the player and tower info objects being referenced
	local tower: TowerInfo? = towers[towerName]
	if not tower then
		Log({
			type = "warn",
			[1] = `Unknown tower "{towerName}"`,
		})
		return
	end

	-- If the player is already currently loading a tower, don't do it twice
	if player.isLoadingTower then
		return
	end

	-- Set the player object's properties appropriately
	if resetTimer then
		player.towerTimer = 0
		player.boostItemUsed = false
		player.boostItemNames = {}
	end
	player.currentTower = towerName
	player.currentCheckpoint = 1
	-- "this player is currently loading a tower, do not attempt to load a tower while this tower loading is in progress"
	player.isLoadingTower = true

	TowerData.incrementTowerAttempt(player.player, towerName)

	-- Forcefully load the character
	-- should disrupt natural respawning
	Util.respawnAndTeleport(player.player, tower.spawnLocation)

	-- Delete the ClientSidedObjects folder from the player if it exists, which in this case, shouldn't
	local oldCOFolder: Instance? = player.player:FindFirstChild("ClientSidedObjects")
	if oldCOFolder then
		oldCOFolder:Destroy()
	end

	-- Send over the client objects if they exist
	-- (If they don't, the tower is truely purist)
	local purist = tower.clientObjects == nil
	if not purist and tower.clientObjects then
		local coFolder: Instance = tower.clientObjects:Clone()
		coFolder.Name = "ClientSidedObjects"
		coFolder.Parent = player.player
	end

	BlinkServer.LoadTower.Fire(player.player, towerName, purist, resetTimer)
end

local function initTower(towerFolder: Instance): TowerInfo?
	if not towerFolder:IsA("Folder") and not towerFolder:IsA("Model") then
		return nil
	end

	local acronym = towerFolder.Name

	-- Get the SpawnLocation
	local spawnLocation: Instance? = towerFolder:FindFirstChild("SpawnLocation")
	if not (spawnLocation and spawnLocation:IsA("BasePart")) then
		Log({
			type = "warn",
			[1] = `Skipping {acronym} because it does not have a SpawnLocation.`,
		})
		return nil
	end

	-- Get the ClientSidedObjects folder
	local clientObjects: Instance? = (
		towerFolder:FindFirstChild("ClientSidedObjects") or CLIENT_OBJECTS_FOLDER:FindFirstChild(acronym)
	)

	-- Get the Checkpoints
	local checkpointsFolder: Instance? = (
		towerFolder:FindFirstChild("Checkpoints") or TOWER_CHECKPOINTS:FindFirstChild(acronym)
	)
	-- The checkpoints exist but isn't in ServerStorage
	if checkpointsFolder and checkpointsFolder.Parent ~= TOWER_CHECKPOINTS then
		checkpointsFolder.Name = acronym
		checkpointsFolder.Parent = TOWER_CHECKPOINTS

		Log({
			type = "warn",
			[1] = `{acronym} is storing its checkpoints in the workspace! consider moving the checkpoints folder to ServerStorage.TowerCheckpoints`,
		})
	end

	local checkpointsList: { BasePart } = {}
	local checkpointCount = 0

	if checkpointsFolder then
		for index, _ in checkpointsFolder:GetChildren() do
			local checkpointIndex: string = tostring(index)
			local checkpoint: Instance? = checkpointsFolder:FindFirstChild(checkpointIndex)
			if not checkpoint then
				Log({
					type = "error",
					[1] = `{acronym} is missing checkpoint {checkpointIndex} in its Checkpoints folder!`,
				})
				return nil
			end
			if not checkpoint:IsA("BasePart") then
				Log({
					type = "error",
					[1] = `{acronym} has a non-BasePart ({checkpoint.Name}) in its Checkpoints folder!`,
				})
				return nil
			end

			table.insert(checkpointsList, checkpoint)
			checkpointCount += 1
		end
	end
	-- No checkpoints found, throw a warning
	if (checkpointCount == 0) and Config.checkpointsMissingWarning then
		Log({
			type = "warn",
			[1] = `{acronym} has no checkpoints!`,
		})
	end

	local realmTower = Util.getRealmTowerInfo(acronym)

	local towerNameString = acronym
	local towerDifficulty = "default"
	local towerBadgeId = 0

	if realmTower then
		if realmTower.name then
			towerNameString = realmTower.name
		end
		if realmTower.rating then
			local difficultyName: string? = Util.getDifficultyByRating(realmTower.rating)
			if difficultyName then
				towerDifficulty = difficultyName
			end
		end
		if realmTower.badgeId then
			towerBadgeId = realmTower.badgeId
		end
	end

	-- Construct the tower object
	local tower: TowerInfo = {
		name = towerNameString,
		difficulty = towerDifficulty,
		badgeId = towerBadgeId,
		ajBadgeId = Attributes.getInt(towerFolder, "AJBadgeID") or 0,
		towerPoints = Attributes.getInt(towerFolder, "TowerPoints") or 1,
		allJumpsPoints = Attributes.getInt(towerFolder, "AllJumpsPoints"),
		noBoosts = towerFolder:HasTag("NoBoosts"),

		folder = towerFolder,
		spawnLocation = spawnLocation :: BasePart,
		clientObjects = clientObjects,

		endings = {},

		minimumTime = Attributes.getNumber(towerFolder, "MinimumTime") or 0,
		checkpoints = checkpointsList,
		checkpointCount = checkpointCount,
	}
	-- If the tower has client objects (which it most likely has), send it to the COFolder
	if tower.clientObjects then
		tower.clientObjects.Name = acronym

		local version = tower.clientObjects:GetAttribute("KitVersion")

		for _, instance in tower.clientObjects:GetDescendants() do
			if instance:IsA("BasePart") and instance.CollisionGroup == "Default" then
				instance.CollisionGroup = "ClientObjects"
			elseif instance:IsA("ModuleScript") and version then
				if instance.Name == "ClientObjectScript" then
					continue
				end

				local thisPointer = pointerTemplate:Clone()
				thisPointer.Value = instance
				thisPointer.Name = instance.Name
				thisPointer.Parent = instance.Parent

				-- Move original module to storage to prevent cloning full source to every player
				instance.Name = `{acronym}_{instance.Name}_{HttpService:GenerateGUID(false):sub(1, 8)}`
				instance.Parent = pointerContainer

				-- Copy tags to pointer
				for _, tag: string in instance:GetTags() do
					thisPointer:AddTag(tag)
				end
			end
		end

		tower.clientObjects.Parent = CLIENT_OBJECTS_FOLDER
	end

	-- Having no minimum time is a security risk
	if tower.minimumTime == 0 and Config.noMinimumTimeWarning then
		Log({
			type = "warn",
			[1] = `{acronym} has no minimum time, it is vulnerable to being cheesed!`,
		})
	end

	-- Register the tower object
	towers[acronym] = tower

	return tower
end

local hasStarted = false

--- Registers all towers found in `workspace.Towers`, building the runtime metadata.
function TowerService.Start()
	if hasStarted then
		return
	end
	hasStarted = true

	for _, v in TOWERS:GetChildren() do
		initTower(v)
	end
end

--- Gets a tower by its acronym.
--- @param acronym string -- The tower's acronym (folder name)
--- @return TowerInfo? -- The tower info, or nil if not found
function TowerService.getTower(acronym: string): TowerInfo?
	return towers[acronym]
end

--- Gets all registered towers.
--- @return {[string]: TowerInfo} -- Map of tower acronyms to their info
function TowerService.getAllTowers(): { [string]: TowerInfo }
	return towers
end

return TowerService
