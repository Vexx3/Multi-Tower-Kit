--[=[
	Coordinates tower rush flow: starting rushes, advancing through towers, and
	awarding rush completions.

	@class TowerRushManager
]=]

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local Announcements = require("../Services/Announcements")
local BlinkServer = require("../Network/BlinkServer")
local DataInfo = require("./DataInfo")
local PlayerState = require("../Player/PlayerState")
local TowerManager = require("./TowerManager")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

local TowerRushes: Types.Dictionary<Types.TowerRush> = require(ReplicatedStorage.RealmData.TowerRushes)

local TowerRushManager = {}

--[=[
	Begin a tower rush for the player, initializing rush state and loading the
	first tower.

	@within TowerRushManager
	@server
]=]
function TowerRushManager:LoadTowerRush(playerName: string, towerRushName: string)
	local player: Types.PlayerInfo? = DataInfo.PlayerInfo[playerName]
	local towerRush: Types.TowerRush? = TowerRushes[towerRushName]

	if not player then
		return
	end

	if not towerRush then
		Util:Warn(`Unknown tower rush "{towerRushName}"`)
		return
	end

	if player.IsLoadingTower then
		return
	end

	player.CurrentTowerRush = towerRushName
	player.CurrentTowerRushIndex = 1
	player.BoostItemUsed = false
	player.BoostItemNames = {}

	TowerManager:LoadTower(playerName, towerRush.Towers[1], true)
	BlinkServer.UpdateTowerRush.Fire(player.Player, 1, #towerRush.Towers)
end

--[=[
	Advance a player to the next tower in their active rush or complete the
	rush if on the final tower.

	@within TowerRushManager
]=]
function TowerRushManager:AdvanceTowerRush(playerName: string)
	local player: Types.PlayerInfo? = DataInfo.PlayerInfo[playerName]
	if not player then
		return
	end

	local towerRush: Types.TowerRush? = TowerRushes[player.CurrentTowerRush]
	if not towerRush then
		return
	end

	local towerCount = #towerRush.Towers
	if player.CurrentTowerRushIndex == towerCount then
		Announcements:WinAnnouncement(player, towerRush.Title, towerRush.Difficulty)

		if towerRush.BadgeID ~= 0 then
			BadgeService:AwardBadgeAsync(player.Player.UserId, towerRush.BadgeID)
		end
		PlayerState:TeleportToWinroom(player, towerRush.WinroomMarker)
		return
	end

	player.CurrentTowerRushIndex += 1
	local towerName = towerRush.Towers[player.CurrentTowerRushIndex]
	TowerManager:LoadTower(playerName, towerName, false)
	BlinkServer.UpdateTowerRush.Fire(player.Player, player.CurrentTowerRushIndex, towerCount)
end

return TowerRushManager
