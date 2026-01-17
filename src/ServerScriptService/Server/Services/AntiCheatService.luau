--[[
	Anti-cheat checks for tower completion.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared

local Types = require(Shared.Types)

type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo
type EndingInfo = Types.EndingInfo

local AntiCheatService = {}

--- Validates a player's tower completion against minimum time and checkpoint order.
--- Players using debug items bypass these checks.
--- @param player PlayerInfo -- The player attempting to complete the tower
--- @param tower TowerInfo -- The tower being completed
--- @param ending EndingInfo -- The ending/winpad touched
--- @return boolean -- Whether the win is valid
--- @return string -- Reason for rejection if invalid
function AntiCheatService.validateWin(player: PlayerInfo, tower: TowerInfo, ending: EndingInfo): (boolean, string)
	if ending.parentTower ~= player.currentTower then
		return false, "Touched the winpad of a tower you're not in"
	end

	if not player.debugItemUsed then
		if tower.minimumTime > 0 and player.towerTimer < tower.minimumTime then
			return false, "Completed the tower too early"
		end

		if player.currentCheckpoint < tower.checkpointCount then
			return false, "Completed the tower out of order"
		end
	end

	return true, ""
end

return AntiCheatService
