local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared

local Announcements = require("../Announcements")
local Attributes = require("../../Utils/Attributes")
local DataInfo = require("./DataInfo")
local LeaderstatsManager = require("../../Core/LeaderstatsManager")
local PlayerState = require("../../Core/PlayerState")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type Dictionary<T> = Types.Dictionary<T>
type EndingInfo = Types.EndingInfo
type List<T> = Types.List<T>
type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local WinpadParticles = ServerStorage.WinpadParticles

local WinpadManager = {}
WinpadManager.Winpads = {} :: List<BasePart>

local function PlayerTouchedWinpad(playerName: string, towerName: string, endingID: string)
	local TowerManager = require("./TowerManager")

	local player: PlayerInfo = DataInfo.PlayerInfo[playerName]
	local tower: TowerInfo = DataInfo.TowerInfo[towerName]
	if not player or not tower then
		return
	end

	if player.TouchEventBusy then
		return
	end
	player.TouchEventBusy = true

	local ending: EndingInfo = tower.Endings[endingID]
	assert(ending, `{playerName} touched a winpad in {towerName}, but the ending referenced does not exist`)

	if player.CurrentTower == "" then
		player.TouchEventBusy = false
		return
	end

	-- Check to see if this ending is from this tower, if it's not, the player is probably cheating
	if ending.ParentTower ~= player.CurrentTower then
		Announcements:AntiCheatKick(player.Player, "Touched the winpad of a tower you're not in")
		return
	end

	-- Anything checks inside this block do not apply if the player has equipped a debug item
	if not player.DebugItemUsed then
		-- If the player completed the tower before the minumum time, they beat the tower too early! they must be cheating
		if (tower.MinimumTime > 0) and (player.TowerTimer < tower.MinimumTime) then
			Announcements:AntiCheatKick(player.Player, "Completed the tower too early")
			return
		end

		-- If the player hasn't hit the checkpoints in order, they beat the tower out of order!
		if player.CurrentTowerCheckpoint < tower.CheckpointCount then
			Announcements:AntiCheatKick(player.Player, "Completed the tower out of order")
			return
		end
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

		Announcements:WinAnnouncement(player, endingName, endingDifficultyName)
		-- Award badge(s)

		if tower.BadgeID ~= 0 and not ending.PreventTowerBadge then
			BadgeService:AwardBadge(player.Player.UserId, tower.BadgeID)
		end
		if ending.BadgeID ~= 0 then
			BadgeService:AwardBadge(player.Player.UserId, ending.BadgeID)
		end

		-- only adjust tower points if the player won the tower, not the secret ending.
		if endingID == towerName then
			LeaderstatsManager:UpdatePlayerTowerData(player.Player, tower, tower.TowerPoints)
		end

		PlayerState:TeleportToWinroom(player, endingWinroom)
	else
		-- The player is doing a tower rush
		TowerManager:AdvanceTowerRush(playerName)
	end		

	task.wait(0.1)
	player.TouchEventBusy = false
end

local function Setup(towerName: string, winpad: BasePart)
	-- Give the winpad it's funny particles
	local particles = WinpadParticles:Clone()
	particles.Parent = winpad

	-- Figure out it's EndingID (if it has none, it's "default")
	local endingID = Attributes:GetString(winpad, "EndingID") or ""
	if endingID == "" then
		winpad:SetAttribute("EndingID", towerName)
		endingID = towerName
	end
	
	-- Figure out the acronym of the tower this winpad belongs too
	-- A winpad inside of the tower folder will have this value implicitely figured out automatically (unless explicetely defined otherwise, though I'm not sure why you would want to do that lol)
	-- A winpad outside of the tower folder must explicitely define this property (or else error)
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
		PreventTowerBadge = Attributes:GetBoolean(winpad, "PreventTowerBadge") or false,
		ParentTower = towerName,
		WinroomMarker = Attributes:GetString(winpad, "WinroomMarker") or Attributes:GetString(winpad, "Winroom") or ""
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
		
		PlayerTouchedWinpad(playerName, towerName, endingID)
	end)
	
end

function WinpadManager:InitWinpad(towerName: string, winpad: BasePart)
	Setup(towerName, winpad)
	table.insert(WinpadManager.Winpads, winpad)
end

return WinpadManager
