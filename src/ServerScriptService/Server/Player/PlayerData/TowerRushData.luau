--[=[
	Handles per-tower-rush player statistics stored in the profile datastore.

	Tracks attempts, wins, best times, and total time spent on tower rushes.

	@class TowerRushData
	@server
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.TowerGame.Shared

local PlayerData = require("../PlayerData")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type TowerStat = Types.TowerStat
type PlayerData = PlayerData.PlayerData

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

local function applyDefaults(stat: TowerStat)
	for key, value in pairs(DEFAULT_RUSH_STAT) do
		if (stat :: { [string]: unknown })[key] == nil then
			(stat :: { [string]: unknown })[key] = value
		end
	end
end

local function applyTime(stat: TowerStat, deltaSeconds: number)
	if deltaSeconds <= 0 then
		return
	end

	stat.totalTimeSpent.seconds += deltaSeconds
	stat.totalTimeSpent.formatted = Util.formatDuration(stat.totalTimeSpent.seconds)
end

local function ensureStat(data: PlayerData, rushName: string): TowerStat
	local rushStats = if data.towerRushStats then table.clone(data.towerRushStats) else {}
	data.towerRushStats = rushStats

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

local TowerRushData = {}

--- Gets the rush statistics for a specific tower rush.
--- @param player Player -- The player to get stats for
--- @param rushName string -- The rush name
--- @return TowerStat? -- The rush stats, or nil if not found
function TowerRushData.getRushStat(player: Player, rushName: string): TowerStat?
	local data = PlayerData.getData(player)
	if not data then
		return nil
	end

	local stats = data.towerRushStats
	return stats and stats[rushName]
end

--- Increments the attempt count for a tower rush.
--- @param player Player -- The player who attempted the rush
--- @param rushName string -- The rush name
function TowerRushData.incrementRushAttempt(player: Player, rushName: string)
	PlayerData.updateAsync(player, function(data)
		local stat = ensureStat(data, rushName)
		stat.attempts += 1
		return true
	end)
end

--- Adds time spent in a tower rush to the player's statistics.
--- @param player Player -- The player
--- @param rushName string -- The rush name
--- @param deltaSeconds number -- Time spent in seconds
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

--- Records a tower rush win and updates best times.
--- @param player Player -- The player who won
--- @param rushName string -- The rush name
--- @param runTimeSeconds number -- The completion time in seconds
--- @param boostItemUsed boolean -- Whether a boost item was used
--- @param isAllJumps boolean? -- Whether this was an all-jumps completion
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

return TowerRushData
