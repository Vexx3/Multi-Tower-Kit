--!strict
-- @zylx 2025-11-20

-- Not to be confused with the PlayerInfo type in MultiTowerServer
type PlayerInfo = {
	Player: Player,
	LeaderStatsFolder: Folder,

	TowerStat: IntValue,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.PlayerData)
local Types = require(ReplicatedStorage.Shared.Types)

local Players: { [string]: PlayerInfo } = {}

local LeaderstatsManager = {}

function LeaderstatsManager:InitPlayer(player: Player)	
	local data = PlayerData:GetData(player)
	if not data then
		return
	end
	
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local towerStat = Instance.new("IntValue")
	towerStat.Name = "Towers"
	towerStat.Value = data.Towers
	towerStat.Parent = leaderstats	

	local info: PlayerInfo = {
		Player = player,
		LeaderStatsFolder = leaderstats,
		TowerStat = towerStat,
	}
	Players[player.Name] = info
end

function LeaderstatsManager:UpdatePlayerTowerData(player: Player, towerInfo: Types.TowerInfo, stat: number)
	local info: PlayerInfo = Players[player.Name]
	if not info then
		return
	end
	
	local data = PlayerData:GetData(player)
	if not data then
		return
	end
	
	if data.CompletedTowers[towerInfo.Name] then
		return
	end
	
	data.Towers += stat
	info.TowerStat.Value = data.Towers
	
	data.CompletedTowers[towerInfo.Name] = towerInfo.Difficulty
end

return LeaderstatsManager
