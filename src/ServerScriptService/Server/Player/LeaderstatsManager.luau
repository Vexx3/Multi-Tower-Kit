--[=[
	Creates and updates Roblox leaderstats for players based on their tower
	completions.

	@class LeaderstatsManager
	@server
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.PlayerData)
local TowerData = require(script.Parent.PlayerData.TowerData)
local Types = require(ReplicatedStorage.Shared.Types)

type PlayerInfo = {
	Player: Player,
	LeaderStatsFolder: Folder,
	TowerStat: IntValue,
	AllJumpsStat: IntValue,
}

local _players: { [string]: PlayerInfo } = {}

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

	local allJumpsStat = Instance.new("IntValue")
	allJumpsStat.Name = "All-jumps"
	allJumpsStat.Value = data.AllJumps
	allJumpsStat.Parent = leaderstats

	local info: PlayerInfo = {
		Player = player,
		LeaderStatsFolder = leaderstats,
		TowerStat = towerStat,
		AllJumpsStat = allJumpsStat,
	}
	_players[player.Name] = info
end

--[=[
	Awards tower completion, increments the Towers stat, and records the
	completed tower difficulty if the player has not already finished it.

	@within LeaderstatsManager
	@param stat number -- amount to add to the Towers stat
]=]
function LeaderstatsManager:SetTowerStat(player: Player, towerInfo: Types.TowerInfo, stat: number)
	local info = _players[player.Name]
	if not info then
		return
	end

	local playerData = PlayerData:GetData(player)
	if not playerData then
		return
	end

	local acronym = towerInfo.Folder.Name

	if table.find(playerData.CompletedTowers, acronym) then
		return
	end

	PlayerData:UpdateAsync(player, function(data)
		data.Towers += stat
		info.TowerStat.Value = data.Towers
		table.insert(data.CompletedTowers, acronym)
		return true
	end)
end

--[=[
	Awards all-jumps completion for a tower. Updates a separate leaderstat and
	all-jumps datastore counter so normal wins remain untouched.

	@within LeaderstatsManager
	@param stat number -- amount to add to the All-jumps stat
]=]
function LeaderstatsManager:SetAllJumpsStat(player: Player, towerInfo: Types.TowerInfo, stat: number)
	local info = _players[player.Name]
	if not info then
		return
	end

	local towerKey = towerInfo.Folder.Name
	local towerStat = TowerData:GetTowerStat(player, towerKey)
	if towerStat and towerStat.AllJumpsWins and towerStat.AllJumpsWins > 1 then
		return
	end

	PlayerData:UpdateAsync(player, function(data)
		local current = data.AllJumps or 0
		data.AllJumps = current + stat
		info.AllJumpsStat.Value = data.AllJumps
		return true
	end)
end

return LeaderstatsManager
