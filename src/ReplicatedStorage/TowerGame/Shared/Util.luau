local Players = game:GetService("Players")

local Config = require("../GameData/Config")
local DifficultiesModule = require("../GameData/Difficulties")
local RealmInfo = require("../RealmData/RealmInfo")
local Types = require("./Types")

type List<T> = Types.List<T>
type Dictionary<T> = Types.Dictionary<T>
type PlayerInfo = Types.PlayerInfo
type TowerRush = Types.TowerRush
type TowerInfo = Types.TowerInfo
type EndingInfo = Types.EndingInfo
type Difficulty = Types.DifficultyInfo

local DIFFICULTIES = DifficultiesModule.Data
local HIP_OFFSET = CFrame.new(0, 3, 0)
local WARNING_TAG = "[MTKv4.1.1] "

local DEFAULT_DIFFICULTY: Difficulty = {
	Title = "unknown",
	Rating = 0,
	Color = Color3.new(1, 1, 1),

	FancyFont = false,
	GlobalAnnouncement = false,
	GlobalAJAnnouncement = false,
}

local Util = {}

function Util.getDifficulty(difficultyName: string)
	local search: Difficulty? = DIFFICULTIES[difficultyName]
	return search or DEFAULT_DIFFICULTY
end

function Util.warn(message: string)
	if Config.QUIET then
		return
	end
	warn(`{WARNING_TAG}{message}`)
end

function Util.isPlayerPart(hit: BasePart)
	local parent = hit.Parent
	if parent and parent:IsA("Model") and parent:FindFirstChild("Humanoid") then
		local player = Players:GetPlayerFromCharacter(parent)
		if player then
			return true, player.Name
		end
	end
	return false, ""
end

function Util.isPlayerAlive(character: Model?)
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.Health > 0
	end
	return false
end

function Util.isPointInPart(point: Vector3, part: BasePart)
	local localPoint: Vector3 = part.CFrame:PointToObjectSpace(point)
	local unitPoint: Vector3 = localPoint / part.Size
	return (
		unitPoint.X <= 0.5
		and unitPoint.X >= -0.5
		and unitPoint.Y <= 0.5
		and unitPoint.Y >= -0.5
		and unitPoint.Z <= 0.5
		and unitPoint.Z >= -0.5
	)
end

function Util.teleportPlayerToPart(player: Player, destination: BasePart)
	local character = player.Character or player.CharacterAdded:Wait()
	character:PivotTo(destination.CFrame * HIP_OFFSET)
end

function Util.formatTimeSyntax(text: string)
	return text:gsub("{Time:(%d+%.?%d*)}", function(num: string)
		local n = tonumber(num) or 0
		return Util.formatTimer(n)
	end)
end

function Util.padWithLeadingZero(n: number)
	return if n < 10 then `0{n}` else tostring(n)
end

function Util.formatTimer(time: number)
	local ms = math.floor((time % 1) * 100)
	local s = math.floor(time % 60)
	local m = math.floor(time / 60)

	return `{Util.padWithLeadingZero(m)}:{Util.padWithLeadingZero(s)}.{Util.padWithLeadingZero(ms)}`
end

function Util.formatDuration(time: number)
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

function Util.formatBoosts(boosts: Dictionary<string>)
	local boostList: { string } = {}
	for _, boostName in boosts do
		table.insert(boostList, boostName)
	end

	return table.concat(boostList, ", ")
end

function Util.registerTouch(part: BasePart, onRequestTouch: (playerName: string, part: BasePart) -> ())
	if not part:IsA("BasePart") then
		return
	end

	local debounce: { [string]: boolean } = {}

	part.Touched:Connect(function(hit)
		local isPlayer, playerName = Util.isPlayerPart(hit)
		if not isPlayer then
			return
		end

		local player: Player = Players:FindFirstChild(playerName)
		if not player or not Util.isPlayerAlive(player.Character) then
			return
		end

		if debounce[playerName] then
			return
		end

		debounce[playerName] = true
		onRequestTouch(playerName, part)

		task.delay(0.1, function()
			debounce[playerName] = false
		end)
	end)
end

function Util.respawnAndTeleport(player: Player, spawnPart: BasePart)
	player:LoadCharacterAsync()

	local character = player.Character or player.CharacterAdded:Wait()

	local forceField = character:FindFirstChildWhichIsA("ForceField")
	if forceField then
		forceField:Destroy()
	end

	Util.teleportPlayerToPart(player, spawnPart)
end

function Util.getDifficultyColors(difficultyName: string)
	local difficulty = Util.getDifficulty(difficultyName)
	local color = difficulty.Color
	local stroke = Color3.new(color.R * 0.35, color.G * 0.35, color.B * 0.35)

	return color, stroke
end

function Util.getRealmTowerInfo(acronym: string)
	for _, worldData in RealmInfo :: any do
		for _, areaData in worldData do
			if areaData.Towers and areaData.Towers[acronym] then
				return areaData.Towers[acronym]
			end
		end
	end
	return nil
end

function Util.getDifficultyByRating(rating: number)
	for name, info in DIFFICULTIES do
		if info.Rating == rating then
			return name
		end
	end
	return ""
end

function Util.getTowerColors(acronym: string)
	local realmTower = Util.getRealmTowerInfo(acronym)
	if realmTower then
		local difficultyName = Util.getDifficultyByRating(realmTower.Rating)
		if difficultyName then
			return Util.getDifficultyColors(difficultyName)
		end
	end

	return Color3.new(1, 1, 1), Color3.new(0.35, 0.35, 0.35)
end

function Util.getFormattedDifficultyRichText(rating: number, numDifficulty: number)
	local diffName = Util.getDifficultyByRating(rating) or "Unknown"
	local subDiff, subColor = DifficultiesModule.GetSubDetails(numDifficulty)

	local difficultyInfo = Util.getDifficulty(diffName)
	local tColor = difficultyInfo.Color

	local subHex = subColor:ToHex()
	local diffHex = tColor:ToHex()

	local ratingDisplay = tostring(rating)
	if numDifficulty > 0 then
		ratingDisplay = string.format("%d.%02d", rating, numDifficulty * 100)
	end

	return string.format(
		'<font color="#%s">%s</font> <font color="#%s">%s</font> <font color="#%s">[%s]</font>',
		subHex,
		subDiff,
		diffHex,
		diffName,
		subHex,
		ratingDisplay
	)
end

function Util.getRainbowColor()
	local speed = 0.2
	return Color3.fromHSV((os.clock() * speed) % 1, 1, 1)
end

return Util
