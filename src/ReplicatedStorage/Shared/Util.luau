--!strict
-- Written by fanofpixels

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get types
local Types = require(script.Parent.Types)

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

-- Find instances of {Time:seconds} in a string and format it
function Util:FormatTimeSyntax(text: string)
	return text:gsub("{Time:(%d+%.?%d*)}", function(num: string)
		local n = tonumber(num) or 0
		return Util:FormatTimer(n)
	end)
end

function Util:FormatTimer(time: number)
	local ms = math.floor((time % 1) * 100)
	local s = math.floor(time % 60)
	local m = math.floor(time / 60)

	local function pad2(n: number)
		return if n < 10 then `0{n}` else tostring(n)
	end

	return `{m}:{pad2(s)}.{pad2(ms)}`
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

return Util
