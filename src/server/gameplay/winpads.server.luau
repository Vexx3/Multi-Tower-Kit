--[[
	Winpad collision detection and tower completion.
	Includes anti-cheat validation.
]]

local BadgeService = game:GetService("BadgeService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Attributes = require("../../shared/attributes")
local Config = require("../../shared/constants/config")
local Hooks = require("../../shared/hooks")
local Types = require("../../shared/types")
local Util = require("../../shared/utils/util")
local accounts = require("../accounts")
local announcements = require("./announcements")
local leaderstats = require("../lib/leaderstats")
local playerState = require("../lib/playerState")
local players = require("../lib/players")
local sessionStore = require("../stores/sessionStore")
local tickets = require("./tickets")
local towerRush = require("./towerRush")
local towers = require("./towers")

local TowerRushes = require("../../shared/constants/towerRushes")

type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo
type EndingInfo = Types.EndingInfo

local TOWERS = (workspace :: any).Towers
local WINPAD_PARTICLES = (ServerStorage :: any).WinpadParticles
local WINPAD_MATERIALS = Enum.Material:GetEnumItems()

local winpads: { BasePart } = {}

--- Validates that a win is legitimate.
local function validateWin(player: PlayerInfo, tower: TowerInfo, ending: EndingInfo): (boolean, string)
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

--- Handles normal (non-rush) tower completion.
local function handleNormalCompletion(
	player: PlayerInfo,
	tower: TowerInfo,
	ending: EndingInfo,
	endingId: string,
	towerName: string
)
	local endingDifficultyName = if endingId == towerName then tower.difficulty else ending.difficulty
	local endingName = if endingId == towerName then tower.name else ending.name
	local endingWinroom = ending.winroomMarker

	local runTime = player.towerTimer
	announcements.winAnnouncement(player, endingName, endingDifficultyName, runTime)

	local isAllJumps = player.mode == "AllJumps"

	Hooks.fire("TowerWon", player.player, towerName, runTime, isAllJumps)

	if not isAllJumps then
		if tower.badgeId ~= 0 and not ending.preventTowerBadge then
			BadgeService:AwardBadgeAsync(player.player.UserId, tower.badgeId)
		end

		if ending.badgeId ~= 0 then
			BadgeService:AwardBadgeAsync(player.player.UserId, ending.badgeId)
		end
	end

	if endingId == towerName then
		if isAllJumps then
			if tower.ajBadgeId and tower.ajBadgeId ~= 0 then
				BadgeService:AwardBadgeAsync(player.player.UserId, tower.ajBadgeId)
			end

			accounts.recordTowerWin(player.player, towerName, runTime, player.boostItemUsed, true)
			leaderstats.setAllJumpsStat(player.player, tower, tower.allJumpsPoints or tower.towerPoints)
		else
			accounts.recordTowerWin(player.player, towerName, runTime, player.boostItemUsed)
			leaderstats.setTowerStat(player.player, tower, tower.towerPoints)

			if not player.boostItemUsed then
				tickets.awardTickets(player.player, tower)
			end
		end
	end

	playerState.teleportToWinroom(player, endingWinroom)
end

--- Handles winpad touch event.
local function onPlayerTouchedWinpad(
	playerName: string,
	towerName: string,
	endingId: string,
	tower: TowerInfo,
	ending: EndingInfo
)
	local player = players.getSession(playerName)
	if not player or not tower then
		return
	end

	if player.boostItemUsed then
		if tower.noBoosts then
			return
		end

		if player.currentTowerRush ~= "" then
			local rush = TowerRushes[player.currentTowerRush]
			if rush and rush.noBoosts then
				return
			end
		end
	end

	if player.mode == "Practice" or player.touchEventBusy then
		return
	end

	sessionStore.setTouchBusy(playerName, true)

	if player.currentTower == "" then
		sessionStore.setTouchBusy(playerName, false)
		return
	end

	local valid, reason = validateWin(player, tower, ending)
	if not valid then
		announcements.antiCheatKick(player.player, reason)
		sessionStore.setTouchBusy(playerName, false)
		return
	end

	if player.currentTowerRush == "" then
		handleNormalCompletion(player, tower, ending, endingId, towerName)
	else
		towerRush.advanceTowerRush(player)
	end

	task.wait(0.1)
	sessionStore.setTouchBusy(playerName, false)
end

--- Sets up a winpad with particles and touch detection.
local function setupWinpad(towerName: string, winpad: BasePart, tower: TowerInfo)
	local particles = WINPAD_PARTICLES:Clone()
	particles.Parent = winpad

	local endingId = Attributes.getString(winpad, "EndingID") or ""
	if endingId == "" then
		winpad:SetAttribute("EndingID", towerName)
		endingId = towerName
	end

	local parentTower = Attributes.getString(winpad, "ParentTower") or ""
	if parentTower == "" then
		winpad:SetAttribute("ParentTower", towerName)
	end

	local ending = {
		name = Attributes.getString(winpad, "EndingName") or tower.name,
		difficulty = Attributes.getString(winpad, "Difficulty") or tower.difficulty,
		badgeId = Attributes.getInt(winpad, "BadgeID") or 0,
		preventTowerBadge = Attributes.getBoolean(winpad, "PreventTowerBadge") or false,
		parentTower = towerName,
		winroomMarker = Attributes.getString(winpad, "WinroomMarker") or Attributes.getString(winpad, "Winroom") or "",
	}

	tower.endings[endingId] = ending

	Util.registerTouch(winpad, function(playerName)
		onPlayerTouchedWinpad(playerName, towerName, endingId, tower, ending)
	end)

	table.insert(winpads, winpad)
end

--- Updates winpad animations (color/material changes).
local function updateWinpadAnimations(_time: number, deltaTime: number)
	local prevInterval = math.floor((_time - deltaTime) / Config.winpadInterval) * Config.winpadInterval
	local currentInterval = math.floor(_time / Config.winpadInterval) * Config.winpadInterval

	if prevInterval < currentInterval then
		for _, winpad in winpads do
			if Config.winpadsChangeColor then
				winpad.Color = Color3.fromHSV(math.random(0, 100) / 100, 1, 1)
			end

			if Config.winpadsChangeMaterial then
				winpad.Material = WINPAD_MATERIALS[math.random(1, #WINPAD_MATERIALS)]
			end
		end
	end
end

-- Wait for towers to be registered by init.server.luau before discovering winpads
while not next(towers.getAllTowers()) do
	task.wait()
end

-- Discover all winpads and set them up
for _, towerFolder in TOWERS:GetChildren() do
	local tower = towers.getTower(towerFolder.Name)
	if not tower then
		continue
	end

	for _, descendant in towerFolder:GetDescendants() do
		if descendant.Name == "WinPad" and descendant:IsA("BasePart") then
			setupWinpad(towerFolder.Name, descendant, tower)
		end
	end
end

RunService.Stepped:Connect(updateWinpadAnimations)
