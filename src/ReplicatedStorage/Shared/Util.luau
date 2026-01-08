local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get types
local Types = require("./Types")

type List<T> = Types.List<T>
type Dictionary<T> = Types.Dictionary<T>
type PlayerInfo = Types.PlayerInfo
type TowerRush = Types.TowerRush
type TowerInfo = Types.TowerInfo
type EndingInfo = Types.EndingInfo
type Difficulty = Types.DifficultyInfo

----------------------------------------------------------------------------------------------

local GameData = ReplicatedStorage.GameData
local RealmData = ReplicatedStorage.RealmData

local Config = require(GameData.Config)
local DifficultiesModule = require(GameData.Difficulties)
local RealmInfo = require(RealmData.RealmInfo)
local Difficulties = DifficultiesModule.Data

local warningTag = "[MTKv4.1.1] "

-- If the difficulty specified by something is unknown, fallback to this
local defaultDifficuty: Difficulty = {
	Title = "unknown",
	Rating = 0,
	Color = Color3.new(1, 1, 1),

	FancyFont = false,
	GlobalAnnouncement = false,
}

local Util = {}

function Util:GetDifficulty(difficultyName: string)
	local search: Difficulty? = Difficulties[difficultyName]
	return search or defaultDifficuty
end

function Util:Warn(message: string)
	if Config.QUIET then
		return
	end
	warn(`{warningTag}{message}`)
end

function Util:IsPlayerPart(hit: BasePart)
	local parent = hit.Parent
	if parent and parent:IsA("Model") and parent:FindFirstChild("Humanoid") then
		local player = Players:GetPlayerFromCharacter(parent)
		if player then
			return true, player.Name
		end
	end
	return false, ""
end

function Util:IsPlayerAlive(character: Model?)
	if not character then
		return false
	end
	local Humanoid = character:FindFirstChildOfClass("Humanoid")
	if Humanoid then
		return Humanoid.Health > 0
	end
	return false
end

function Util:IsPointInPart(point: Vector3, part: BasePart)
	local LocalPoint: Vector3 = part.CFrame:PointToObjectSpace(point)
	local UnitPoint: Vector3 = LocalPoint / part.Size
	return (
		UnitPoint.X <= 0.5
		and UnitPoint.X >= -0.5
		and UnitPoint.Y <= 0.5
		and UnitPoint.Y >= -0.5
		and UnitPoint.Z <= 0.5
		and UnitPoint.Z >= -0.5
	)
end

---------------------------------------------------------------------------------------
-- Hip offset to make sure teleports dont teleport you inside of the destination
local hip = CFrame.new(0, 3, 0)

-- Teleports the player's character
function Util:TeleportPlayerToPart(player: Player, destination: BasePart)
	local character = player.Character or player.CharacterAdded:Wait()
	character:PivotTo(destination.CFrame * hip)
end

---------------------------------------------------------------------------------------

-- Find instances of {Time:seconds} in a string and format it
function Util:FormatTimeSyntax(text: string)
	return text:gsub("{Time:(%d+%.?%d*)}", function(num: string)
		local n = tonumber(num) or 0
		return Util:FormatTimer(n)
	end)
end

function Util.pad2(n: number)
	return if n < 10 then `0{n}` else tostring(n)
end

function Util:FormatTimer(time: number)
	local ms = math.floor((time % 1) * 100)
	local s = math.floor(time % 60)
	local m = math.floor(time / 60)

	return `{Util.pad2(m)}:{Util.pad2(s)}.{Util.pad2(ms)}`
end

function Util:FormatDuration(time: number)
	local totalSeconds = math.max(time, 0)
	local seconds = math.floor(totalSeconds)
	local minutes = math.floor(seconds / 60)
	local hours = math.floor(minutes / 60)

	seconds %= 60
	minutes %= 60

	local parts = {}
	if hours > 0 then
		table.insert(parts, `{hours}h`)
	end
	if minutes > 0 or hours > 0 then
		table.insert(parts, `{minutes}m`)
	end
	table.insert(parts, `{seconds}s`)

	return table.concat(parts, " ")
end

function Util:FormatBoosts(boosts: Dictionary<string>)
	local boostList: { string } = {}
	for _, boostName in boosts do
		table.insert(boostList, boostName)
	end

	return table.concat(boostList, ", ")
end

-- made it as a function so it doesn't always get repeated. rn they are only used on markers and portals
function Util:RegisterTouch(part: BasePart, onTouch: (playerName: string, part: BasePart) -> ())
	if not part:IsA("BasePart") then
		return
	end

	local debounce: { [string]: boolean } = {}

	part.Touched:Connect(function(hit)
		local isPlayer, playerName = Util:IsPlayerPart(hit)
		if not isPlayer then
			return
		end

		local player: Player = Players:FindFirstChild(playerName)
		if not player or not Util:IsPlayerAlive(player.Character) then
			return
		end

		if debounce[playerName] then
			return
		end

		debounce[playerName] = true
		onTouch(playerName, part)

		task.delay(0.1, function()
			debounce[playerName] = false
		end)
	end)
end

function Util:RespawnAndTeleport(player: Player, spawnPart: BasePart)
	player:LoadCharacterAsync()

	local character = player.Character or player.CharacterAdded:Wait()

	local ForceField = character:FindFirstChildWhichIsA("ForceField")
	if ForceField then
		ForceField:Destroy()
	end

	Util:TeleportPlayerToPart(player, spawnPart)
end

---------------------------------------------------------------------------------------

-- get the difficulty and their difficulty color 2nd returned value is used for the stroke color
function Util:GetDifficultyColors(difficultyName: string)
	local difficulty = Util:GetDifficulty(difficultyName)
	local color = difficulty.Color
	local stroke = Color3.new(color.R * 0.35, color.G * 0.35, color.B * 0.35)

	return color, stroke
end

function Util:GetRealmTowerInfo(acronym: string)
	for _, worldData in RealmInfo :: any do
		for _, areaData in worldData do
			if areaData.Towers and areaData.Towers[acronym] then
				return areaData.Towers[acronym]
			end
		end
	end
	return nil
end

function Util:GetDifficultyByRating(rating: number): string?
	for name, info in Difficulties do
		if info.Rating == rating then
			return name
		end
	end
	return nil
end

-- get the tower difficulty and their difficulty color 2nd returned value is used for the stroke color
function Util:GetTowerColors(acronym: string)
	local realmTower = Util:GetRealmTowerInfo(acronym)
	if realmTower then
		local difficultyName = Util:GetDifficultyByRating(realmTower.Rating)
		if difficultyName then
			return Util:GetDifficultyColors(difficultyName)
		end
	end

	return Color3.new(1, 1, 1), Color3.new(0.35, 0.35, 0.35)
end

return Util
