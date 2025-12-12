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

local Config = require(GameData.Config)
local Lyra = require(Packages.Lyra)
local t = require(Packages._Index["osyrisrblx_t@3.1.1"]["t"])

local Loaded: { [Player]: boolean } = {}

local DATA_STORE_KEY = if RunService:IsStudio()
	then Config.DATA_STORE_KEY_STUDIO
	else Config.DATA_STORE_KEY

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

local store = Lyra.createPlayerStore({
	name = DATA_STORE_KEY,
	template = Config.DEFAULT_PLAYER_DATA,
	schema = t.strictInterface({
		Towers = t.number,
		AllJumps = t.optional(t.number),
		TowerStats = t.table,
	}),
	migrationSteps = {
		Lyra.MigrationStep.addFields("addAJ", {
			AllJumps = 0,
		}),
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
	while not Loaded[player] do
		task.wait()
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
		local success = pcall(store.loadAsync, store, player)
		if success then
			Loaded[player] = true
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
