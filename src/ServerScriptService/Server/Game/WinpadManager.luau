-- Licensed under the MIT License
-- Copyright (c) 2025 Zylx

--[=[
	Handles winpad collision detection, player win validation, badge awarding,
	and tower completion processing including rush advancement.

	@class WinpadManager
	@server
]=]

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared

local Announcements = require("../Services/Announcements")
local AntiCheat = require("./AntiCheat")
local Attributes = require("../Helpers/Attributes")
local DataInfo = require("./DataInfo")
local LeaderstatsManager = require("../Player/LeaderstatsManager")
local PlayerState = require("../Player/PlayerState")
local TowerData = require("../Player/PlayerData/TowerData")
local TowerRushManager = require("./TowerRushManager")
local TowerRushes = require(ReplicatedStorage.RealmData.TowerRushes)
local TowerSignManager = require("./TowerSignManager")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type Dictionary<T> = Types.Dictionary<T>
type EndingInfo = Types.EndingInfo
type List<T> = Types.List<T>
type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local TOWERS = workspace.Towers
local WINPAD_PARTICLES = ServerStorage.WinpadParticles

local WinpadManager = {}
WinpadManager.Winpads = {} :: List<BasePart>

local function onPlayerTouchedWinpad(playerName: string, towerName: string, endingID: string)
	local player: PlayerInfo = DataInfo.PlayerInfo[playerName]
	local tower: TowerInfo = DataInfo.TowerInfo[towerName]
	if not player or not tower then
		return
	end

	if tower.NoBoostItems and player.BoostItemUsed then
		return
	end

	if player.CurrentTowerRush ~= "" then
		local rush = TowerRushes[player.CurrentTowerRush]
		if rush and rush.NoBoostItems and player.BoostItemUsed then
			return
		end
	end

	if player.PracticeMode then
		return
	end

	if player.TouchEventBusy then
		return
	end

	player.TouchEventBusy = true

	local ending: EndingInfo = tower.Endings[endingID]
	assert(ending, `{playerName} touched a winpad in {towerName}, but the ending referenced does not exist`)

	if player.CurrentTower == "" then
		return
	end

	local valid, reason = AntiCheat:ValidateWin(player, tower, ending)
	if not valid then
		Announcements:AntiCheatKick(player.Player, reason)
		return
	end

	if player.CurrentTowerRush == "" then
		-- The player is doing a singular tower
		-- The info that will be used in the win message
		local endingDifficultyName = tower.Difficulty
		local endingName = tower.Name
		local endingWinroom = ending.WinroomMarker

		-- Override it if this isn't the default ending
		if endingID ~= towerName then
			endingDifficultyName = ending.Difficulty
			endingName = ending.Name
		end

		local runTime = player.TowerTimer
		Announcements:WinAnnouncement(player, endingName, endingDifficultyName, runTime)

		local onAJMode = player.AllJumpsMode

		-- Award badge(s)
		if not onAJMode then
			if tower.BadgeID ~= 0 and not ending.PreventTowerBadge then
				BadgeService:AwardBadgeAsync(player.Player.UserId, tower.BadgeID)
			end
			if ending.BadgeID ~= 0 then
				BadgeService:AwardBadgeAsync(player.Player.UserId, ending.BadgeID)
			end
		end

		-- only adjust tower points if the player won the tower, not the secret ending.
		if endingID == towerName then
			if onAJMode then
				if tower.AJBadgeID ~= 0 then
					BadgeService:AwardBadgeAsync(player.Player.UserId, tower.AJBadgeID)
				end

				TowerData:RecordTowerWin(player.Player, towerName, runTime, player.BoostItemUsed, true)
				LeaderstatsManager:SetAllJumpsStat(player.Player, tower, tower.TowerPoints)
			else
				TowerData:RecordTowerWin(player.Player, towerName, runTime, player.BoostItemUsed)
				LeaderstatsManager:SetTowerStat(player.Player, tower, tower.TowerPoints)
				TowerSignManager:MarkTowerCompleted(towerName)
			end
		end

		PlayerState:TeleportToWinroom(player, endingWinroom)
	else
		-- The player is doing a tower rush
		TowerRushManager:AdvanceTowerRush(playerName)
	end

	task.wait(0.1)
	player.TouchEventBusy = false
end

local function setupWinpad(towerName: string, winpad: BasePart)
	local particles = WINPAD_PARTICLES:Clone()
	particles.Parent = winpad

	local endingID = Attributes:GetString(winpad, "EndingID") or ""
	if endingID == "" then
		winpad:SetAttribute("EndingID", towerName)
		endingID = towerName
	end

	-- Determine the parent tower. Winpads inside tower folders inherit it implicitly.
	-- Winpads outside must explicitly define the ParentTower attribute.
	local parentTower = Attributes:GetString(winpad, "ParentTower") or ""
	if parentTower == "" then
		assert(towerName ~= "", `Could not setup winpad {winpad:GetFullName()} because its parent tower is undefined`)
		winpad:SetAttribute("ParentTower", towerName)
	end

	-- Get the tower this winpad says it belongs to
	local tower: TowerInfo? = DataInfo.TowerInfo[towerName]
	assert(tower, `Could not set up winpad {winpad:GetFullName()} because its parent tower does not exist`)

	-- Construct the ending object,
	local ending: EndingInfo = {
		Name = Attributes:GetString(winpad, "EndingName") or tower.Name,
		Difficulty = Attributes:GetString(winpad, "Difficulty") or tower.Difficulty,
		BadgeID = Attributes:GetInt(winpad, "BadgeID") or 0,
		AJBadgeID = Attributes:GetInt(winpad, "AJBadgeID") or 0,
		PreventTowerBadge = Attributes:GetBoolean(winpad, "PreventTowerBadge") or false,
		ParentTower = towerName,
		WinroomMarker = Attributes:GetString(winpad, "WinroomMarker") or Attributes:GetString(winpad, "Winroom") or "",
	}

	-- and set it
	tower.Endings[endingID] = ending

	winpad.Touched:Connect(function(hit)
		local isPlayer, playerName = Util:IsPlayerPart(hit)
		local player: PlayerInfo = DataInfo.PlayerInfo[playerName]
		if not isPlayer and player and player.TouchEventBusy then
			return
		end

		-- Guard clause to prevent player from winning while dead
		if player and not Util:IsPlayerAlive(player.Player.Character) then
			return
		end

		onPlayerTouchedWinpad(playerName, towerName, endingID)
	end)
end

local function initWinpad(towerName: string, winpad: BasePart)
	setupWinpad(towerName, winpad)
	table.insert(WinpadManager.Winpads, winpad)
end

function WinpadManager:InitWinpads()
	for _, tower in TOWERS:GetChildren() do
		for _, descendant in tower:GetDescendants() do
			if descendant.Name == "WinPad" and descendant:IsA("BasePart") then
				initWinpad(tower.Name, descendant)
			end
		end
	end
end

return WinpadManager
