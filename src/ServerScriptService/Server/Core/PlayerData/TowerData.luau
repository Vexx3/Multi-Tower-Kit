--!strict
-- Handles per-tower player statistics stored in the profile datastore.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local PlayerData = require("../PlayerData")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type TowerStat = Types.TowerStat

local DEFAULT_TOWER_STAT: TowerStat = {
	Attempts = 0,
	Wins = 0,
	TotalTimeSpentSeconds = 0,
	TotalTimeSpentFormatted = "0s",
	BestWinTimeItemlessSeconds = nil,
	BestWinTimeItemlessFormatted = nil,
}

local TowerData = {}

local function applyTime(stat: TowerStat, deltaSeconds: number)
	if deltaSeconds <= 0 then
		return
	end

	stat.TotalTimeSpentSeconds += deltaSeconds
	stat.TotalTimeSpentFormatted = Util:FormatDuration(stat.TotalTimeSpentSeconds)
end

-- Returns (and creates if missing) the tower stat table for a player/tower
function TowerData:GetTowerStat(player: Player, towerName: string): TowerStat?
	local data = PlayerData:GetData(player)
	if not data then
		return nil
	end

	local towerStats = data.TowerStats or {}
	data.TowerStats = towerStats

	local stat: TowerStat? = towerStats[towerName]
	if not stat then
		stat = table.clone(DEFAULT_TOWER_STAT)
		towerStats[towerName] = stat
	end

	return stat
end

function TowerData:IncrementTowerAttempt(player: Player, towerName: string)
	local stat = TowerData:GetTowerStat(player, towerName)
	if not stat then
		return
	end

	stat.Attempts += 1
end

function TowerData:AddTowerTimeSpent(player: Player, towerName: string, deltaSeconds: number)
	local stat = TowerData:GetTowerStat(player, towerName)
	if not stat then
		return
	end
	applyTime(stat, math.max(deltaSeconds, 0))
end

function TowerData:RecordTowerWin(
	player: Player,
	towerName: string,
	runTimeSeconds: number,
	boostItemUsed: boolean
)
	local stat = TowerData:GetTowerStat(player, towerName)
	if not stat then
		return
	end

	local cleanRunTime = math.max(runTimeSeconds, 0)

	stat.Wins += 1
	applyTime(stat, cleanRunTime)

	if not boostItemUsed and cleanRunTime > 0 then
		local best = stat.BestWinTimeItemlessSeconds
		if not best or cleanRunTime < best then
			stat.BestWinTimeItemlessSeconds = cleanRunTime
			stat.BestWinTimeItemlessFormatted = Util:FormatTimer(cleanRunTime)
		end
	end
end

return TowerData
