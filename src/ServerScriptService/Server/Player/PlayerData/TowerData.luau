-- Handles per-tower player statistics stored in the profile datastore.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.TowerGame.Shared

local PlayerData = require("../PlayerData")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type TowerStat = Types.TowerStat
type PlayerData = PlayerData.PlayerData

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

local function applyDefaults(stat: TowerStat)
	local statAny: { [string]: unknown } = stat :: any
	for key: string, value: unknown in DEFAULT_TOWER_STAT :: any do
		if statAny[key] == nil then
			statAny[key] = value
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

local function ensureStat(data: PlayerData, towerName: string): TowerStat
	local towerStats: { [string]: TowerStat } = if data.towerStats then table.clone(data.towerStats) else {}
	data.towerStats = towerStats

	local stat: TowerStat? = towerStats[towerName]
	if stat then
		stat = table.clone(stat :: TowerStat)
	else
		stat = table.clone(DEFAULT_TOWER_STAT)
	end
	towerStats[towerName] = stat :: TowerStat

	applyDefaults(stat :: TowerStat)

	return stat :: TowerStat
end

local TowerData = {}

function TowerData.getTowerStat(player: Player, towerName: string): TowerStat?
	local data = PlayerData.getData(player)
	if not data then
		return nil
	end

	local stats: { [string]: TowerStat }? = data.towerStats
	return stats and stats[towerName]
end

function TowerData.incrementTowerAttempt(player: Player, towerName: string)
	PlayerData.updateAsync(player, function(data: PlayerData)
		local stat: TowerStat = ensureStat(data, towerName)
		stat.attempts += 1
		return true
	end)
end

function TowerData.addTowerTimeSpent(player: Player, towerName: string, timeDelta: number)
	local delta = math.max(timeDelta, 0)
	if delta <= 0 then
		return
	end

	PlayerData.updateAsync(player, function(data: PlayerData)
		local stat: TowerStat = ensureStat(data, towerName)
		applyTime(stat, delta)
		return true
	end)
end

function TowerData.recordTowerWin(
	player: Player,
	towerName: string,
	runTimeSeconds: number,
	isBoostUsed: boolean,
	isAllJumps: boolean?
)
	local cleanRunTime = math.round(math.max(runTimeSeconds, 0) * 100) / 100
	local awardAllJumps = isAllJumps == true

	PlayerData.updateAsync(player, function(data: PlayerData)
		local stat = ensureStat(data, towerName)

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

return TowerData
