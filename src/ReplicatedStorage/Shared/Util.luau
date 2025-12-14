-- Licensed under the MIT License
-- Original Copyright (c) 2023 fanofpixels
-- Modifications Copyright (c) 2025 Zylx

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

local Config = require(GameData.Config)
local Difficulties = require(GameData.Difficulties)

local Towers = workspace.Towers

local warningTag = "[MTKv4] "

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
	local character = player.Character
	if not character then
		return
	end

	character:PivotTo(destination.CFrame * hip)
end

-- Teleports the player's character, and if it isn't loaded, waits until it is
function Util:TeleportPlayerToPartWithWait(player: Player, destination: BasePart)
	local character = player.Character
	if not character then
		repeat
			task.wait(0.05)
			character = player.Character
			if player.Character then
				player.Character:PivotTo(destination.CFrame * hip)
			end
		until character
		return
	end

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

	local hasBoosts = if #boostList > 0 then table.concat(boostList, ", ") else ""

	return hasBoosts
end

-- made it as a function so it doesn't always get repeated. rn they are only used on markers and portals
function Util:RegisterTouch(part: BasePart, onTouch: (playerName: string, part: BasePart) -> ())
	if not part or not part:IsA("BasePart") then
		return
	end

	part.Touched:Connect(function(hit)
		local isPlayer, playerName = Util:IsPlayerPart(hit)
		if isPlayer then
			onTouch(playerName, part)
		end
	end)
end

function Util:RespawnAndTeleport(player: Player, spawnPart: BasePart)
	player:LoadCharacterAsync()

	local character: Model?
	repeat
		task.wait(0.05)
		character = player.Character
	until player.Character

	if not character then
		Util:Warn(`Character failed to load for {player.Name}`)
		return
	end

	local ForceField = character:FindFirstChildWhichIsA("ForceField")
	if ForceField then
		ForceField:Destroy()
	end

	Util:TeleportPlayerToPartWithWait(player, spawnPart)
end

---------------------------------------------------------------------------------------

-- get the difficulty and their difficulty color 2nd returned value is used for the stroke color
function Util:GetDifficultyColors(difficultyName: string)
	local color = Util:GetDifficulty(difficultyName).Color
	local stroke = Color3.new(color.R * 0.35, color.G * 0.35, color.B * 0.35)
	return color, stroke
end

-- get the tower difficulty and their difficulty color 2nd returned value is used for the stroke color
function Util:GetTowerColors(acronym: string)
	local tower = Towers:FindFirstChild(acronym)
	local difficultyValue = tower and tower:FindFirstChild("Difficulty") :: StringValue?

	if difficultyValue then
		return Util:GetDifficultyColors(difficultyValue.Value)
	end

	return Color3.new(1, 1, 1), Color3.new(0.35, 0.35, 0.35)
end

return Util
