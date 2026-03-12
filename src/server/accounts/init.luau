--[[
	Public API for player account data.
	Combines data store access with per-tower and per-rush statistics.
]]

local Types = require("../shared/types")
local Util = require("../shared/utils/util")
local store = require("@self/store")

export type PlayerData = store.PlayerData

type TowerStat = Types.TowerStat

local DEFAULT_TOWER_STAT: TowerStat = {
	attempts = 0,
	wins = 0,
	allJumpsWins = 0,
	totalTimeSpent = {
		seconds = 0,
		formatted = "0m 0s",
	},
	bestWinTime = {
		seconds = 0,
		formatted = "N/A",
	},
	bestAjWinTime = {
		seconds = 0,
		formatted = "N/A",
	},
}

local DEFAULT_RUSH_STAT: TowerStat = {
	attempts = 0,
	wins = 0,
	allJumpsWins = 0,
	totalTimeSpent = {
		seconds = 0,
		formatted = "0m 0s",
	},
	bestWinTime = {
		seconds = 0,
		formatted = "N/A",
	},
	bestAjWinTime = {
		seconds = 0,
		formatted = "N/A",
	},
}

local function applyDefaults(stat: TowerStat, defaults: TowerStat)
	local statMap = stat :: { [string]: unknown }
	local defaultsMap = defaults :: { [string]: unknown }
	for key, value in defaultsMap do
		if statMap[key] == nil then
			statMap[key] = value
		end
	end
end

local function applyTime(stat: TowerStat, timeDelta: number)
	if timeDelta <= 0 then
		return
	end

	stat.totalTimeSpent.seconds += timeDelta
	stat.totalTimeSpent.formatted = Util.formatDuration(stat.totalTimeSpent.seconds)
end

local function ensureTowerStat(data: PlayerData, towerName: string): TowerStat
	local towerStats: { [string]: TowerStat } = if data.towerStats then table.clone(data.towerStats) else {}
	data.towerStats = towerStats

	local stat: TowerStat? = towerStats[towerName]
	if stat then
		stat = table.clone(stat :: TowerStat)
	else
		stat = table.clone(DEFAULT_TOWER_STAT)
	end
	towerStats[towerName] = stat :: TowerStat

	applyDefaults(stat :: TowerStat, DEFAULT_TOWER_STAT)

	return stat :: TowerStat
end

local function ensureRushStat(data: PlayerData, rushName: string): TowerStat
	local rushStats = if data.towerRushStats then table.clone(data.towerRushStats) else {}
	data.towerRushStats = rushStats

	local stat = rushStats[rushName]
	if stat then
		stat = table.clone(stat)
	else
		stat = table.clone(DEFAULT_RUSH_STAT)
	end
	rushStats[rushName] = stat

	applyDefaults(stat, DEFAULT_RUSH_STAT)

	return stat
end

local accounts = {}

accounts.getData = store.getData
accounts.waitForData = store.waitForData
accounts.updateAsync = store.updateAsync
accounts.loadAsync = store.loadAsync
accounts.unloadAsync = store.unloadAsync
accounts.closeAsync = store.closeAsync
accounts.peekAsync = store.peekAsync

--- Gets the tower statistics for a specific tower.
function accounts.getTowerStat(player: Player, towerName: string): TowerStat?
	local data = store.getData(player)
	if not data then
		return nil
	end

	local stats: { [string]: TowerStat }? = data.towerStats
	return stats and stats[towerName]
end

--- Increments the attempt count for a tower.
function accounts.incrementTowerAttempt(player: Player, towerName: string)
	store.updateAsync(player, function(data: PlayerData)
		local stat = ensureTowerStat(data, towerName)
		stat.attempts += 1
		return true
	end)
end

--- Adds time spent in a tower to the player's statistics.
function accounts.addTowerTimeSpent(player: Player, towerName: string, timeDelta: number)
	local delta = math.max(timeDelta, 0)
	if delta <= 0 then
		return
	end

	store.updateAsync(player, function(data: PlayerData)
		local stat = ensureTowerStat(data, towerName)
		applyTime(stat, delta)
		return true
	end)
end

--- Records a tower win and updates best times.
function accounts.recordTowerWin(
	player: Player,
	towerName: string,
	runTimeSeconds: number,
	isBoostUsed: boolean,
	isAllJumps: boolean?
)
	local cleanRunTime = math.round(math.max(runTimeSeconds, 0) * 100) / 100
	local awardAllJumps = isAllJumps == true

	store.updateAsync(player, function(data: PlayerData)
		local stat = ensureTowerStat(data, towerName)

		if awardAllJumps then
			stat.allJumpsWins += 1

			if not isBoostUsed and cleanRunTime > 0 then
				local best = stat.bestAjWinTime.seconds
				if best == 0 or cleanRunTime < best then
					stat.bestAjWinTime.seconds = cleanRunTime
					stat.bestAjWinTime.formatted = Util.formatTimer(cleanRunTime)
				end
			end
		else
			stat.wins += 1
		end

		applyTime(stat, cleanRunTime)

		if not awardAllJumps and not isBoostUsed and cleanRunTime > 0 then
			local best = stat.bestWinTime.seconds
			if best == 0 or cleanRunTime < best then
				stat.bestWinTime.seconds = cleanRunTime
				stat.bestWinTime.formatted = Util.formatTimer(cleanRunTime)
			end
		end

		return true
	end)
end

--- Gets the rush statistics for a specific tower rush.
function accounts.getRushStat(player: Player, rushName: string): TowerStat?
	local data = store.getData(player)
	if not data then
		return nil
	end

	local stats = data.towerRushStats
	return stats and stats[rushName]
end

--- Increments the attempt count for a tower rush.
function accounts.incrementRushAttempt(player: Player, rushName: string)
	store.updateAsync(player, function(data: PlayerData)
		local stat = ensureRushStat(data, rushName)
		stat.attempts += 1
		return true
	end)
end

--- Adds time spent in a tower rush to the player's statistics.
function accounts.addRushTimeSpent(player: Player, rushName: string, deltaSeconds: number)
	local delta = math.max(deltaSeconds, 0)
	if delta <= 0 then
		return
	end

	store.updateAsync(player, function(data: PlayerData)
		local stat = ensureRushStat(data, rushName)
		applyTime(stat, delta)
		return true
	end)
end

--- Records a tower rush win and updates best times.
function accounts.recordRushWin(
	player: Player,
	rushName: string,
	runTimeSeconds: number,
	boostItemUsed: boolean,
	isAllJumps: boolean?
)
	local cleanRunTime = math.round(math.max(runTimeSeconds, 0) * 100) / 100
	local awardAllJumps = isAllJumps == true

	store.updateAsync(player, function(data: PlayerData)
		local stat = ensureRushStat(data, rushName)

		if awardAllJumps then
			stat.allJumpsWins += 1

			if not boostItemUsed and cleanRunTime > 0 then
				local best = stat.bestAjWinTime.seconds
				if best == 0 or cleanRunTime < best then
					stat.bestAjWinTime.seconds = cleanRunTime
					stat.bestAjWinTime.formatted = Util.formatTimer(cleanRunTime)
				end
			end
		else
			stat.wins += 1
		end

		applyTime(stat, cleanRunTime)

		if not awardAllJumps and not boostItemUsed and cleanRunTime > 0 then
			local best = stat.bestWinTime.seconds
			if best == 0 or cleanRunTime < best then
				stat.bestWinTime.seconds = cleanRunTime
				stat.bestWinTime.formatted = Util.formatTimer(cleanRunTime)
			end
		end

		local completed = data.completedTowerRushes or {}
		if not table.find(completed, rushName) then
			completed = table.clone(completed)
			table.insert(completed, rushName)
			data.completedTowerRushes = completed
		end

		return true
	end)
end

return accounts
