--[[
	Coordinates tower rush flow: starting rushes, advancing through towers,
	and awarding completions.
]]

local BadgeService = game:GetService("BadgeService")

local BlinkServer = require("../Network/BlinkServer")
local Hooks = require("../../shared/hooks")
local Log = require("../../../Framework/Log")
local RealmInfo = require("../../shared/constants/realmInfo")
local Types = require("../../shared/types")
local Util = require("../../shared/utils/util")
local accounts = require("../accounts")
local announcements = require("./announcements")
local leaderstats = require("../lib/leaderstats")
local playerState = require("../lib/playerState")
local sessionStore = require("../stores/sessionStore")
local towers = require("./towers")

type TowerRush = Types.TowerRush
type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local TowerRushes = require("../../shared/constants/towerRushes")

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

local function awardTowerCompletion(playerInfo: PlayerInfo, towerInfo: TowerInfo, splitTime: number)
	local player = playerInfo.player
	local isAllJumps = playerInfo.mode == "AllJumps"

	accounts.recordTowerWin(player, towerInfo.folder.Name, splitTime, playerInfo.boostItemUsed, isAllJumps)

	if isAllJumps then
		if towerInfo.ajBadgeId and towerInfo.ajBadgeId ~= 0 then
			BadgeService:AwardBadgeAsync(player.UserId, towerInfo.ajBadgeId)
		end
		leaderstats.setAllJumpsStat(player, towerInfo, towerInfo.allJumpsPoints or towerInfo.towerPoints)
	else
		if towerInfo.badgeId ~= 0 then
			BadgeService:AwardBadgeAsync(player.UserId, towerInfo.badgeId)
		end
		leaderstats.setTowerStat(player, towerInfo, towerInfo.towerPoints)
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

	announcements.winAnnouncement(playerInfo, title, difficulty, rushTime)
	accounts.recordRushWin(
		playerInfo.player,
		towerRushName,
		rushTime,
		playerInfo.boostItemUsed,
		playerInfo.mode == "AllJumps"
	)

	if badgeId and badgeId ~= 0 then
		BadgeService:AwardBadgeAsync(playerInfo.player.UserId, badgeId)
	end

	playerState.teleportToWinroom(playerInfo, rushConfig.winroomMarker)
end

local towerRush = {}

--- Begins a tower rush for the player, initializing rush state and loading the first tower.
function towerRush.loadTowerRush(player: PlayerInfo, towerRushName: string)
	local rushConfig: TowerRush? = TowerRushes[towerRushName]

	if not rushConfig then
		Log({
			type = "warn",
			[1] = `Unknown tower rush "{towerRushName}"`,
		})
		return
	end

	if player.isLoadingTower then
		return
	end

	local playerName = player.player.Name

	sessionStore.update(playerName, {
		currentTowerRush = towerRushName,
		currentTowerRushIndex = 1,
		currentTowerRushSplitTime = 0,
		boostItemUsed = false,
		boostItemNames = {},
	})

	accounts.incrementRushAttempt(player.player, towerRushName)

	local freshSession = sessionStore.get(playerName)
	if freshSession then
		playerState.updatePlayerInfoStats(freshSession)
		towers.loadTower(freshSession, rushConfig.towers[1], true)
	end

	BlinkServer.UpdateTowerRush.Fire(player.player, 1, #rushConfig.towers)
end

--- Advances a player to the next tower in their active rush or completes the rush.
function towerRush.advanceTowerRush(player: PlayerInfo)
	local rushConfig: TowerRush? = TowerRushes[player.currentTowerRush]
	if not rushConfig then
		return
	end

	local currentTowerName = rushConfig.towers[player.currentTowerRushIndex]
	local towerInfo = towers.getTower(currentTowerName)
	local rushTime = player.towerTimer
	local splitTime = rushTime - player.currentTowerRushSplitTime

	if towerInfo then
		awardTowerCompletion(player, towerInfo, splitTime)
	end

	local towerCount = #rushConfig.towers
	if player.currentTowerRushIndex == towerCount then
		Hooks.fire("TowerRushCompleted", player.player, player.currentTowerRush, rushTime)
		awardRushCompletion(player, player.currentTowerRush, rushTime)
		return
	end

	local nextIndex = player.currentTowerRushIndex + 1
	local playerName = player.player.Name

	sessionStore.update(playerName, {
		currentTowerRushIndex = nextIndex,
		currentTowerRushSplitTime = rushTime,
	})

	local towerName = rushConfig.towers[nextIndex]
	local freshSession = sessionStore.get(playerName)
	if freshSession then
		towers.loadTower(freshSession, towerName, false)
	end

	BlinkServer.UpdateTowerRush.Fire(player.player, nextIndex, towerCount)
end

return towerRush
