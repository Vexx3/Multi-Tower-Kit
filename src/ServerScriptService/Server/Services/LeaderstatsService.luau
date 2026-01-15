-- Creates and updates Roblox leaderstats for players based on their tower completions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.TowerGame.Shared

local PlayerData = require("../Player/PlayerData")
local ToolService = require("./ToolService")
local Types = require(Shared.Types)

type LeaderstatsInfo = {
	player: Player,
	leaderStatsFolder: Folder,
	towerStat: IntValue,
	allJumpsStat: IntValue,
}

local players: { [string]: LeaderstatsInfo } = {}

local LeaderstatsService = {}

-- Initializes leaderstats for a player upon joining.
function LeaderstatsService.initPlayer(player: Player)
	local data = PlayerData.getData(player)
	if not data then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local towerStat = Instance.new("IntValue")
	towerStat.Name = "Towers"
	towerStat.Value = data.towers
	towerStat.Parent = leaderstats

	local allJumpsStat = Instance.new("IntValue")
	allJumpsStat.Name = "All-jumps"
	allJumpsStat.Value = data.allJumps
	allJumpsStat.Parent = leaderstats

	local info: LeaderstatsInfo = {
		player = player,
		leaderStatsFolder = leaderstats,
		towerStat = towerStat,
		allJumpsStat = allJumpsStat,
	}

	players[player.Name] = info
end

-- Awards tower completion, increments the Towers stat, and records the completed tower.
function LeaderstatsService.setTowerStat(player: Player, towerInfo: Types.TowerInfo, stat: number)
	local info: LeaderstatsInfo? = players[player.Name]
	if not info then
		return
	end

	local playerData = PlayerData.getData(player)
	if not playerData then
		return
	end

	local acronym = towerInfo.folder.Name
	if table.find(playerData.completedTowers, acronym) then
		return
	end

	PlayerData.updateAsync(player, function(data: PlayerData.PlayerData)
		data.towers += stat
		info.towerStat.Value = data.towers
		table.insert(data.completedTowers, acronym)
		return true
	end)

	ToolService.giveTowerTools(player, acronym)
end

-- Awards all-jumps completion for a tower. Updates the All-jumps leaderstat.
function LeaderstatsService.setAllJumpsStat(player: Player, towerInfo: Types.TowerInfo, stat: number)
	local info: LeaderstatsInfo? = players[player.Name]
	if not info then
		return
	end

	local towerKey = towerInfo.folder.Name
	local playerData = PlayerData.getData(player)

	if not playerData or (playerData.completedAjTowers and table.find(playerData.completedAjTowers, towerKey)) then
		return
	end

	PlayerData.updateAsync(player, function(data: PlayerData.PlayerData)
		local current = data.allJumps
		data.allJumps = current + stat
		info.allJumpsStat.Value = data.allJumps

		table.insert(data.completedAjTowers, towerKey)
		return true
	end)
end

return LeaderstatsService
