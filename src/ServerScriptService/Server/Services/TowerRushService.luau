-- Coordinates tower rush flow: starting rushes, advancing through towers, and awarding completions.

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Data = Shared.Data
local Framework = ReplicatedStorage.Framework

local AnnouncementService = require("./AnnouncementService")
local BlinkServer = require("../Network/BlinkServer")
local LeaderstatsService = require("./LeaderstatsService")
local Log = require(Framework.Log)
local PlayerState = require("../Player/PlayerState")
local RealmInfo = require(Data.RealmInfo)
local TowerData = require("../Player/PlayerData/TowerData")
local TowerRushData = require("../Player/PlayerData/TowerRushData")
local TowerService = require("./TowerService")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type TowerRush = Types.TowerRush
type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local TowerRushes = require(Data.TowerRushes)

-- Maps rush key to realm tower info (for badge/name lookup).
local rushInfoMap: Types.Dictionary<Types.RealmTowerInfo> = {}

do
	local realms: Types.Realms = RealmInfo :: any
	for _, world in realms do
		for _, area in world do
			if area.towers then
				for key, data in area.towers do
					if data.rush then
						rushInfoMap[key] = data
					end
				end
			end
		end
	end
end

local TowerRushService = {}

local function awardTowerCompletion(playerInfo: PlayerInfo, towerInfo: TowerInfo, splitTime: number)
	local player = playerInfo.player
	local isAllJumps = playerInfo.mode == "AllJumps"

	TowerData.recordTowerWin(player, towerInfo.folder.Name, splitTime, playerInfo.boostItemUsed, isAllJumps)

	if isAllJumps then
		if towerInfo.ajBadgeId and towerInfo.ajBadgeId ~= 0 then
			BadgeService:AwardBadgeAsync(player.UserId, towerInfo.ajBadgeId)
		end
		LeaderstatsService.setAllJumpsStat(player, towerInfo, towerInfo.allJumpsPoints or towerInfo.towerPoints)
	else
		if towerInfo.badgeId ~= 0 then
			BadgeService:AwardBadgeAsync(player.UserId, towerInfo.badgeId)
		end
		LeaderstatsService.setTowerStat(player, towerInfo, towerInfo.towerPoints)
	end
end

local function awardRushCompletion(playerInfo: PlayerInfo, towerRushName: string, rushTime: number)
	local rushInfo = rushInfoMap[towerRushName]
	local rushConfig = TowerRushes[towerRushName]

	if not rushInfo or not rushConfig then
		Log({
			type = "warn",
			[1] = `Attempted to award completion for unknown rush: {towerRushName}`,
		})
		return
	end

	local title = rushInfo.name
	local difficulty = Util.getDifficultyByRating(rushInfo.rating)
	local badgeId = rushInfo.badgeId

	AnnouncementService.winAnnouncement(playerInfo, title, difficulty, rushTime)
	TowerRushData.recordRushWin(
		playerInfo.player,
		towerRushName,
		rushTime,
		playerInfo.boostItemUsed,
		playerInfo.mode == "AllJumps"
	)

	if badgeId and badgeId ~= 0 then
		BadgeService:AwardBadgeAsync(playerInfo.player.UserId, badgeId)
	end

	PlayerState.teleportToWinroom(playerInfo, rushConfig.winroomMarker)
end

-- Begin a tower rush for the player, initializing rush state and loading the first tower.
function TowerRushService.loadTowerRush(player: PlayerInfo, towerRushName: string)
	local towerRush: TowerRush? = TowerRushes[towerRushName]

	if not towerRush then
		Log({
			type = "warn",
			[1] = `Unknown tower rush "{towerRushName}"`,
		})
		return
	end

	if player.isLoadingTower then
		return
	end

	player.currentTowerRush = towerRushName
	player.currentTowerRushIndex = 1
	player.currentTowerRushSplitTime = 0
	player.boostItemUsed = false
	player.boostItemNames = {}

	TowerRushData.incrementRushAttempt(player.player, towerRushName)
	TowerService.loadTower(player, towerRush.towers[1], true)
	BlinkServer.UpdateTowerRush.Fire(player.player, 1, #towerRush.towers)
end

-- Advance a player to the next tower in their active rush or complete the rush if on the final tower.
function TowerRushService.advanceTowerRush(player: PlayerInfo)
	local towerRush: TowerRush? = TowerRushes[player.currentTowerRush]
	if not towerRush then
		return
	end

	local currentTowerName = towerRush.towers[player.currentTowerRushIndex]
	local towerInfo = TowerService.getTower(currentTowerName)
	local rushTime = player.towerTimer
	local splitTime = rushTime - player.currentTowerRushSplitTime

	if towerInfo then
		awardTowerCompletion(player, towerInfo, splitTime)
	end

	local towerCount = #towerRush.towers
	if player.currentTowerRushIndex == towerCount then
		awardRushCompletion(player, player.currentTowerRush, rushTime)
		return
	end

	player.currentTowerRushIndex += 1
	player.currentTowerRushSplitTime = rushTime

	local towerName = towerRush.towers[player.currentTowerRushIndex]
	TowerService.loadTower(player, towerName, false)
	BlinkServer.UpdateTowerRush.Fire(player.player, player.currentTowerRushIndex, towerCount)
end

return TowerRushService
