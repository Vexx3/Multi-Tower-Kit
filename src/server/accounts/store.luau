--[[
	Lyra-backed player data store.
	Provides load, unload, getData, waitForData, updateAsync, and peekAsync.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BlinkServer = require("../Network/BlinkServer")
local Config = require("../../shared/constants/config")
local Lyra = require("../../../Packages/lyra")
local accountStore = require("../stores/accountStore")
local t = require("../../../Packages/t")
local template = require("./template")

export type PlayerData = template.PlayerData

local DATA_STORE_KEY: string = if RunService:IsStudio() then Config.dataStoreKeyStudio else Config.dataStoreKey

local loaded: { [Player]: boolean } = {}

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

local function onAccountChanged(key: string, newData: PlayerData)
	local player = Players:GetPlayerByUserId(tonumber(key) :: number)
	if player then
		accountStore.setAccount(player.Name, newData)
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

	if newData.tickets ~= oldData.tickets then
		changes.tickets = newData.tickets
		hasChanges = true
	end

	if newData.ticketCooldowns ~= oldData.ticketCooldowns then
		changes.ticketCooldowns = newData.ticketCooldowns
		hasChanges = true
	end

	if hasChanges then
		BlinkServer.PlayerDataUpdate.Fire(player, changes)
	end
end

local timeStatSchema = t.strictInterface({
	seconds = t.number,
	formatted = t.string,
})

local towerStatSchema = t.strictInterface({
	attempts = t.number,
	wins = t.number,
	allJumpsWins = t.number,
	totalTimeSpent = timeStatSchema,
	bestWinTime = timeStatSchema,
	bestAjWinTime = timeStatSchema,
})

local tSchema = t.strictInterface({
	towers = t.number,
	allJumps = t.optional(t.number),
	completedTowers = t.array(t.string),
	completedAjTowers = t.optional(t.array(t.string)),
	towerStats = t.map(t.string, towerStatSchema),
	completedTowerRushes = t.array(t.string),
	towerRushStats = t.map(t.string, towerStatSchema),
	tickets = t.number,
	ticketCooldowns = t.map(t.string, t.number),
	settings = t.strictInterface({
		quickResetDelay = t.number,
		resetOnDeath = t.boolean,
		highFPSPhysicsFix = t.boolean,
		utility = t.union(t.literal("Off"), t.literal("Emote"), t.literal("Alignment")),
		towerLoadingBehavior = t.union(t.literal("Load All"), t.literal("Unload Towers"), t.literal("Unload All")),
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

local store = Lyra.createPlayerStore({
	name = DATA_STORE_KEY,
	template = template,
	schema = tSchema,
	changedCallbacks = { onAccountChanged, syncWithClient },
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

		Lyra.MigrationStep.addFields("addNewFields", {
			allJumps = 0,
			completedAjTowers = {},
			towerStats = {},
			completedTowerRushes = {},
			towerRushStats = {},
			settings = template.settings,
		}),

		Lyra.MigrationStep.addFields("addTickets", {
			tickets = 0,
			ticketCooldowns = {},
		}),

		Lyra.MigrationStep.transform("renameLowDetailMode", function(data: any)
			local settings = data.settings
			if settings and settings.lowDetailMode ~= nil then
				local mapping = {
					["Off"] = "Load All",
					["On"] = "Unload Towers",
					["Ultra"] = "Unload All",
				}
				settings.towerLoadingBehavior = mapping[settings.lowDetailMode] or "Load All"
				settings.lowDetailMode = nil
			end
			return data
		end),
	},
	importLegacyData = function(key: string)
		local dataStore: GlobalDataStore = DataStoreService:GetDataStore(DATA_STORE_KEY)
		local success, data = pcall(function()
			return dataStore:GetAsync(key)
		end)

		if not success then
			error("Failed to reach data system")
		end

		if data ~= nil then
			return data.Data
		end

		return nil
	end,
	logCallback = createLogger(),
} :: any)

local function getData(player: Player): PlayerData?
	if not loaded[player] then
		return nil
	end
	return store:getAsync(player)
end

local function waitForData(player: Player): PlayerData?
	while not loaded[player] and player.Parent do
		task.wait(0.1)
	end
	return getData(player)
end

local function updateAsync(player: Player, fn: (data: PlayerData) -> boolean)
	return store:updateAsync(player, fn)
end

local function loadAsync(player: Player)
	store:loadAsync(player)
	loaded[player] = true
end

local function unloadAsync(player: Player)
	loaded[player] = nil
	store:unloadAsync(player)
end

local function closeAsync()
	store:closeAsync()
end

local function peekAsync(userId: number)
	return store:peekAsync(userId)
end

return {
	getData = getData,
	waitForData = waitForData,
	updateAsync = updateAsync,
	loadAsync = loadAsync,
	unloadAsync = unloadAsync,
	closeAsync = closeAsync,
	peekAsync = peekAsync,
}
