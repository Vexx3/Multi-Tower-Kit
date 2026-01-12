--[=[
	Creates and updates Roblox leaderstats for players based on their tower
	completions.

	@class LeaderstatsManager
	@server
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.PlayerData)
local ToolManager = require(script.Parent.Parent.Helpers.ToolManager)
local Types = require(ReplicatedStorage.TowerGame.Shared.Types)

type PlayerInfo = {
	Player: Player,
	LeaderStatsFolder: Folder,
	TowerStat: IntValue,
	AllJumpsStat: IntValue,
}

local _players: { [string]: PlayerInfo } = {}

local LeaderstatsManager = {}

function LeaderstatsManager.initPlayer(player: Player)
	local data = PlayerData.getData(player)
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
function LeaderstatsManager.setTowerStat(player: Player, towerInfo: Types.TowerInfo, stat: number)
	local info = _players[player.Name]
	if not info then
		return
	end

	local playerData = PlayerData.getData(player)
	if not playerData then
		return
	end

	local acronym = towerInfo.Folder.Name

	if table.find(playerData.CompletedTowers, acronym) then
		return
	end

	PlayerData.updateAsync(player, function(data)
		data.Towers += stat
		info.TowerStat.Value = data.Towers
		table.insert(data.CompletedTowers, acronym)
		return true
	end)

	ToolManager.giveTowerTools(player, acronym)
end

--[=[
	Awards all-jumps completion for a tower. Updates a separate leaderstat and
	all-jumps datastore counter so normal wins remain untouched.

	@within LeaderstatsManager
	@param stat number -- amount to add to the All-jumps stat
]=]
function LeaderstatsManager.setAllJumpsStat(player: Player, towerInfo: Types.TowerInfo, stat: number)
	local info = _players[player.Name]
	if not info then
		return
	end

	local towerKey = towerInfo.Folder.Name
	local playerData = PlayerData.getData(player)
	if not playerData or (playerData.CompletedAJTowers and table.find(playerData.CompletedAJTowers, towerKey)) then
		return
	end

	PlayerData.updateAsync(player, function(data)
		local current = data.AllJumps or 0
		data.AllJumps = current + stat
		info.AllJumpsStat.Value = data.AllJumps

		if not data.CompletedAJTowers then
			data.CompletedAJTowers = {}
		end
		table.insert(data.CompletedAJTowers, towerKey)

		return true
	end)
end

return LeaderstatsManager
