--[=[
	Handles per-tower player statistics stored in the profile datastore.

	@class TowerData
	@server
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.TowerGame.Shared
local Config = require(ReplicatedStorage.TowerGame.GameData.Config)

local PlayerData = require("../PlayerData")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type TowerStat = Types.TowerStat

local DEFAULT_DIFFICULTY_STAT: TowerStat = {
	Attempts = 0,
	Wins = 0,
	AllJumpsWins = 0,
	TotalTimeSpentSeconds = 0,
	TotalTimeSpentFormatted = "0m 0s",
	BestWinTimeSeconds = 0,
	BestWinTimeFormatted = "N/A",
	BestAJWinTimeSeconds = 0,
	BestAJWinTimeFormatted = "N/A",
}

local TowerData = {}

local function _applyDefaults(stat: TowerStat)
	local statAny = stat :: any
	for key, value in DEFAULT_DIFFICULTY_STAT do
		if statAny[key] == nil then
			statAny[key] = value
		end
	end
end

local function _applyTime(stat: TowerStat, timeDelta: number)
	if timeDelta <= 0 then
		return
	end

	stat.TotalTimeSpentSeconds += timeDelta
	stat.TotalTimeSpentFormatted = Util.formatDuration(stat.TotalTimeSpentSeconds)
end

local function _ensureStat(data: Config.PlayerData, towerName: string): TowerStat
	local towerStats = if data.TowerStats then table.clone(data.TowerStats) else {}
	data.TowerStats = towerStats

	local stat = towerStats[towerName]
	if stat then
		stat = table.clone(stat)
	else
		stat = table.clone(DEFAULT_DIFFICULTY_STAT)
	end
	towerStats[towerName] = stat

	_applyDefaults(stat)

	return stat
end

function TowerData.getTowerStat(player: Player, towerName: string): TowerStat?
	local data = PlayerData.getData(player)
	if not data then
		return nil
	end

	local stats = data.TowerStats
	return stats and stats[towerName]
end

function TowerData.incrementTowerAttempt(player: Player, towerName: string)
	PlayerData.updateAsync(player, function(data)
		local stat = _ensureStat(data, towerName)
		stat.Attempts += 1
		return true
	end)
end

function TowerData.addTowerTimeSpent(player: Player, towerName: string, timeDelta: number)
	local delta = math.max(timeDelta, 0)
	if delta <= 0 then
		return
	end

	PlayerData.updateAsync(player, function(data)
		local stat = _ensureStat(data, towerName)
		_applyTime(stat, delta)
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
	local cleanRunTime = math.max(runTimeSeconds, 0)
	local awardAllJumps = isAllJumps == true

	PlayerData.updateAsync(player, function(data)
		local stat = _ensureStat(data, towerName)

		if awardAllJumps then
			stat.AllJumpsWins += 1

			if not isBoostUsed and cleanRunTime > 0 then
				local best = stat.BestAJWinTimeSeconds
				if best == 0 or cleanRunTime < best then
					stat.BestAJWinTimeSeconds = cleanRunTime
					stat.BestAJWinTimeFormatted = Util.formatTimer(cleanRunTime)
				end
			end
		else
			stat.Wins += 1
		end
		_applyTime(stat, cleanRunTime)

		if not awardAllJumps and not isBoostUsed and cleanRunTime > 0 then
			local best = stat.BestWinTimeSeconds
			if best == 0 or cleanRunTime < best then
				stat.BestWinTimeSeconds = cleanRunTime
				stat.BestWinTimeFormatted = Util.formatTimer(cleanRunTime)
			end
		end

		return true
	end)
end

return TowerData
