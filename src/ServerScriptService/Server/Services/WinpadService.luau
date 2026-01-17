--[=[
	Handles winpad collision detection, player win validation, and tower/rush completion.

	Registers touch events on all winpads, validates wins through AntiCheatService,
	and delegates to TowerRushService or direct completion logic based on mode.

	@class WinpadService
	@server
]=]

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Data = Shared.Data

local AnnouncementService = require("./AnnouncementService")
local AntiCheat = require("./AntiCheatService")
local Attributes = require(Shared.Attributes)
local Config = require(Data.Config)
local LeaderstatsService = require("./LeaderstatsService")
local PlayerService = require("./PlayerService")
local PlayerState = require("../Player/PlayerState")
local TicketService = require("./TicketService")
local TowerData = require("../Player/PlayerData/TowerData")
local TowerRushService = require("./TowerRushService")
local TowerService = require("./TowerService")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type Dictionary<T> = Types.Dictionary<T>
type EndingInfo = Types.EndingInfo
type List<T> = Types.List<T>
type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local TowerRushes = require(Data.TowerRushes)

local TOWERS = workspace.Towers
local WINPAD_PARTICLES = ServerStorage.WinpadParticles
local WINPAD_MATERIALS = Enum.Material:GetEnumItems()

local winpads: List<BasePart> = {}

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

local function onPlayerTouchedWinpad(playerName: string, towerName: string, endingId: string)
	local player = PlayerService.getSession(playerName)
	local tower = TowerService.getTower(towerName)

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

	player.touchEventBusy = true

	local ending: EndingInfo = tower.endings[endingId]
	assert(ending, `{playerName} touched a winpad in {towerName}, but the ending referenced does not exist`)

	if player.currentTower == "" then
		return
	end

	-- Validate win through anti-cheat
	local valid, reason = AntiCheat.validateWin(player, tower, ending)
	if not valid then
		AnnouncementService.antiCheatKick(player.player, reason)
		return
	end

	-- Handle solo tower completion vs tower rush advancement
	if player.currentTowerRush == "" then
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

		-- Record completion and update leaderstats
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

				-- Award tickets for normal completions (not AllJumps, not boosted)
				if not player.boostItemUsed then
					TicketService.awardTickets(player.player, tower)
				end
			end
		end

		PlayerState.teleportToWinroom(player, endingWinroom)
	else
		TowerRushService.advanceTowerRush(player)
	end

	task.wait(0.1)
	player.touchEventBusy = false
end

local function setupWinpad(towerName: string, winpad: BasePart)
	local particles = WINPAD_PARTICLES:Clone()
	particles.Parent = winpad

	local endingId = Attributes.getString(winpad, "EndingID") or ""
	if endingId == "" then
		winpad:SetAttribute("EndingID", towerName)
		endingId = towerName
	end

	local parentTower = Attributes.getString(winpad, "ParentTower") or ""
	if parentTower == "" then
		assert(towerName ~= "", `Could not setup winpad {winpad:GetFullName()} because its parent tower is undefined`)
		winpad:SetAttribute("ParentTower", towerName)
	end

	local tower: TowerInfo? = TowerService.getTower(towerName)
	assert(tower, `Could not set up winpad {winpad:GetFullName()} because its parent tower does not exist`)

	local ending: EndingInfo = {
		name = Attributes.getString(winpad, "EndingName") or tower.name,
		difficulty = Attributes.getString(winpad, "Difficulty") or tower.difficulty,
		badgeId = Attributes.getInt(winpad, "BadgeID") or 0,
		preventTowerBadge = Attributes.getBoolean(winpad, "PreventTowerBadge") or false,
		parentTower = towerName,
		winroomMarker = Attributes.getString(winpad, "WinroomMarker") or Attributes.getString(winpad, "Winroom") or "",
	}

	tower.endings[endingId] = ending

	Util.registerTouch(winpad, function(playerName)
		onPlayerTouchedWinpad(playerName, towerName, endingId)
	end)
end

local function initWinpad(towerName: string, winpad: BasePart)
	setupWinpad(towerName, winpad)
	table.insert(winpads, winpad)
end

local WinpadService = {}

--- Initializes the winpad service, discovers all winpads, and starts animations.
function WinpadService.Start()
	for _, tower in TOWERS:GetChildren() do
		for _, descendant in tower:GetDescendants() do
			if descendant.Name == "WinPad" and descendant:IsA("BasePart") then
				initWinpad(tower.Name, descendant)
			end
		end
	end

	RunService.Stepped:Connect(updateWinpadAnimations)
end

return WinpadService
