--[=[
	Coordinates tower rush flow: starting rushes, advancing through towers, and
	awarding rush completions.

	@class TowerRushManager
]=]

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerGame = ReplicatedStorage.TowerGame
local RealmData = TowerGame.RealmData
local Shared = TowerGame.Shared

local Types = require(Shared.Types)

local RealmInfo = require(RealmData.RealmInfo)
local TowerRushes: Types.Dictionary<Types.TowerRush> = require(RealmData.TowerRushes)

local Announcements = require("../Services/Announcements")
local BlinkServer = require("../Network/BlinkServer")
local DataInfo = require("./DataInfo")
local LeaderstatsManager = require("../Player/LeaderstatsManager")
local PlayerState = require("../Player/PlayerState")
local TowerData = require("../Player/PlayerData/TowerData")
local TowerManager = require("./TowerManager")
local TowerRushData = require("../Player/PlayerData/TowerRushData")
local TowerSignManager = require("./TowerSignManager")
local Util = require(Shared.Util)

local TowerRushManager = {}

local _rushInfoMap = {}
for _, world in RealmInfo :: any do
	for _, area in world do
		if area.Towers then
			for key, data in area.Towers do
				if data.Rush then
					_rushInfoMap[key] = data
				end
			end
		end
	end
end

local function awardTowerCompletion(playerInfo: Types.PlayerInfo, towerInfo: Types.TowerInfo, splitTime: number)
	local player = playerInfo.Player
	local isAllJumps = playerInfo.AllJumpsMode

	Announcements.winAnnouncement(playerInfo, towerInfo.Name, towerInfo.Difficulty, splitTime)

	TowerData.recordTowerWin(player, towerInfo.Folder.Name, splitTime, playerInfo.BoostItemUsed, isAllJumps)

	if isAllJumps then
		if towerInfo.AJBadgeID and towerInfo.AJBadgeID ~= 0 then
			BadgeService:AwardBadgeAsync(player.UserId, towerInfo.AJBadgeID)
		end
		LeaderstatsManager.setAllJumpsStat(player, towerInfo, towerInfo.AllJumpsPoints or towerInfo.TowerPoints)
	else
		if towerInfo.BadgeID ~= 0 then
			BadgeService:AwardBadgeAsync(player.UserId, towerInfo.BadgeID)
		end
		LeaderstatsManager.setTowerStat(player, towerInfo, towerInfo.TowerPoints)
		TowerSignManager.markTowerCompleted(towerInfo.Folder.Name)
	end
end

local function awardRushCompletion(playerInfo: Types.PlayerInfo, towerRushName: string, rushTime: number)
	local rushInfo = _rushInfoMap[towerRushName]
	local rushConfig = TowerRushes[towerRushName]

	if not rushInfo or not rushConfig then
		Util.warn(`Attempted to award completion for unknown rush: {towerRushName}`)
		return
	end

	local title = rushInfo.Name
	local difficulty = Util.getDifficultyByRating(rushInfo.Rating)
	local badgeId = rushInfo.BadgeID

	Announcements.winAnnouncement(playerInfo, title, difficulty, rushTime)
	TowerRushData.recordRushWin(playerInfo.Player, towerRushName, rushTime, playerInfo.BoostItemUsed)

	if badgeId and badgeId ~= 0 then
		BadgeService:AwardBadgeAsync(playerInfo.Player.UserId, badgeId)
	end

	PlayerState.teleportToWinroom(playerInfo, rushConfig.WinroomMarker)
end

--[=[
	Begin a tower rush for the player, initializing rush state and loading the
	first tower.

	@within TowerRushManager
	@server
]=]
function TowerRushManager.loadTowerRush(playerName: string, towerRushName: string)
	local player: Types.PlayerInfo? = DataInfo.PlayerInfo[playerName]
	local towerRush: Types.TowerRush? = TowerRushes[towerRushName]

	if not player then
		return
	end

	if not towerRush then
		Util.warn(`Unknown tower rush "{towerRushName}"`)
		return
	end

	if player.IsLoadingTower then
		return
	end

	player.CurrentTowerRush = towerRushName
	player.CurrentTowerRushIndex = 1
	player.CurrentTowerRushSplitTime = 0
	player.BoostItemUsed = false
	player.BoostItemNames = {}

	TowerRushData.incrementRushAttempt(player.Player, towerRushName)
	TowerManager.loadTower(playerName, towerRush.Towers[1], true)
	BlinkServer.UpdateTowerRush.Fire(player.Player, 1, #towerRush.Towers)
end

--[=[
	Advance a player to the next tower in their active rush or complete the
	rush if on the final tower.

	@within TowerRushManager
]=]
function TowerRushManager.advanceTowerRush(playerName: string)
	local player: Types.PlayerInfo? = DataInfo.PlayerInfo[playerName]
	if not player then
		return
	end

	local towerRush: Types.TowerRush? = TowerRushes[player.CurrentTowerRush]
	if not towerRush then
		return
	end

	local currentTowerName = towerRush.Towers[player.CurrentTowerRushIndex]
	local towerInfo = DataInfo.TowerInfo[currentTowerName]
	local rushTime = player.TowerTimer
	local splitTime = rushTime - player.CurrentTowerRushSplitTime

	if towerInfo then
		awardTowerCompletion(player, towerInfo, splitTime)
	end

	local towerCount = #towerRush.Towers
	if player.CurrentTowerRushIndex == towerCount then
		awardRushCompletion(player, player.CurrentTowerRush, rushTime)
		return
	end

	player.CurrentTowerRushIndex += 1
	player.CurrentTowerRushSplitTime = rushTime
	local towerName = towerRush.Towers[player.CurrentTowerRushIndex]
	TowerManager.loadTower(playerName, towerName, false)
	BlinkServer.UpdateTowerRush.Fire(player.Player, player.CurrentTowerRushIndex, towerCount)
end

return TowerRushManager
