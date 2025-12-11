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

local store = Lyra.createPlayerStore({
	name = DATA_STORE_KEY,
	template = Config.DEFAULT_PLAYER_DATA,
	schema = t.strictInterface({
		Towers = t.number,
		TowerStats = t.table,
	}),
	importLegacyData = function(key: string)
		local success, data = pcall(function()
			return DataStoreService:GetDataStore(DATA_STORE_KEY):GetAsync(key)
		end)

		if not success then
			error("Failed to reach data system")
		end

		if data ~= nil then
			return data
		end

		return nil
	end,
})

local PlayerData = {}

--[=[
	Return the current data snapshot for a player if loaded.
local Loaded: { [Player]: boolean } = {}

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

function PlayerData:WaitForData(player: Player): Config.PlayerData?
	while not Loaded[player] do
		task.wait()
	end

	return PlayerData:GetData(player)
end

function PlayerData:Init()
	--[=[
	Yield until the player's data session is loaded, then return it.
	Does not start a new load; relies on loadAsync from Init.
]=]

	Players.PlayerAdded:Connect(function(player)
		local success, result = pcall(store.loadAsync, store, player)

		if success then
			Loaded[player] = true
		else
			warn(`[PlayerData] Failed to load {player.Name}: {result}`)
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
