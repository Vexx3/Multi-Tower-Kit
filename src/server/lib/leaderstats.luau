--[[
	Creates and updates Roblox leaderstats for players.
]]

local Leaderboard = require("../../shared/utils/Leaderboard")
local Sift = require("../../../Packages/sift")
local Types = require("../../shared/types")
local accounts = require("../accounts")
local tools = require("../gameplay/tools")

local Array = Sift.Array

local leaderstats = {}

--- Initializes leaderstats for a player upon joining.
function leaderstats.initPlayer(player: Player)
	local data = accounts.getData(player)
	if not data then
		return
	end

	Leaderboard.setStat(player, "Towers", data.towers)
	Leaderboard.setStat(player, "All-jumps", data.allJumps)
end

--- Awards tower completion, increments the Towers stat, and records the completed tower.
function leaderstats.setTowerStat(player: Player, towerInfo: Types.TowerInfo, stat: number)
	local playerData = accounts.getData(player)
	if not playerData then
		return
	end

	local acronym = towerInfo.folder.Name
	if Array.includes(playerData.completedTowers, acronym) then
		return
	end

	accounts.updateAsync(player, function(data: accounts.PlayerData)
		data.towers += stat
		Leaderboard.setStat(player, "Towers", data.towers)
		data.completedTowers = Array.push(data.completedTowers, acronym)
		return true
	end)

	tools.giveTowerTools(player, acronym)
end

--- Awards all-jumps completion for a tower and updates the All-jumps leaderstat.
function leaderstats.setAllJumpsStat(player: Player, towerInfo: Types.TowerInfo, stat: number)
	local towerKey = towerInfo.folder.Name
	local playerData = accounts.getData(player)

	if not playerData or Array.includes(playerData.completedAjTowers or {}, towerKey) then
		return
	end

	accounts.updateAsync(player, function(data: accounts.PlayerData)
		data.allJumps = data.allJumps + stat
		Leaderboard.setStat(player, "All-jumps", data.allJumps)
		data.completedAjTowers = Array.push(data.completedAjTowers, towerKey)
		return true
	end)
end

return leaderstats
