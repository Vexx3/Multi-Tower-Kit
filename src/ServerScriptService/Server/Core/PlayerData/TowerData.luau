-- Handles per-tower player statistics stored in the profile datastore.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(ReplicatedStorage.GameData.Config)

local PlayerData = require("../PlayerData")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type TowerStat = Types.TowerStat

local DEFAULT_TOWER_STAT: TowerStat = {
	Attempts = 0,
	Wins = 0,
	AllJumpsWins = 0,
	TotalTimeSpentSeconds = 0,
	TotalTimeSpentFormatted = "0s",
	BestWinTimeItemlessSeconds = nil,
	BestWinTimeItemlessFormatted = nil,
}

local TowerData = {}

local function applyDefaults(stat: TowerStat)
	local statAny = stat :: any
	for key, value in DEFAULT_TOWER_STAT do
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
	stat.TotalTimeSpentFormatted = Util:FormatDuration(stat.TotalTimeSpentSeconds)
end

local function ensureStat(data: Config.PlayerData, towerName: string): TowerStat
	local towerStats = data.TowerStats or {}
	data.TowerStats = towerStats

	local stat = towerStats[towerName]
	if not stat then
		stat = table.clone(DEFAULT_TOWER_STAT)
		towerStats[towerName] = stat
	end

	applyDefaults(stat)

	return stat
end

function TowerData:GetTowerStat(player: Player, towerName: string): TowerStat?
	local data = PlayerData:GetData(player)
	if not data then
		return nil
	end

	local stats = data.TowerStats
	return stats and stats[towerName]
end

function TowerData:IncrementTowerAttempt(player: Player, towerName: string)
	PlayerData:UpdateAsync(player, function(data)
		local stat = ensureStat(data, towerName)
		stat.Attempts += 1
		return true
	end)
end

function TowerData:AddTowerTimeSpent(player: Player, towerName: string, deltaSeconds: number)
	local delta = math.max(deltaSeconds, 0)
	if delta <= 0 then
		return
	end

	PlayerData:UpdateAsync(player, function(data)
		local stat = ensureStat(data, towerName)
		applyTime(stat, delta)
		return true
	end)
end

function TowerData:RecordTowerWin(
	player: Player,
	towerName: string,
	runTimeSeconds: number,
	boostItemUsed: boolean,
	isAllJumps: boolean?
)
	local cleanRunTime = math.max(runTimeSeconds, 0)
	local awardAllJumps = isAllJumps == true

	PlayerData:UpdateAsync(player, function(data)
		local stat = ensureStat(data, towerName)

		if awardAllJumps then
			stat.AllJumpsWins += 1
		else
			stat.Wins += 1
		end
		applyTime(stat, cleanRunTime)

		if not awardAllJumps and not boostItemUsed and cleanRunTime > 0 then
			local best = stat.BestWinTimeItemlessSeconds
			if not best or cleanRunTime < best then
				stat.BestWinTimeItemlessSeconds = cleanRunTime
				stat.BestWinTimeItemlessFormatted = Util:FormatTimer(cleanRunTime)
			end
		end

		return true
	end)
end

return TowerData
