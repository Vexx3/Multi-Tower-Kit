--[[
	Creates and updates Roblox leaderstats for players.
	Uses Sift for array operations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.TowerGame.Shared
local Modules = ReplicatedStorage.Modules
local Packages = ReplicatedStorage.Packages

local Leaderboard = require(Modules.Leaderboard)
local PlayerData = require("../Player/PlayerData")
local Sift = require(Packages.sift)
local ToolService = require("./ToolService")
local Types = require(Shared.Types)

local Array = Sift.Array

local LeaderstatsService = {}

--- Initializes leaderstats for a player upon joining.
--- @param player Player -- The player to create leaderstats for
function LeaderstatsService.initPlayer(player: Player)
	local data = PlayerData.getData(player)
	if not data then
		return
	end

	Leaderboard.setStat(player, "Towers", data.towers)
	Leaderboard.setStat(player, "All-jumps", data.allJumps)
end

--- Awards tower completion, increments the Towers stat, and records the completed tower.
--- @param player Player -- The player who completed the tower
--- @param towerInfo TowerInfo -- The tower that was completed
--- @param stat number -- The number of points to award
function LeaderstatsService.setTowerStat(player: Player, towerInfo: Types.TowerInfo, stat: number)
	local playerData = PlayerData.getData(player)
	if not playerData then
		return
	end

	local acronym = towerInfo.folder.Name
	if Array.includes(playerData.completedTowers, acronym) then
		return
	end

	PlayerData.updateAsync(player, function(data: PlayerData.PlayerData)
		data.towers += stat
		Leaderboard.setStat(player, "Towers", data.towers)
		data.completedTowers = Array.push(data.completedTowers, acronym)
		return true
	end)

	ToolService.giveTowerTools(player, acronym)
end

--- Awards all-jumps completion for a tower and updates the All-jumps leaderstat.
--- @param player Player -- The player who completed the tower in all-jumps mode
--- @param towerInfo TowerInfo -- The tower that was completed
--- @param stat number -- The number of points to award
function LeaderstatsService.setAllJumpsStat(player: Player, towerInfo: Types.TowerInfo, stat: number)
	local towerKey = towerInfo.folder.Name
	local playerData = PlayerData.getData(player)

	if not playerData or Array.includes(playerData.completedAjTowers or {}, towerKey) then
		return
	end

	PlayerData.updateAsync(player, function(data: PlayerData.PlayerData)
		data.allJumps = data.allJumps + stat
		Leaderboard.setStat(player, "All-jumps", data.allJumps)
		data.completedAjTowers = Array.push(data.completedAjTowers, towerKey)
		return true
	end)
end

return LeaderstatsService
