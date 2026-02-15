--[[
	Core tower lifecycle: registration, metadata building, and loading.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Attributes = require("../../shared/attributes")
local BlinkServer = require("../Network/BlinkServer")
local Config = require("../../shared/constants/config")
local Hooks = require("../../shared/hooks")
local Log = require("../../../Framework/Log")
local Types = require("../../shared/types")
local Util = require("../../shared/utils/util")
local accounts = require("../accounts")
local practiceTools = require("./practiceTools")
local sessionStore = require("../stores/sessionStore")

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

--- Loads a tower for a player, updating session state and replicating client objects.
local function loadTower(player: PlayerInfo, towerName: string, resetTimer: boolean)
	local tower: TowerInfo? = towers[towerName]
	if not tower then
		Log({ type = "warn", [1] = `Unknown tower "{towerName}"` })
		return
	end

	if player.isLoadingTower then
		return
	end

	sessionStore.setTower(player.player.Name, towerName, resetTimer)

	accounts.incrementTowerAttempt(player.player, towerName)
	Util.respawnAndTeleport(player.player, tower.spawnLocation)

	local oldCOFolder: Instance? = player.player:FindFirstChild("ClientSidedObjects")
	if oldCOFolder then
		oldCOFolder:Destroy()
	end

	local purist = tower.clientObjects == nil
	if not purist and tower.clientObjects then
		local coFolder: Instance = tower.clientObjects:Clone()
		coFolder.Name = "ClientSidedObjects"
		coFolder.Parent = player.player
	end

	BlinkServer.LoadTower.Fire(player.player, towerName, purist, resetTimer)
	Hooks.fire("TowerLoaded", player.player, towerName)

	-- Give practice tools when entering a tower in Practice mode
	local freshSession = sessionStore.get(player.player.Name)
	if freshSession and freshSession.mode == "Practice" then
		practiceTools.give(player.player)
	else
		practiceTools.remove(player.player)
	end
end

local function initTower(towerFolder: Instance): TowerInfo?
	if not towerFolder:IsA("Folder") and not towerFolder:IsA("Model") then
		return nil
	end

	local acronym = towerFolder.Name

	local spawnLocation: Instance? = towerFolder:FindFirstChild("SpawnLocation")
	if not (spawnLocation and spawnLocation:IsA("BasePart")) then
		Log({
			type = "warn",
			[1] = `Skipping {acronym} because it does not have a SpawnLocation.`,
		})
		return nil
	end

	local clientObjects: Instance? = (
		towerFolder:FindFirstChild("ClientSidedObjects") or CLIENT_OBJECTS_FOLDER:FindFirstChild(acronym)
	)

	local checkpointsFolder: Instance? = (
		towerFolder:FindFirstChild("Checkpoints") or TOWER_CHECKPOINTS:FindFirstChild(acronym)
	)
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
			local checkpointIndex = tostring(index)
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
	if (checkpointCount == 0) and Config.checkpointsMissingWarning then
		Log({
			type = "warn",
			[1] = `{acronym} has no checkpoints!`,
		})
	end

	local realmTower: Types.RealmTowerInfo? = Util.getRealmTowerInfo(acronym)

	local towerNameString = acronym
	local towerDifficulty = "default"
	local towerBadgeId = 0

	if realmTower then
		if realmTower.name then
			towerNameString = realmTower.name
		end
		if realmTower.rating then
			local difficultyName = Util.getDifficultyByRating(realmTower.rating)
			if difficultyName then
				towerDifficulty = difficultyName
			end
		end
		if realmTower.badgeId then
			towerBadgeId = realmTower.badgeId
		end
	end

	local configFolder = towerFolder:FindFirstChild("Configuration")
	local minimumTimeSource = configFolder or towerFolder

	local tower: TowerInfo = {
		name = towerNameString,
		difficulty = towerDifficulty,
		badgeId = towerBadgeId,
		ajBadgeId = Attributes.getInt(towerFolder, "AJBadgeID") or 0,
		towerPoints = Attributes.getInt(towerFolder, "TowerPoints") or 1,
		allJumpsPoints = Attributes.getInt(towerFolder, "AllJumpsPoints"),
		noBoosts = towerFolder:HasTag("NoBoosts"),

		folder = towerFolder :: Instance,
		spawnLocation = spawnLocation :: BasePart,
		clientObjects = clientObjects,

		endings = {},

		minimumTime = Attributes.getNumber(minimumTimeSource, "MinimumTime") or 0,
		checkpoints = checkpointsList,
		checkpointCount = checkpointCount,
	}

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

				instance.Name = `{acronym}_{instance.Name}_{HttpService:GenerateGUID(false):sub(1, 8)}`
				instance.Parent = pointerContainer

				for _, tag: string in instance:GetTags() do
					thisPointer:AddTag(tag)
				end
			end
		end

		tower.clientObjects.Parent = CLIENT_OBJECTS_FOLDER
	end

	if tower.minimumTime == 0 and Config.noMinimumTimeWarning then
		Log({
			type = "warn",
			[1] = `{acronym} has no minimum time, it is vulnerable to being cheesed!`,
		})
	end

	towers[acronym] = tower

	return tower
end

local hasStarted = false

local function init()
	if hasStarted then
		return
	end
	hasStarted = true

	for _, v in TOWERS:GetChildren() do
		initTower(v)
	end
end

local function getTower(acronym: string): TowerInfo?
	return towers[acronym]
end

local function getAllTowers(): { [string]: TowerInfo }
	return towers
end

return {
	init = init,
	getTower = getTower,
	getAllTowers = getAllTowers,
	loadTower = loadTower,
}
