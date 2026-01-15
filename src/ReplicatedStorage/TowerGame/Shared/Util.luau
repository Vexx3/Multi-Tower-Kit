-- Utility functions used throughout the Multi Tower Kit.

local Players = game:GetService("Players")

local DifficultiesModule = require("./Data/Difficulties")
local RealmInfo = require("./Data/RealmInfo")
local Types = require("./Types")

type Dictionary<T> = Types.Dictionary<T>
type Difficulty = Types.DifficultyInfo
type List<T> = Types.List<T>
type Realms = Types.Realms

local DIFFICULTIES = DifficultiesModule.data
local HIP_OFFSET = CFrame.new(0, 3, 0)

local DEFAULT_DIFFICULTY: Difficulty = {
	title = "unknown",
	rating = 0,
	color = Color3.new(1, 1, 1),

	fancyFont = false,
	globalAnnouncement = false,
	globalAjAnnouncement = false,
}

local Util = {}

function Util.getDifficulty(difficultyName: string): Difficulty
	local search: Difficulty? = DIFFICULTIES[difficultyName]
	return search or DEFAULT_DIFFICULTY
end

function Util.isPlayerPart(hit: BasePart): (boolean, string)
	local parent = hit.Parent
	if parent and parent:IsA("Model") and parent:FindFirstChild("Humanoid") then
		local player = Players:GetPlayerFromCharacter(parent)
		if player then
			return true, player.Name
		end
	end
	return false, ""
end

function Util.isPlayerAlive(character: Model?): boolean
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return humanoid.Health > 0
	end

	return false
end

function Util.isPointInPart(point: Vector3, part: BasePart): boolean
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

function Util.teleportPlayerToPart(player: Player, destination: BasePart): ()
	local character = player.Character or player.CharacterAdded:Wait()
	character:PivotTo(destination.CFrame * HIP_OFFSET)
end

local function padWithLeadingZero(n: number): string
	return if n < 10 then `0{n}` else tostring(n)
end

function Util.formatTimer(time: number): string
	local ms = math.floor((time % 1) * 100)
	local s = math.floor(time % 60)
	local m = math.floor(time / 60)

	return `{padWithLeadingZero(m)}:{padWithLeadingZero(s)}.{padWithLeadingZero(ms)}`
end

function Util.formatTimeSyntax(text: string): string
	local result = text:gsub("{Time:(%d+%.?%d*)}", function(num: string)
		local n = tonumber(num) or 0
		return Util.formatTimer(n)
	end)
	return result :: any
end

function Util.formatDuration(time: number): string
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

function Util.formatBoosts(boosts: Dictionary<string>): string
	local boostList: { string } = {}
	for _, boostName in pairs(boosts) do
		table.insert(boostList, boostName)
	end

	return table.concat(boostList, ", ")
end

function Util.registerTouch(part: BasePart, onRequestTouch: (playerName: string, part: BasePart) -> ()): ()
	if not part:IsA("BasePart") then
		return
	end

	local debounce: { [string]: boolean } = {}

	part.Touched:Connect(function(hit: BasePart)
		local isPlayer, playerName = Util.isPlayerPart(hit)
		if not isPlayer then
			return
		end

		local player = Players:FindFirstChild(playerName) :: Player?
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

function Util.respawnAndTeleport(player: Player, spawnPart: BasePart): ()
	player:LoadCharacterAsync()

	local character = player.Character or player.CharacterAdded:Wait()

	local forceField = character:FindFirstChildWhichIsA("ForceField")
	if forceField then
		forceField:Destroy()
	end

	Util.teleportPlayerToPart(player, spawnPart)
end

function Util.getDifficultyColors(difficultyName: string): (Color3, Color3)
	local difficulty = Util.getDifficulty(difficultyName)
	local color = difficulty.color

	return color, Color3.new(color.R * 0.35, color.G * 0.35, color.B * 0.35)
end

function Util.getRealmTowerInfo(acronym: string): Types.RealmTowerInfo?
	local realms: Realms = RealmInfo :: any
	for _, worldData in pairs(realms) do
		for _, areaData in pairs(worldData) do
			if areaData.towers and areaData.towers[acronym] then
				return areaData.towers[acronym]
			end
		end
	end

	return nil
end

function Util.find<T>(list: List<T>, predicate: (T) -> boolean): T?
	for _, value in ipairs(list) do
		if predicate(value) then
			return value
		end
	end
	return nil
end

function Util.getDifficultyByRating(rating: number): string
	for name, info in pairs(DIFFICULTIES) do
		if info.rating == rating then
			return name
		end
	end

	return ""
end

function Util.getTowerColors(acronym: string): (Color3, Color3)
	local realmTower = Util.getRealmTowerInfo(acronym)
	if realmTower then
		local difficultyName = Util.getDifficultyByRating(realmTower.rating)
		if difficultyName then
			return Util.getDifficultyColors(difficultyName)
		end
	end

	return Color3.new(1, 1, 1), Color3.new(0.35, 0.35, 0.35)
end

function Util.getFormattedDifficultyRichText(rating: number, numDifficulty: number): string
	local diffName = Util.getDifficultyByRating(rating) or "Unknown"
	local subDiff, subColor = DifficultiesModule.getSubDetails(numDifficulty)

	local difficultyInfo = Util.getDifficulty(diffName)
	local tColor = difficultyInfo.color

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

function Util.getRainbowColor(): Color3
	local speed = 0.2
	return Color3.fromHSV((os.clock() * speed) % 1, 1, 1)
end

return Util
