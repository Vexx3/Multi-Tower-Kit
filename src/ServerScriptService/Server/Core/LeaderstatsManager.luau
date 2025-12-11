-- @zylx 2025-11-20

--[=[
	Creates and updates Roblox leaderstats for players based on their tower
	completions.

	@class LeaderstatsManager
	@server
]=]

-- Not to be confused with the PlayerInfo type in MultiTowerServer
type PlayerInfo = {
	Player: Player,
	LeaderStatsFolder: Folder,

	TowerStat: IntValue,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.PlayerData)
local TowerData = require(script.Parent.PlayerData.TowerData)
local Types = require(ReplicatedStorage.Shared.Types)

local Players: { [string]: PlayerInfo } = {}

local LeaderstatsManager = {}

-- Sets up the leaderstats folder and initial tower count for a joining player.

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

--[=[
	Awards tower completion, increments the Towers stat, and records the
	completed tower difficulty if the player has not already finished it.

	@within LeaderstatsManager
	@param stat number -- amount to add to the Towers stat
]=]
function LeaderstatsManager:SetTowerStat(player: Player, towerInfo: Types.TowerInfo, stat: number)
	local info: PlayerInfo = Players[player.Name]
	if not info then
		return
	end

	local towerKey = towerInfo.Folder.Name
	local towerStat = TowerData:GetTowerStat(player, towerKey)
	-- Only award the global Towers stat on the first recorded win for this tower
	if towerStat and towerStat.Wins and towerStat.Wins > 1 then
		return
	end

	PlayerData:UpdateAsync(player, function(data)
		data.Towers += stat
		info.TowerStat.Value = data.Towers
		return true
	end)
end

return LeaderstatsManager
