--[=[
	Player data backed by Lyra. Provides a thin wrapper to load/update player
	sessions while keeping the API surface used across the project.

	@class PlayerData
	@server
]=]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameData = ReplicatedStorage.GameData
local Packages = ReplicatedStorage.Packages

local BlinkServer = require("../Network/BlinkServer")
local Config = require(GameData.Config)
local Lyra = require(Packages.Lyra)
local t = require(Packages._Index["osyrisrblx_t@3.1.1"]["t"])

local Loaded: { [Player]: boolean } = {}

local DATA_STORE_KEY = if RunService:IsStudio() then Config.DATA_STORE_KEY_STUDIO else Config.DATA_STORE_KEY

local function createLogger()
	if RunService:IsStudio() then
		-- Show all logs in Studio
		return function(message)
			print(`[Lyra][{message.level}] {message.message}`)
			if message.context then
				print("Context:", message.context)
			end
		end
	else
		-- Only show errors in production
		return function(message)
			if message.level == "error" or message.level == "fatal" then
				warn(`[Lyra] {message.message}`)
			end
		end
	end
end

local function syncWithClient(key: string, newData: Config.PlayerData, oldData: Config.PlayerData?)
	local player = Players:GetPlayerByUserId(tonumber(key))
	if not player then
		return
	end

	if oldData == nil then
		-- First time data is loaded
		BlinkServer.PlayerDataUpdate.Fire(player, newData)
		return
	end

	local changes = {}
	local hasChanges = false

	if newData.Towers ~= oldData.Towers then
		changes.Towers = newData.Towers
		hasChanges = true
	end

	if newData.AllJumps ~= oldData.AllJumps then
		changes.AllJumps = newData.AllJumps
		hasChanges = true
	end

	if newData.CompletedTowers ~= oldData.CompletedTowers then
		changes.CompletedTowers = newData.CompletedTowers
		hasChanges = true
	end

	local newStats = newData.TowerStats or {}
	local oldStats = oldData.TowerStats or {}

	if newStats ~= oldStats then
		local towerStatsChanges = {}
		local statsChanged = false

		for name, stat in pairs(newStats) do
			if stat ~= oldStats[name] then
				towerStatsChanges[name] = stat
				statsChanged = true
			end
		end

		if statsChanged then
			changes.TowerStats = towerStatsChanges
			hasChanges = true
		end
	end

	if hasChanges then
		BlinkServer.PlayerDataUpdate.Fire(player, changes)
	end
end

local store = Lyra.createPlayerStore({
	name = DATA_STORE_KEY,
	template = Config.DEFAULT_PLAYER_DATA,
	schema = t.strictInterface({
		Towers = t.number,
		AllJumps = t.optional(t.number),
		CompletedTowers = t.array(t.string),
		TowerStats = t.table,
	}),
	changedCallbacks = { syncWithClient },
	migrationSteps = {
		-- Migrate the Old CompletedTowers map to a list
		Lyra.MigrationStep.transform("completedTowersMapToList", function(data)
			local completed = data.CompletedTowers

			if type(completed) == "table" then
				local newList = {}

				for towerName, _ in completed do
					table.insert(newList, towerName)
				end

				data.CompletedTowers = newList
			end

			return data
		end),
	},
	importLegacyData = function(key: string)
		local success, data = pcall(function()
			return DataStoreService:GetDataStore(DATA_STORE_KEY):GetAsync(key)
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
})

local PlayerData = {}

--[=[
	Return the current data snapshot for a player if loaded.

	@within PlayerData
	@return Config.PlayerData?
]=]
function PlayerData:GetData(player: Player): Config.PlayerData?
	while not Loaded[player] and player.Parent do
		task.wait()
	end

	if not player.Parent then
		return nil
	end

	return store:getAsync(player)
end

--[=[
	Apply a mutation to the player's data using Lyra's updateAsync.

	@within PlayerData
]=]
function PlayerData:UpdateAsync(player: Player, fn: (data: Config.PlayerData) -> boolean)
	return store:updateAsync(player, fn)
end

function PlayerData:Init()
	Players.PlayerAdded:Connect(function(player)
		-- Set attribute to false initially to indicate data is loading
		player:SetAttribute("DataLoaded", false)

		local success = pcall(store.loadAsync, store, player)
		if success then
			Loaded[player] = true
			-- Signal to client that data has been loaded
			player:SetAttribute("DataLoaded", true)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		Loaded[player] = nil
		store:unloadAsync(player)
	end)

	game:BindToClose(function()
		store:closeAsync()
	end)
end

return PlayerData
