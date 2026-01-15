-- Player data backed by Lyra. Provides a thin wrapper to load/update player
-- sessions while keeping the API surface used across the project.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Data = Shared.Data
local Packages = ReplicatedStorage.Packages

local BlinkServer = require(script.Parent.Parent.Network.BlinkServer)
local Config = require(Data.Config)
local InternalTemplate = require(script.InternalTemplate)
local Lyra = require(Packages.Lyra)
local t = require(Packages._Index["osyrisrblx_t@3.1.1"].t)

export type PlayerData = InternalTemplate.PlayerData

local DATA_STORE_KEY: string = if RunService:IsStudio() then Config.dataStoreKeyStudio else Config.dataStoreKey

local Loaded: { [Player]: boolean } = {}

local function createLogger()
	if RunService:IsStudio() then
		return function(message: any): ()
			print(`[Lyra][{message.level}] {message.message}`)
			if message.context then
				print("Context:", message.context)
			end
		end
	else
		return function(message: any): ()
			if message.level == "error" or message.level == "fatal" then
				warn(`[Lyra] {message.message}`)
			end
		end
	end
end

local function syncWithClient(key: string, newData: PlayerData, oldData: PlayerData?)
	local player = Players:GetPlayerByUserId(tonumber(key) :: number)
	if not player then
		return
	end

	if oldData == nil then
		BlinkServer.PlayerDataUpdate.Fire(player, newData)
		return
	end

	local changes: any = {}
	local hasChanges = false

	if newData.towers ~= oldData.towers then
		changes.towers = newData.towers
		hasChanges = true
	end

	if newData.allJumps ~= oldData.allJumps then
		changes.allJumps = newData.allJumps
		hasChanges = true
	end

	if newData.completedTowers ~= oldData.completedTowers then
		changes.completedTowers = newData.completedTowers
		hasChanges = true
	end

	if newData.completedAjTowers ~= oldData.completedAjTowers then
		changes.completedAjTowers = newData.completedAjTowers
		hasChanges = true
	end

	-- Sync tower stats changes
	if newData.towerStats or oldData.towerStats then
		local newStats: { [string]: any }? = newData.towerStats :: any
		local oldStats: { [string]: any }? = oldData.towerStats :: any

		local towerStatsChanges: { [string]: any } = {}
		local statsChanged = false

		if newStats ~= oldStats and newStats then
			for name, stat in newStats do
				if not oldStats or stat ~= oldStats[name] then
					towerStatsChanges[name] = stat
					statsChanged = true
				end
			end
		end

		if statsChanged then
			changes.towerStats = towerStatsChanges
			hasChanges = true
		end
	end

	if newData.completedTowerRushes ~= oldData.completedTowerRushes then
		changes.completedTowerRushes = newData.completedTowerRushes
		hasChanges = true
	end

	-- Sync tower rush stats changes
	if newData.towerRushStats or oldData.towerRushStats then
		local newStats: { [string]: any }? = newData.towerRushStats :: any
		local oldStats: { [string]: any }? = oldData.towerRushStats :: any

		local towerRushStatsChanges: { [string]: any } = {}
		local statsChanged: boolean = false

		if newStats ~= oldStats and newStats then
			for name, stat in newStats do
				if not oldStats or stat ~= oldStats[name] then
					towerRushStatsChanges[name] = stat
					statsChanged = true
				end
			end
		end

		if statsChanged then
			changes.towerRushStats = towerRushStatsChanges
			hasChanges = true
		end
	end

	if newData.settings ~= (if oldData then oldData.settings else nil) then
		changes.settings = newData.settings
		hasChanges = true
	end

	if hasChanges then
		BlinkServer.PlayerDataUpdate.Fire(player, changes)
	end
end

-- Schema validator using t library, wrapped for Lyra's expected signature
local tSchema = t.strictInterface({
	towers = t.number,
	allJumps = t.optional(t.number),
	completedTowers = t.array(t.string),
	completedAjTowers = t.optional(t.array(t.string)),
	towerStats = t.table,
	completedTowerRushes = t.array(t.string),
	towerRushStats = t.table,
	settings = t.strictInterface({
		quickResetDelay = t.number,
		resetOnDeath = t.boolean,
		highFPSPhysicsFix = t.boolean,
		utility = t.union(t.literal("Off"), t.literal("Emote"), t.literal("Alignment")),
		lowDetailMode = t.union(t.literal("Off"), t.literal("On"), t.literal("Ultra")),
		fpsDisplay = t.boolean,
		hideTimer = t.boolean,
		invisiblePlayers = t.union(
			t.literal("Off"),
			t.literal("Not Friended"),
			t.literal("Everyone Else"),
			t.literal("Near")
		),
		keyDisplayLimit = t.number,
		hideBubbleChat = t.boolean,
		musicVolume = t.number,
		keybinds = t.strictInterface({
			quickRestart = t.string,
			cornerFlip = t.string,
			createCheckpoint = t.string,
			teleportCheckpoint = t.string,
			removeCheckpoint = t.string,
			playAnimation = t.string,
		}),
		extendedCompletions = t.boolean,
	}),
})

local function playerDataSchema(data: unknown): (boolean, string?)
	return tSchema(data)
end

local store = Lyra.createPlayerStore({
	name = DATA_STORE_KEY,
	template = InternalTemplate,
	schema = playerDataSchema,
	changedCallbacks = { syncWithClient },
	migrationSteps = {
		Lyra.MigrationStep.transform("migrateLegacyFormat", function(data: any)
			local mapping: { [string]: string } = {
				Towers = "towers",
				CompletedTowers = "completedTowers",
			}

			for oldKey, newKey in mapping do
				if data[oldKey] ~= nil and data[newKey] == nil then
					data[newKey] = data[oldKey]
					data[oldKey] = nil
				end
			end

			-- Convert completedTowers map to list if it's in the old dictionary format
			local completed = data.completedTowers
			if typeof(completed) == "table" then
				local isDictionary = false
				for k in completed do
					if typeof(k) == "string" then
						isDictionary = true
						break
					end
				end

				if isDictionary then
					local newList = {}
					for towerName in completed do
						if typeof(towerName) == "string" then
							table.insert(newList, towerName)
						end
					end
					data.completedTowers = newList
				end
			end

			return data
		end),

		-- Add the new fields that weren't in the legacy data
		Lyra.MigrationStep.addFields("addNewFields", {
			allJumps = 0,
			completedAjTowers = {},
			towerStats = {},
			completedTowerRushes = {},
			towerRushStats = {},
			settings = InternalTemplate.settings,
		}),
	},
	importLegacyData = function(key: string)
		local dataStore: GlobalDataStore = DataStoreService:GetDataStore(DATA_STORE_KEY)
		local success, data = pcall(function()
			return dataStore:GetAsync(key)
		end)

		if not success then
			error("Failed to reach data system") -- Player will be kicked and can retry
		end

		if data ~= nil then
			return data.Data -- Return existing data to import
		end

		return nil -- Return nil for new players to use template
	end,
	logCallback = createLogger(),
} :: any)

local PlayerData = {}

-- Return the current data snapshot for a player.
-- Returns nil immediately if data is not loaded.
function PlayerData.getData(player: Player): PlayerData?
	if not Loaded[player] then
		return nil
	end
	return store:getAsync(player)
end

-- Yields the current thread until the player's data is loaded.
-- Returns the data if successful, or nil if the player left.
function PlayerData.waitForData(player: Player)
	while not Loaded[player] and player.Parent do
		player:GetAttributeChangedSignal("DataLoaded"):Wait()
	end
	return PlayerData.getData(player)
end

-- Apply a mutation to the player's data using Lyra's updateAsync.
function PlayerData.updateAsync(player: Player, fn: (data: PlayerData) -> boolean)
	return store:updateAsync(player, fn)
end

function PlayerData.init()
	BlinkServer.GetPlayerData.On(function(_, userId: number): any?
		return store:peekAsync(userId)
	end)

	BlinkServer.UpdateSettings.On(function(player: Player, updates: { [string]: any })
		PlayerData.updateAsync(player, function(data: PlayerData)
			local changed = false
			for key, value in updates do
				if key == "keybinds" and typeof(value) == "table" then
					for bindKey, bindValue in value do
						if (data.settings.keybinds :: any)[bindKey] ~= bindValue then
							(data.settings.keybinds :: any)[bindKey] = bindValue
							changed = true
						end
					end
				elseif (data.settings :: any)[key] ~= nil and (data.settings :: any)[key] ~= value then
					(data.settings :: any)[key] = value
					changed = true
				end
			end
			return changed
		end)
	end)

	local function onPlayerAdded(player: Player)
		player:SetAttribute("DataLoaded", false)

		local success, message = pcall(function()
			store:loadAsync(player)
			return nil
		end)

		if success then
			Loaded[player] = true
			player:SetAttribute("DataLoaded", true)
		else
			warn(`Failed to load data for {player.Name}: {message}`)
			player:Kick("Failed to load your data. Please rejoin.")
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		Loaded[player] = nil
		store:unloadAsync(player)
	end)

	game:BindToClose(function()
		store:closeAsync()
	end)
end

return PlayerData
