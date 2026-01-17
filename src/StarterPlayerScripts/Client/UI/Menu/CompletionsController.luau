--!nocheck

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

type TowerData = {
	name: string,
	badgeId: number,
	rating: number,
	numDifficulty: number,
	rush: boolean?,
}

type TowerEntry = {
	acronym: string,
	data: TowerData,
}

type DifficultySortedEntry = {
	acronym: string,
	data: TowerData,
	areaEmblem: string,
}

type Stats = {
	attempts: number,
	wins: number,
	bestWinTimeFormatted: string,
	bestAJWinTimeFormatted: string,
	totalTimeSpentFormatted: string,
	allJumpsWins: number,
}

type TowerButton = GuiButton & {
	TowerName: TextLabel,
	Emblem: ImageLabel,
}

type PlaceList = Frame & {
	TowerTemplate: TowerButton,
}

type PlaceProgressBar = Frame & {
	Fill: Frame,
	ProgressLabel: TextLabel,
}

type PlaceInfo = Frame & {
	PlaceName: TextLabel,
	Icon: ImageLabel,
	Icon2: ImageLabel,
}

type CategoryFrame = Frame & {
	List: Frame,
	PlaceInfo: PlaceInfo,
	PlaceProgressBar: PlaceProgressBar,
}

type DetailsFrameType = Frame & {
	NameLabel: TextLabel,
	AttemptsLabel: TextLabel,
	WinsLabel: TextLabel,
	BestAJWinLabel: TextLabel,
	BestWinLabel: TextLabel,
	TimeSpentLabel: TextLabel,
	AJLabel: TextLabel,
	DifficultyLabel: TextLabel,
	CloseFrame: Frame & { Close: GuiButton },
}

type SettingsFrameType = Frame & {
	AreaButton: GuiButton,
	DifficultyButton: GuiButton,
	UsernameBox: TextBox,
	PlayerImage: ImageLabel,
	SaveButton: GuiButton,
	CancelButton: GuiButton,
}

type NotificationFrameType = Frame & {
	InfoLabel: TextLabel,
	CloseButton: GuiButton,
}

type MenuFrameType = Frame & {
	DetailsFrame: DetailsFrameType,
	DifficultyHover: TextLabel,
	PlacesContainer: Frame & { PlaceTemplate: CategoryFrame },
	CompletionSettings: SettingsFrameType,
	NotificationFrame: NotificationFrameType,
	SettingsButton: GuiButton,
	TotalProgressBar: PlaceProgressBar,
	PlayerName: TextLabel,
	PlayerAvatar: ImageLabel,
	PlayerHardest: TextLabel,
}

export type PlayerDataCache = {
	completedTowers: { string },
	completedTowerRushes: { string },
	towerStats: { [string]: Stats },
	towerRushStats: { [string]: Stats },
	[string]: any,
}

type HardestTower = {
	rating: number,
	numDiff: number,
	acronym: string?,
}

type SortMode = "Areas" | "Difficulties"

local Packages = ReplicatedStorage.Packages
local TowerGame = ReplicatedStorage.TowerGame

local BlinkClient = require(TowerGame.Network.BlinkClient)
local Janitor = require(Packages.Janitor)
local RealmInfo = require(TowerGame.Shared.Data.RealmInfo)
local Util = require(TowerGame.Shared.Util)

local CompletionsController = {}

local Player = Players.LocalPlayer

local Menu: MenuFrameType?
local SettingsFrame: SettingsFrameType?
local DetailsFrame: DetailsFrameType?
local HoverTooltip: TextLabel?
local PlacesContainer: Frame?
local PlaceTemplate: CategoryFrame?
local NotificationFrame: NotificationFrameType?
local InfoLabel: TextLabel?
local NotifyClose: GuiButton?

local activeRushButtons: { [GuiObject]: boolean } = {}
local currentSortMode: SortMode = "Areas"
local cachedData: PlayerDataCache? = nil
local tooltipJanitor = Janitor.new()

local ACTIVE_COLOR = Color3.fromRGB(166, 227, 161)
local COMPLETED_COLOR = Color3.fromRGB(115, 156, 111)
local DEFAULT_FILL_COLOR = Color3.fromRGB(166, 227, 161)

local defaultStrokeColors = {
	Area = Color3.new(1, 1, 1),
	Difficulty = Color3.new(1, 1, 1),
}

local viewingUserId = Player.UserId
local viewingUserName = Player.Name

local function getUserIdFromUsername(username: string): number?
	local success, userId = pcall(Players.GetUserIdFromNameAsync, Players, username)
	return if success then userId else nil
end

local function showNotification(message: string, canClose: boolean)
	InfoLabel.Text = message
	NotifyClose.Visible = canClose
	NotificationFrame.Visible = true
end

local function updateTooltipPosition()
	local mouseLocation = UserInputService:GetMouseLocation()
	local inset = GuiService:GetGuiInset()
	local menuPosition: Vector2 = Menu.AbsolutePosition

	HoverTooltip.Position =
		UDim2.fromOffset(mouseLocation.X - menuPosition.X, mouseLocation.Y - inset.Y - menuPosition.Y)
end

local function showTowerTooltip(button: TowerButton, towerData: TowerData)
	button.TowerName.Text = towerData.name
	HoverTooltip.RichText = true
	HoverTooltip.Text = Util.getFormattedDifficultyRichText(towerData.rating, towerData.numDifficulty)
	HoverTooltip.Visible = true
	HoverTooltip:SetAttribute("isRush", towerData.rush or false)

	tooltipJanitor:Cleanup()
	tooltipJanitor:Add(RunService.RenderStepped:Connect(updateTooltipPosition))
end

local function hideTowerTooltip(button: TowerButton, acronym: string)
	button.TowerName.Text = acronym
	HoverTooltip.Visible = false
	tooltipJanitor:Cleanup()
end

local function updateSortVisuals()
	if not SettingsFrame then
		return
	end

	local areaStroke = SettingsFrame.AreaButton:FindFirstChildOfClass("UIStroke")
	local diffStroke = SettingsFrame.DifficultyButton:FindFirstChildOfClass("UIStroke")

	if areaStroke then
		areaStroke.Color = if currentSortMode == "Areas" then ACTIVE_COLOR else defaultStrokeColors.Area
	end
	if diffStroke then
		diffStroke.Color = if currentSortMode == "Difficulties" then ACTIVE_COLOR else defaultStrokeColors.Difficulty
	end
end

local function showTowerDetails(acronym: string, towerData: TowerData)
	if not cachedData or not DetailsFrame then
		return
	end

	local statCategory = if towerData.rush then cachedData.towerRushStats else cachedData.towerStats
	local stats: Stats = (statCategory and statCategory[acronym])
		or {
			attempts = 0,
			wins = 0,
			bestWinTimeFormatted = "N/A",
			bestAJWinTimeFormatted = "N/A",
			totalTimeSpentFormatted = "0s",
			allJumpsWins = 0,
		}

	local towerColor, towerStroke = Util.getTowerColors(acronym)

	DetailsFrame:SetAttribute("isRush", towerData.rush or false)

	DetailsFrame.NameLabel.Text = towerData.name
	DetailsFrame.NameLabel.TextColor3 = towerColor
	DetailsFrame.NameLabel.TextStrokeColor3 = towerStroke

	DetailsFrame.AttemptsLabel.Text = `Attempts: {stats.attempts}`
	DetailsFrame.WinsLabel.Text = `Legit Wins: {stats.wins}`
	DetailsFrame.BestAJWinLabel.Text = `Best All Jumps Win Time (Itemless): {stats.bestAJWinTimeFormatted}`
	DetailsFrame.BestWinLabel.Text = `Best Legit Win Time (Itemless): {stats.bestWinTimeFormatted}`
	DetailsFrame.TimeSpentLabel.Text = `Total Time Spent: {stats.totalTimeSpentFormatted}`
	DetailsFrame.AJLabel.Text = `All Jumps Wins: {stats.allJumpsWins}`

	DetailsFrame.DifficultyLabel.RichText = true
	DetailsFrame.DifficultyLabel.Text = Util.getFormattedDifficultyRichText(towerData.rating, towerData.numDifficulty)

	DetailsFrame.Visible = true
end

local function createTowerButton(acronym: string, towerData: TowerData, areaEmblem: string, hasEmblem: boolean)
	local data = cachedData :: PlayerDataCache
	if not PlaceTemplate then
		return nil, false
	end
	local list = PlaceTemplate.List
	local template = list and list.TowerTemplate
	if not template then
		return nil, false
	end

	local button = template:Clone() :: TowerButton
	local towerColor, towerStroke = Util.getTowerColors(acronym)

	button.TowerName.Text = acronym
	button.TowerName.TextColor3 = towerColor
	button.TowerName.TextStrokeColor3 = towerStroke

	button.Emblem.Visible = hasEmblem
	if hasEmblem then
		button.Emblem.Image = areaEmblem
		button.Emblem.ImageColor3 = towerColor
	end

	if towerData.rush then
		activeRushButtons[button] = true
	end

	local completionList = if towerData.rush then data.completedTowerRushes else data.completedTowers
	local isCompleted = table.find(completionList, acronym) ~= nil
	if isCompleted then
		button.BackgroundColor3 = COMPLETED_COLOR
	end

	button.MouseEnter:Connect(function()
		showTowerTooltip(button, towerData)
	end)
	button.MouseLeave:Connect(function()
		hideTowerTooltip(button, acronym)
	end)
	button.MouseButton1Click:Connect(function()
		showTowerDetails(acronym, towerData)
	end)

	button.Visible = true
	return button, isCompleted
end

local function createCategoryFrame(name: string, icon: string, hasIcon: boolean): CategoryFrame
	local frame = PlaceTemplate:Clone() :: CategoryFrame
	frame.Name = name
	frame.PlaceInfo.PlaceName.Text = name

	frame.PlaceInfo.Icon.Visible = hasIcon
	frame.PlaceInfo.Icon2.Visible = hasIcon
	if hasIcon then
		frame.PlaceInfo.Icon.Image = icon
		frame.PlaceInfo.Icon2.Image = icon
	end

	return frame
end

local function updateHardestCheck(hardest: HardestTower, rating: number, numDiff: number, acronym: string): HardestTower
	local isNewHardest = rating > hardest.rating or (rating == hardest.rating and numDiff > hardest.numDiff)
	if isNewHardest then
		return { rating = rating, numDiff = numDiff, acronym = acronym }
	end
	return hardest
end

local function formatProgress(completed: number, total: number)
	local ratio = if total > 0 then math.clamp(completed / total, 0, 1) else 0
	local percentage = ratio * 100
	local formattedPercent = if percentage % 1 == 0
		then string.format("%d", percentage)
		else string.format("%.1f", percentage)

	return `{completed}/{total} ({formattedPercent}%)`, ratio
end

local function loadPlayerCompletions(username: string)
	if username == "" or username == " " then
		username = Player.Name
	end

	showNotification("Loading completions data...", false)

	task.spawn(function()
		local targetId = getUserIdFromUsername(username)
		if not targetId then
			showNotification(`Player "{username}" does not exist`, true)
			return
		end

		local data = BlinkClient.GetPlayerData.Invoke(targetId)
		if not data then
			showNotification(`No completions data found for {username}`, true)
			return
		end

		viewingUserId = targetId
		viewingUserName = username
		cachedData = data
		CompletionsController.refresh()

		if Menu then
			Menu.PlayerName.Text = `{username}'s Completions`
			Menu.PlayerAvatar.Image = `rbxthumb://type=AvatarHeadShot&id={targetId}&w=150&h=150`
		end
		if NotificationFrame then
			NotificationFrame.Visible = false
		end
	end)
end

local function buildAreaEntries(areaData: any): { TowerEntry }
	local entries: { TowerEntry } = {}
	for acronym, towerData: TowerData in pairs(areaData.towers :: { [string]: TowerData }) do
		local entry: TowerEntry = {
			acronym = acronym,
			data = towerData,
		}
		table.insert(entries, entry)
	end

	table.sort(entries, function(a: TowerEntry, b: TowerEntry)
		local aRush = a.data.rush or false
		local bRush = b.data.rush or false
		if aRush ~= bRush then
			return bRush
		end
		if a.data.rating ~= b.data.rating then
			return a.data.rating < b.data.rating
		end
		return a.data.numDifficulty < b.data.numDifficulty
	end)

	return entries
end

local function renderAreaFrame(
	areaName: string,
	areaData: any,
	entries: { TowerEntry },
	hardestTower: HardestTower
): (number, number, number, number, HardestTower)
	local hasEmblem = areaData.emblem and areaData.emblem ~= "rbxassetid://0"
	local areaFrame = createCategoryFrame(areaName, areaData.emblem, hasEmblem)

	local areaCompletedCount = 0
	local areaTotalCount = 0
	local addedGlobalCount = 0
	local addedCompletedCount = 0
	local updatedHardest = hardestTower

	for _, towerEntry in entries do
		local towerButton, isCompleted =
			createTowerButton(towerEntry.acronym, towerEntry.data, areaData.emblem, hasEmblem)
		if not towerButton then
			continue
		end

		if not towerEntry.data.rush then
			areaTotalCount += 1
			addedGlobalCount += 1
			if isCompleted then
				areaCompletedCount += 1
				addedCompletedCount += 1
				updatedHardest = updateHardestCheck(
					updatedHardest,
					towerEntry.data.rating,
					towerEntry.data.numDifficulty,
					towerEntry.acronym
				)
			end
		end

		towerButton.Parent = areaFrame.List
	end

	local progressText, ratio = formatProgress(areaCompletedCount, areaTotalCount)
	local progressBar = areaFrame.PlaceProgressBar
	progressBar.Fill.Size = UDim2.fromScale(ratio, 1)
	progressBar.ProgressLabel.Text = progressText
	progressBar.Fill:SetAttribute("Is100Percent", ratio >= 1)

	areaFrame.Visible = true
	areaFrame.Parent = PlacesContainer

	return areaCompletedCount, areaTotalCount, addedGlobalCount, addedCompletedCount, updatedHardest
end

local function buildTowersByDifficulty(): ({ [number]: { DifficultySortedEntry } }, { number })
	local towersByDiff: { [number]: { DifficultySortedEntry } } = {}

	for _, worldData in pairs(RealmInfo :: { [string]: any }) do
		for _, areaData in pairs(worldData) do
			for acronym, towerData in pairs(areaData.towers :: { [string]: TowerData }) do
				if towerData.rush then
					continue
				end

				local rating = towerData.rating or 0
				if not towersByDiff[rating] then
					towersByDiff[rating] = {}
				end

				local entry: DifficultySortedEntry = {
					acronym = acronym,
					data = towerData,
					areaEmblem = areaData.emblem,
				}
				table.insert(towersByDiff[rating], entry)
			end
		end
	end

	local sortedRatings = {}
	for rating in pairs(towersByDiff) do
		table.insert(sortedRatings, rating)
	end
	table.sort(sortedRatings)

	return towersByDiff, sortedRatings
end

local function renderDifficultyFrame(
	rating: number,
	towers: { DifficultySortedEntry },
	hardestTower: HardestTower
): (number, number, HardestTower)
	local diffName = Util.getDifficultyByRating(rating)
	local diffInfo = Util.getDifficulty(diffName)

	local hasImage = diffInfo and diffInfo.difficultyImage ~= ""
	local areaFrame = createCategoryFrame(diffName, diffInfo and diffInfo.difficultyImage or "", hasImage)

	local color, stroke = Util.getDifficultyColors(diffName)
	areaFrame.PlaceInfo.PlaceName.TextColor3 = color
	areaFrame.PlaceInfo.PlaceName.TextStrokeColor3 = stroke

	table.sort(towers, function(a: DifficultySortedEntry, b: DifficultySortedEntry)
		if a.data.numDifficulty ~= b.data.numDifficulty then
			return a.data.numDifficulty < b.data.numDifficulty
		end
		return a.acronym < b.acronym
	end)

	local completedInDiff = 0
	local addedGlobalCount = 0
	local addedCompletedCount = 0
	local updatedHardest = hardestTower

	for _, towerEntry in towers do
		addedGlobalCount += 1
		local towerButton, isCompleted =
			createTowerButton(towerEntry.acronym, towerEntry.data, towerEntry.areaEmblem, true)
		if not towerButton then
			continue
		end

		if isCompleted then
			completedInDiff += 1
			addedCompletedCount += 1
			updatedHardest = updateHardestCheck(
				updatedHardest,
				towerEntry.data.rating,
				towerEntry.data.numDifficulty,
				towerEntry.acronym
			)
		end

		towerButton.Parent = areaFrame.List
	end

	local progressText, ratio = formatProgress(completedInDiff, #towers)
	local progressBar = areaFrame.PlaceProgressBar
	progressBar.Fill.Size = UDim2.fromScale(ratio, 1)
	progressBar.ProgressLabel.Text = progressText
	progressBar.Fill:SetAttribute("Is100Percent", ratio >= 1)

	areaFrame.Visible = true
	areaFrame.Parent = PlacesContainer

	return addedGlobalCount, addedCompletedCount, updatedHardest
end

function CompletionsController.refresh()
	if not cachedData or not Menu or not PlacesContainer then
		return
	end

	activeRushButtons = {}
	for _, child in PlacesContainer:GetChildren() do
		if child:IsA("Frame") and child.Name ~= "PlaceTemplate" then
			child:Destroy()
		end
	end

	local globalTowersCount = 0
	local globalCompletedCount = 0
	local hardestTowerFound: HardestTower = { rating = -1, numDiff = -1, acronym = nil }

	if currentSortMode == "Areas" then
		for _, worldData in pairs(RealmInfo :: { [string]: any }) do
			for areaName, areaData in pairs(worldData) do
				local entries = buildAreaEntries(areaData)
				local _, _, addedGlobal, addedCompleted, updatedHardest =
					renderAreaFrame(areaName, areaData, entries, hardestTowerFound)

				globalTowersCount += addedGlobal
				globalCompletedCount += addedCompleted
				hardestTowerFound = updatedHardest
			end
		end
	else
		local towersByDiff, sortedRatings = buildTowersByDifficulty()
		for _, rating in sortedRatings do
			local towers = towersByDiff[rating]
			local addedGlobal, addedCompleted, updatedHardest = renderDifficultyFrame(rating, towers, hardestTowerFound)

			globalTowersCount += addedGlobal
			globalCompletedCount += addedCompleted
			hardestTowerFound = updatedHardest
		end
	end

	local progressText, ratio = formatProgress(globalCompletedCount, globalTowersCount)
	Menu.TotalProgressBar.Fill.Size = UDim2.fromScale(ratio, 1)
	Menu.TotalProgressBar.ProgressLabel.Text = progressText
	Menu.TotalProgressBar.Fill:SetAttribute("Is100Percent", ratio >= 1)

	Menu.PlayerName.Text = `{viewingUserName}'s Completions`
	Menu.PlayerAvatar.Image = `rbxthumb://type=AvatarHeadShot&id={viewingUserId}&w=150&h=150`

	if hardestTowerFound.acronym then
		local hardestColor = Util.getTowerColors(hardestTowerFound.acronym)
		Menu.PlayerHardest.Text = hardestTowerFound.acronym
		Menu.PlayerHardest.TextColor3 = hardestColor
	end
end

local function updateRainbowEffects()
	local rainbowColor = Util.getRainbowColor()
	local strokeColor = Color3.new(rainbowColor.R * 0.3, rainbowColor.G * 0.3, rainbowColor.B * 0.3)

	for button in pairs(activeRushButtons) do
		if button and button.Parent then
			local towerName = button:FindFirstChild("TowerName") :: TextLabel
			if towerName then
				towerName.TextColor3 = rainbowColor
				towerName.TextStrokeColor3 = strokeColor
			end

			local emblem = button:FindFirstChild("Emblem") :: ImageLabel
			if emblem then
				emblem.ImageColor3 = rainbowColor
			end
		else
			activeRushButtons[button] = nil
		end
	end

	for _, frame in PlacesContainer:GetChildren() do
		if frame:IsA("Frame") and frame:FindFirstChild("PlaceProgressBar") then
			local progressBar = (frame :: any).PlaceProgressBar :: PlaceProgressBar
			progressBar.Fill.BackgroundColor3 = if progressBar.Fill:GetAttribute("Is100Percent")
				then rainbowColor
				else DEFAULT_FILL_COLOR
		end
	end

	if Menu then
		local totalFill = Menu.TotalProgressBar.Fill
		if totalFill:GetAttribute("Is100Percent") then
			totalFill.BackgroundColor3 = rainbowColor
		else
			totalFill.BackgroundColor3 = DEFAULT_FILL_COLOR
		end
	end

	if HoverTooltip.Visible and HoverTooltip:GetAttribute("isRush") then
		HoverTooltip.TextColor3 = rainbowColor
	end

	if DetailsFrame and DetailsFrame.Visible and DetailsFrame:GetAttribute("isRush") then
		DetailsFrame.NameLabel.TextColor3 = rainbowColor
		DetailsFrame.NameLabel.TextStrokeColor3 = strokeColor
	end
end

function CompletionsController.update(data: PlayerDataCache)
	if viewingUserId == Player.UserId then
		cachedData = data
		CompletionsController.refresh()
	end
end

function CompletionsController.setup(menuFrame: Frame)
	Menu = menuFrame :: MenuFrameType
	DetailsFrame = Menu.DetailsFrame
	HoverTooltip = Menu.DifficultyHover
	PlacesContainer = Menu.PlacesContainer
	PlaceTemplate = Menu.PlacesContainer.PlaceTemplate

	SettingsFrame = Menu.CompletionSettings
	NotificationFrame = Menu.NotificationFrame
	InfoLabel = NotificationFrame.InfoLabel
	NotifyClose = NotificationFrame.CloseButton

	local areaStroke = SettingsFrame.AreaButton:FindFirstChildOfClass("UIStroke")
	local diffStroke = SettingsFrame.DifficultyButton:FindFirstChildOfClass("UIStroke")
	if areaStroke then
		defaultStrokeColors.Area = areaStroke.Color
	end
	if diffStroke then
		defaultStrokeColors.Difficulty = diffStroke.Color
	end

	SettingsFrame.AreaButton.MouseButton1Click:Connect(function()
		currentSortMode = "Areas"
		updateSortVisuals()
		CompletionsController.refresh()
	end)

	SettingsFrame.DifficultyButton.MouseButton1Click:Connect(function()
		currentSortMode = "Difficulties"
		updateSortVisuals()
		CompletionsController.refresh()
	end)

	SettingsFrame.UsernameBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = SettingsFrame.UsernameBox.Text
		if text ~= "" then
			task.spawn(function()
				local id = getUserIdFromUsername(text)
				if id then
					SettingsFrame.PlayerImage.Image = `rbxthumb://type=AvatarHeadShot&id={id}&w=150&h=150`
				end
			end)
		end
	end)

	SettingsFrame.SaveButton.MouseButton1Click:Connect(function()
		local targetUser = SettingsFrame.UsernameBox.Text
		SettingsFrame.Visible = false

		local targetId = getUserIdFromUsername(targetUser) or Player.UserId
		if targetId == viewingUserId then
			CompletionsController.refresh()
		else
			loadPlayerCompletions(targetUser)
		end
	end)

	Menu.SettingsButton.MouseButton1Click:Connect(function()
		SettingsFrame.Visible = true
	end)

	SettingsFrame.CancelButton.MouseButton1Click:Connect(function()
		SettingsFrame.Visible = false
	end)

	NotifyClose.MouseButton1Click:Connect(function()
		NotificationFrame.Visible = false
	end)

	DetailsFrame.CloseFrame.Close.MouseButton1Click:Connect(function()
		DetailsFrame.Visible = false
	end)

	PlaceTemplate.Visible = false
	PlaceTemplate.List.TowerTemplate.Visible = false

	RunService.Heartbeat:Connect(updateRainbowEffects)
	updateSortVisuals()
end

return CompletionsController
