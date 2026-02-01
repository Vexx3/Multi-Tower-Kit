--[[
	WinpadService - Handles winpad collision detection and tower completion.
	Includes anti-cheat validation.
]]

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Data = Shared.Data

local AnnouncementService = require("./AnnouncementService")
local Attributes = require(Shared.Attributes)
local Config = require(Data.Config)
local LeaderstatsService = require("./LeaderstatsService")
local PlayerService = require("./PlayerService")
local PlayerState = require("../Player/PlayerState")
local Session = require("../Producers/SessionManager")
local TicketService = require("./TicketService")
local TowerData = require("../Player/PlayerData/TowerData")
local TowerRushService = require("./TowerRushService")
local TowerService = require("./TowerService")
local Util = require(Shared.Util)

local TowerRushes = require(Data.TowerRushes)

local TOWERS = (workspace :: any).Towers
local WINPAD_PARTICLES = (ServerStorage :: any).WinpadParticles
local WINPAD_MATERIALS = Enum.Material:GetEnumItems()

local winpads = {}

--- Validates that a win is legitimate.
local function validateWin(player: any, tower: any, ending: any): (boolean, string)
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
local function handleNormalCompletion(player: any, tower: any, ending: any, endingId: string, towerName: string)
	local endingDifficultyName = if endingId == towerName then tower.difficulty else ending.difficulty
	local endingName = if endingId == towerName then tower.name else ending.name
	local endingWinroom = ending.winroomMarker

	local runTime = player.towerTimer
	AnnouncementService.winAnnouncement(player, endingName, endingDifficultyName, runTime)

	local isAllJumps = player.mode == "AllJumps"

	-- Award badges for normal mode completions
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

			TowerData.recordTowerWin(player.player, towerName, runTime, player.boostItemUsed, true)
			LeaderstatsService.setAllJumpsStat(player.player, tower, tower.allJumpsPoints or tower.towerPoints)
		else
			TowerData.recordTowerWin(player.player, towerName, runTime, player.boostItemUsed)
			LeaderstatsService.setTowerStat(player.player, tower, tower.towerPoints)

			if not player.boostItemUsed then
				TicketService.awardTickets(player.player, tower)
			end
		end
	end

	PlayerState.teleportToWinroom(player, endingWinroom)
end

--- Handles winpad touch event.
local function onPlayerTouchedWinpad(playerName: string, towerName: string, endingId: string, tower: any, ending: any)
	local player = PlayerService.getSession(playerName)
	if not player or not tower then
		return
	end

	-- Check boost restrictions
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

	Session.setTouchBusy(playerName, true)

	if player.currentTower == "" then
		Session.setTouchBusy(playerName, false)
		return
	end

	local valid, reason = validateWin(player, tower, ending)
	if not valid then
		AnnouncementService.antiCheatKick(player.player, reason)
		Session.setTouchBusy(playerName, false)
		return
	end

	if player.currentTowerRush == "" then
		handleNormalCompletion(player, tower, ending, endingId, towerName)
	else
		TowerRushService.advanceTowerRush(player)
	end

	task.wait(0.1)
	Session.setTouchBusy(playerName, false)
end

--- Sets up a winpad with particles and touch detection.
local function setupWinpad(towerName: string, winpad: BasePart, tower: any)
	-- Add particles
	local particles = WINPAD_PARTICLES:Clone()
	particles.Parent = winpad

	-- Get or set ending ID
	local endingId = Attributes.getString(winpad, "EndingID") or ""
	if endingId == "" then
		winpad:SetAttribute("EndingID", towerName)
		endingId = towerName
	end

	-- Set parent tower if not set
	local parentTower = Attributes.getString(winpad, "ParentTower") or ""
	if parentTower == "" then
		winpad:SetAttribute("ParentTower", towerName)
	end

	-- Build ending info
	local ending = {
		name = Attributes.getString(winpad, "EndingName") or tower.name,
		difficulty = Attributes.getString(winpad, "Difficulty") or tower.difficulty,
		badgeId = Attributes.getInt(winpad, "BadgeID") or 0,
		preventTowerBadge = Attributes.getBoolean(winpad, "PreventTowerBadge") or false,
		parentTower = towerName,
		winroomMarker = Attributes.getString(winpad, "WinroomMarker") or Attributes.getString(winpad, "Winroom") or "",
	}

	-- Register ending with tower
	tower.endings[endingId] = ending

	-- Setup touch handler
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

local WinpadService = {}

--- Initializes the winpad service, discovers all winpads, and starts animations.
function WinpadService.Start()
	for _, towerFolder in TOWERS:GetChildren() do
		local tower = TowerService.getTower(towerFolder.Name)
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
end

return WinpadService
