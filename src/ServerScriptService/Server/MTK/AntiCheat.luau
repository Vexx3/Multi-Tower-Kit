--[=[
	Anti-cheat checks for tower completion, ensuring players finish towers
	legitimately before awarding wins.

	@class AntiCheat
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local Types = require(Shared.Types)

type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo
type EndingInfo = Types.EndingInfo

local AntiCheat = {}

--[=[
	Validate a player's tower completion against minimum time and checkpoint
	order, unless they used a debug item.

	@within AntiCheat
]=]
function AntiCheat:ValidateWin(player: PlayerInfo, tower: TowerInfo, ending: EndingInfo)
	-- Check to see if this ending is from this tower, if it's not, the player is probably cheating
	if ending.ParentTower ~= player.CurrentTower then
		return false, "Touched the winpad of a tower you're not in"
	end

	if not player.DebugItemUsed then
		if tower.MinimumTime > 0 and player.TowerTimer < tower.MinimumTime then
			return false, "Completed the tower too early"
		end

		if player.CurrentTowerCheckpoint < tower.CheckpointCount then
			return false, "Completed the tower out of order"
		end
	end

	return true, ""
end

return AntiCheat
