--[=[
	Handles per-towerrush player statistics stored in the profile datastore.

	@class TowerRushData
	@server
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.TowerGame.Shared
local Config = require(ReplicatedStorage.TowerGame.GameData.Config)

local PlayerData = require("../PlayerData")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type TowerStat = Types.TowerStat

local DEFAULT_RUSH_STAT: TowerStat = {
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

local TowerRushData = {}

local function applyDefaults(stat: TowerStat)
	local statAny = stat :: any
	for key, value in DEFAULT_RUSH_STAT do
		if statAny[key] == nil then
			statAny[key] = value
		end
	end
end

local function applyTime(stat: TowerStat, deltaSeconds: number)
	if deltaSeconds <= 0 then
		return
	end

	stat.TotalTimeSpentSeconds += deltaSeconds
	stat.TotalTimeSpentFormatted = Util.formatDuration(stat.TotalTimeSpentSeconds)
end

local function ensureStat(data: Config.PlayerData, rushName: string): TowerStat
	local rushStats = if data.TowerRushStats then table.clone(data.TowerRushStats) else {}
	data.TowerRushStats = rushStats

	local stat = rushStats[rushName]
	if stat then
		stat = table.clone(stat)
	else
		stat = table.clone(DEFAULT_RUSH_STAT)
	end
	rushStats[rushName] = stat

	applyDefaults(stat)

	return stat
end

function TowerRushData.getRushStat(player: Player, rushName: string): TowerStat?
	local data = PlayerData.getData(player)
	if not data then
		return nil
	end

	local stats = data.TowerRushStats
	return stats and stats[rushName]
end

function TowerRushData.incrementRushAttempt(player: Player, rushName: string)
	PlayerData.updateAsync(player, function(data)
		local stat = ensureStat(data, rushName)
		stat.Attempts += 1
		return true
	end)
end

function TowerRushData.addRushTimeSpent(player: Player, rushName: string, deltaSeconds: number)
	local delta = math.max(deltaSeconds, 0)
	if delta <= 0 then
		return
	end

	PlayerData.updateAsync(player, function(data)
		local stat = ensureStat(data, rushName)
		applyTime(stat, delta)
		return true
	end)
end

function TowerRushData.recordRushWin(
	player: Player,
	rushName: string,
	runTimeSeconds: number,
	boostItemUsed: boolean,
	isAllJumps: boolean?
)
	local cleanRunTime = math.round(math.max(runTimeSeconds, 0) * 100) / 100
	local awardAllJumps = isAllJumps == true

	PlayerData.updateAsync(player, function(data)
		local stat = ensureStat(data, rushName)

		if awardAllJumps then
			stat.AllJumpsWins += 1

			if not boostItemUsed and cleanRunTime > 0 then
				local best = stat.BestAJWinTimeSeconds
				if best == 0 or cleanRunTime < best then
					stat.BestAJWinTimeSeconds = cleanRunTime
					stat.BestAJWinTimeFormatted = Util.formatTimer(cleanRunTime)
				end
			end
		else
			stat.Wins += 1
		end

		applyTime(stat, cleanRunTime)

		if not awardAllJumps and not boostItemUsed and cleanRunTime > 0 then
			local best = stat.BestWinTimeSeconds
			if best == 0 or cleanRunTime < best then
				stat.BestWinTimeSeconds = cleanRunTime
				stat.BestWinTimeFormatted = Util.formatTimer(cleanRunTime)
			end
		end

		local completed = data.CompletedTowerRushes or {}
		if not table.find(completed, rushName) then
			completed = table.clone(completed)
			table.insert(completed, rushName)
			data.CompletedTowerRushes = completed
		end

		return true
	end)
end

return TowerRushData
