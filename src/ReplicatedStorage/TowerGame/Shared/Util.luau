--[[
	Utility functions used throughout the Multi Tower Kit.
]]

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
local RAINBOW_SPEED = 0.2

local DEFAULT_DIFFICULTY: Difficulty = {
	title = "unknown",
	rating = 0,
	color = Color3.new(1, 1, 1),
	fancyFont = false,
	globalAnnouncement = false,
	globalAjAnnouncement = false,
}

local Util = {}

--- Gets difficulty info by name, or returns a default if not found.
--- @param difficultyName string -- The name of the difficulty
--- @return DifficultyInfo -- The difficulty info
function Util.getDifficulty(difficultyName: string): Difficulty
	return DIFFICULTIES[difficultyName] or DEFAULT_DIFFICULTY
end

--- Gets difficulty name by its rating number.
--- @param rating number -- The difficulty rating
--- @return string -- The difficulty name, or empty string if not found
function Util.getDifficultyByRating(rating: number): string
	for name, info in DIFFICULTIES do
		if info.rating == rating then
			return name
		end
	end
	return ""
end

--- Gets primary and shadow colors for a difficulty.
--- @param difficultyName string -- The name of the difficulty
--- @return Color3 -- The primary color
--- @return Color3 -- The shadow color (35% brightness)
function Util.getDifficultyColors(difficultyName: string): (Color3, Color3)
	local difficulty = Util.getDifficulty(difficultyName)
	local color = difficulty.color
	return color, Color3.new(color.R * 0.35, color.G * 0.35, color.B * 0.35)
end

--- Formats difficulty info as rich text with colors.
--- @param rating number -- The difficulty rating
--- @param numDifficulty number -- The sub-difficulty number
--- @return string -- Formatted rich text string
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

--- Checks if a part belongs to a player's character.
--- @param hit BasePart -- The part to check
--- @return boolean -- Whether the part belongs to a player
--- @return string -- The player's name, or empty string
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

--- Checks if a character is alive (has humanoid with health > 0).
--- @param character Model? -- The character model to check
--- @return boolean -- Whether the character is alive
function Util.isPlayerAlive(character: Model?): boolean
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

--- Teleports a player to a destination part.
--- @param player Player -- The player to teleport
--- @param destination BasePart -- The part to teleport to
function Util.teleportPlayerToPart(player: Player, destination: BasePart)
	local character = player.Character or player.CharacterAdded:Wait()
	character:PivotTo(destination.CFrame * HIP_OFFSET)
end

--- Respawns a player and teleports them to a spawn part.
--- @param player Player -- The player to respawn
--- @param spawnPart BasePart -- The part to teleport to after respawning
function Util.respawnAndTeleport(player: Player, spawnPart: BasePart)
	player:LoadCharacterAsync()

	local character = player.Character or player.CharacterAdded:Wait()
	local forceField = character:FindFirstChildWhichIsA("ForceField")
	if forceField then
		forceField:Destroy()
	end

	Util.teleportPlayerToPart(player, spawnPart)
end

--- Checks if a point is inside a part's bounding box.
--- @param point Vector3 -- The world position to check
--- @param part BasePart -- The part to check against
--- @return boolean -- Whether the point is inside the part
function Util.isPointInPart(point: Vector3, part: BasePart): boolean
	local localPoint = part.CFrame:PointToObjectSpace(point)
	local unitPoint = localPoint / part.Size
	return unitPoint.X <= 0.5
		and unitPoint.X >= -0.5
		and unitPoint.Y <= 0.5
		and unitPoint.Y >= -0.5
		and unitPoint.Z <= 0.5
		and unitPoint.Z >= -0.5
end

local function padWithLeadingZero(n: number): string
	return if n < 10 then `0{n}` else tostring(n)
end

--- Formats a time value as MM:SS.MS.
--- @param time number -- The time in seconds
--- @return string -- Formatted time string
function Util.formatTimer(time: number): string
	local ms = math.floor((time % 1) * 100)
	local s = math.floor(time % 60)
	local m = math.floor(time / 60)
	return `{padWithLeadingZero(m)}:{padWithLeadingZero(s)}.{padWithLeadingZero(ms)}`
end

--- Replaces {Time:X} syntax in text with formatted time.
--- @param text string -- The text containing time syntax
--- @return string -- Text with times formatted
function Util.formatTimeSyntax(text: string): string
	local result = text:gsub("{Time:(%d+%.?%d*)}", function(num: string)
		local n = tonumber(num) or 0
		return Util.formatTimer(n)
	end)
	return result
end

--- Formats a duration as Xh Xm Xs.
--- @param time number -- The time in seconds
--- @return string -- Formatted duration string
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

--- Formats a dictionary of boosts as a comma-separated string.
--- @param boosts Dictionary<string> -- Map of boost item names to display names
--- @return string -- Comma-separated boost names
function Util.formatBoosts(boosts: Dictionary<string>): string
	local boostList: { string } = {}
	for _, boostName in boosts do
		table.insert(boostList, boostName)
	end
	return table.concat(boostList, ", ")
end

--- Registers a touch handler with player detection and debounce.
--- @param part BasePart -- The part to register touch on
--- @param onRequestTouch (playerName: string, part: BasePart) -> () -- Callback when touched
function Util.registerTouch(part: BasePart, onRequestTouch: (playerName: string, part: BasePart) -> ())
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

--- Gets tower info from RealmInfo by acronym.
--- @param acronym string -- The tower acronym to look up
--- @return RealmTowerInfo? -- The tower info, or nil if not found
function Util.getRealmTowerInfo(acronym: string): Types.RealmTowerInfo?
	local realms: Realms = RealmInfo :: any
	for _, worldData in realms do
		for _, areaData in worldData do
			if areaData.towers and areaData.towers[acronym] then
				return areaData.towers[acronym]
			end
		end
	end
	return nil
end

--- Gets primary and shadow colors for a tower by acronym.
--- @param acronym string -- The tower acronym
--- @return Color3 -- The primary color
--- @return Color3 -- The shadow color
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

--- Finds the first element in a list matching a predicate.
--- @param list List<T> -- The list to search
--- @param predicate (T) -> boolean -- The predicate function
--- @return T? -- The first matching element, or nil
function Util.find<T>(list: List<T>, predicate: (T) -> boolean): T?
	for _, value in list do
		if predicate(value) then
			return value
		end
	end
	return nil
end

--- Gets a cycling rainbow color based on current time.
--- @return Color3 -- The rainbow color
function Util.getRainbowColor(): Color3
	return Color3.fromHSV((os.clock() * RAINBOW_SPEED) % 1, 1, 1)
end

return Util
