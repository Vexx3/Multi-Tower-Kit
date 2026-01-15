-- Client-side tower HUD: shows tower name/acronym, rush progress, timer,
-- boosts-used state, restart prompt, and a simple FPS/ping overlay.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Packages = ReplicatedStorage.Packages

local GUIHandler = require(Shared.GUIHandler)
local Icon = require(Packages.topbarplus)
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type TowerRush = Types.TowerRush

local TowerRushes = require(Shared.Data.TowerRushes)

local RUSH_COLOR_CURRENT = Color3.fromRGB(255, 234, 138)
local RUSH_COLOR_DONE = Color3.fromRGB(152, 255, 152)
local RUSH_COLOR_TODO = Color3.fromRGB(255, 140, 140)

local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui")

local screenGui = PlayerGui:WaitForChild("TowerGUI") :: ScreenGui
screenGui.Enabled = true

local towerAcronymLabel = screenGui:FindFirstChild("TowerAcronym", true) :: TextLabel?
local towerRushProgressLabel = screenGui:FindFirstChild("TowerRushProgress", true) :: TextLabel?
local towerRushNameLabel = screenGui:FindFirstChild("TowerRushName", true) :: TextLabel?
local timerLabel = screenGui:FindFirstChild("Timer", true) :: TextLabel?
local boostsUsedLabel = screenGui:FindFirstChild("BoostsUsed", true) :: TextLabel?
local restartLabelElement = screenGui:FindFirstChild("RestartLabel", true) :: TextLabel?
local trProgressListFrame = screenGui:FindFirstChild("TRProgressList", true) :: Frame?
local trProgressItemTemplate = trProgressListFrame and trProgressListFrame:FindFirstChild("TowerName") :: TextLabel?
local boostListFrame = screenGui:FindFirstChild("BoostList", true) :: Frame?
local boostListItemTemplate = boostListFrame and boostListFrame:FindFirstChild("ItemName") :: TextLabel?

-- Loading Screen Elements
local loadingScreenGroup = screenGui:FindFirstChild("LoadingScreen", true) :: CanvasGroup?
local loadingLabelElement = loadingScreenGroup and loadingScreenGroup:FindFirstChild("LoadingLabel") :: TextLabel?
local attentionLabelElement = loadingScreenGroup and loadingScreenGroup:FindFirstChild("Attention") :: TextLabel?

local restartTransparency = 0
local restartStrokeTransparency = 1

if restartLabelElement then
	restartTransparency = restartLabelElement.TextTransparency
	restartStrokeTransparency = restartLabelElement.TextStrokeTransparency
end

local currentAcronym = ""
local currentTowerName = ""
local currentBoostList: { string } = {}
local currentRushList: { string } = {}
local currentRushIndex = 0
local currentRushName = ""
local currentRushDifficultyColor = Color3.new(1, 1, 1)

local TowerGUI = {}

local function setBoostListVisible(isVisible: boolean): ()
	if boostListFrame then
		boostListFrame.Visible = isVisible
	end
end

local function setRushListVisible(isVisible: boolean): ()
	local hasRush = #currentRushList > 0
	if trProgressListFrame then
		trProgressListFrame.Visible = isVisible and hasRush
	end
	if towerRushNameLabel then
		towerRushNameLabel.Visible = isVisible and currentRushName ~= ""
	end
end

local function rebuildBoostList(list: { string }): ()
	if not boostListFrame or not boostListItemTemplate then
		return
	end
	local template = boostListItemTemplate :: TextLabel

	for _, child in boostListFrame:GetChildren() do
		if child:IsA("TextLabel") and child ~= template then
			child:Destroy()
		end
	end

	template.Visible = false

	for _, name in list do
		local clone = template:Clone()
		clone.Name = `Item_{name}`
		clone.Text = name
		clone.Visible = true
		clone.Parent = boostListFrame
	end
end

local function updateBoostList(): ()
	local boostAttr = Player:GetAttribute("BoostItemNames") :: string?
	local boostNames = if boostAttr then boostAttr else ""
	local pieces = string.split(boostNames, ",")
	local list = {}

	for _, part in pieces do
		if part ~= "" then
			table.insert(list, part)
		end
	end

	currentBoostList = list
	rebuildBoostList(currentBoostList)
end

local function rebuildTowerRushList(): ()
	if not trProgressListFrame or not trProgressItemTemplate then
		return
	end
	local template = trProgressItemTemplate :: TextLabel

	for _, child in trProgressListFrame:GetChildren() do
		if child:IsA("TextLabel") and child ~= template then
			child:Destroy()
		end
	end

	template.Visible = false

	for index, acronym in currentRushList do
		local clone = template:Clone()
		clone.Name = `RushTower_{acronym}`
		clone.Text = acronym

		local textColor, strokeColor = Util.getTowerColors(acronym)
		clone.TextColor3 = textColor
		clone.TextStrokeColor3 = strokeColor

		if index < currentRushIndex then
			clone.BackgroundColor3 = RUSH_COLOR_DONE
		elseif index == currentRushIndex then
			clone.BackgroundColor3 = RUSH_COLOR_CURRENT
		else
			clone.BackgroundColor3 = RUSH_COLOR_TODO
		end

		clone.Visible = true
		clone.Parent = trProgressListFrame
	end
end

local function refreshTowerRushUI(): ()
	if towerRushNameLabel then
		towerRushNameLabel.Text = currentRushName
		towerRushNameLabel.TextColor3 = currentRushDifficultyColor
		towerRushNameLabel.TextStrokeColor3 = Color3.new(
			currentRushDifficultyColor.R * 0.35,
			currentRushDifficultyColor.G * 0.35,
			currentRushDifficultyColor.B * 0.35
		)
	end

	rebuildTowerRushList()
	setRushListVisible(false)
end

local function updateTowerRush(): ()
	local rushIdAttr = Player:GetAttribute("CurrentTowerRush") :: string?
	local rushId = if rushIdAttr then rushIdAttr else ""
	local rush: TowerRush? = if rushId ~= "" then TowerRushes[rushId] else nil

	if rush then
		local realmInfo = Util.getRealmTowerInfo(rushId)
		currentRushName = if realmInfo then realmInfo.name else rushId

		local diff = ""
		if realmInfo then
			diff = Util.getDifficultyByRating(realmInfo.rating)
		end

		local textColor = Util.getDifficultyColors(diff)
		currentRushDifficultyColor = textColor

		local list: { string } = {}
		for _, name in rush.towers do
			table.insert(list, name)
		end
		currentRushList = list
	else
		currentRushName = ""
		currentRushDifficultyColor = Color3.new(1, 1, 1)
		currentRushList = {}
	end

	local idx = Player:GetAttribute("CurrentTowerRushIndex") :: number?
	if idx then
		currentRushIndex = idx
	end

	refreshTowerRushUI()
end

local timeFunction = if RunService:IsRunning() then time else os.clock
local frameUpdateTable: { number } = {}
local start = timeFunction()
local lastIteration = start

local performance = Icon.new():lock():modifyTheme({
	{
		"IconLabel",
		"FontFace",
		Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium),
	},
	{ "IconLabel", "TextSize", 14 },
} :: any)

-- Calculates the current FPS based on frame timing.
local function getPlayerFPS(): number
	lastIteration = timeFunction()

	for index = #frameUpdateTable, 1, -1 do
		frameUpdateTable[index + 1] = if frameUpdateTable[index] >= lastIteration - 1
			then frameUpdateTable[index]
			else nil
	end

	frameUpdateTable[1] = lastIteration

	return math.floor(
		if timeFunction() - start >= 1 then #frameUpdateTable else #frameUpdateTable / (timeFunction() - start)
	)
end

-- Updates the FPS display on each heartbeat.
local function onHeartbeat(): ()
	local playerFPS = getPlayerFPS()
	performance:setLabel(`FPS: {playerFPS}`)
end

-- Shows the loading screen with the specified message.
function TowerGUI.showLoadingScreen(message: string, showAttention: boolean?): ()
	if loadingLabelElement then
		loadingLabelElement.Text = message
	end
	if attentionLabelElement then
		attentionLabelElement.Visible = showAttention or false
	end
	if loadingScreenGroup then
		loadingScreenGroup.Visible = true
		GUIHandler.toggleUI(loadingScreenGroup, true, 1)
	end
end

-- Hides the loading screen.
function TowerGUI.hideLoadingScreen(): ()
	if loadingScreenGroup then
		GUIHandler.toggleUI(loadingScreenGroup, false, 1, function()
			if attentionLabelElement then
				attentionLabelElement.Visible = false
			end
		end)
	end
end

-- Sets the tower acronym display and caches the full tower name.
function TowerGUI.setTowerAcronym(acronym: string): ()
	if not towerAcronymLabel then
		return
	end

	currentAcronym = acronym
	towerAcronymLabel.Visible = acronym ~= ""
	towerAcronymLabel.Text = acronym

	local textColor, strokeColor = Util.getTowerColors(acronym)
	towerAcronymLabel.TextColor3 = textColor
	towerAcronymLabel.TextStrokeColor3 = strokeColor

	currentTowerName = acronym

	local realmTower = Util.getRealmTowerInfo(acronym)
	if realmTower and realmTower.name then
		currentTowerName = realmTower.name
	end
end

-- Updates tower rush progress text and toggles visibility when no rush is active.
function TowerGUI.setTowerRush(progress: number, max: number): ()
	if towerRushProgressLabel then
		towerRushProgressLabel.Text = `{progress}/{max}`
		towerRushProgressLabel.Visible = max ~= 0

		local progressColor = currentRushDifficultyColor
		local progressStroke = Color3.new(
			currentRushDifficultyColor.R * 0.35,
			currentRushDifficultyColor.G * 0.35,
			currentRushDifficultyColor.B * 0.35
		)
		towerRushProgressLabel.TextColor3 = progressColor
		towerRushProgressLabel.TextStrokeColor3 = progressStroke
	end

	currentRushIndex = progress
	updateTowerRush()

	if max == 0 then
		setRushListVisible(false)
	end
end

-- Sets the displayed tower timer using formatted seconds.
function TowerGUI.setTowerTimer(seconds: number): ()
	if timerLabel then
		timerLabel.Text = Util.formatTimer(seconds)
	end
end

-- Shows or hides the boosts-used indicator and refreshes the boost list.
function TowerGUI.setBoostsUsed(value: boolean): ()
	if boostsUsedLabel then
		boostsUsedLabel.Visible = value
	end

	updateBoostList()

	if boostListFrame then
		boostListFrame.Visible = false
	end
end

-- Fades the restart label based on a normalized progress value (0-1).
function TowerGUI.setRestartLabel(t: number): ()
	if restartLabelElement then
		restartLabelElement.Visible = t > 0
		restartLabelElement.TextTransparency = 1 - (t * (1 - restartTransparency))
		restartLabelElement.TextStrokeTransparency = 1 - (t * (1 - restartStrokeTransparency))
	end
end

RunService.Heartbeat:Connect(onHeartbeat)

if towerAcronymLabel then
	towerAcronymLabel.MouseEnter:Connect(function()
		if currentAcronym ~= "" then
			towerAcronymLabel.Text = currentTowerName
		end
	end)
	towerAcronymLabel.MouseLeave:Connect(function()
		towerAcronymLabel.Text = currentAcronym
	end)
end

if boostsUsedLabel and boostListFrame then
	boostsUsedLabel.MouseEnter:Connect(function()
		setBoostListVisible(true)
	end)

	boostsUsedLabel.MouseLeave:Connect(function()
		setBoostListVisible(false)
	end)
end

if towerRushProgressLabel then
	towerRushProgressLabel.MouseEnter:Connect(function()
		setRushListVisible(true)
	end)

	towerRushProgressLabel.MouseLeave:Connect(function()
		setRushListVisible(false)
	end)

	if trProgressListFrame then
		trProgressListFrame.MouseEnter:Connect(function()
			setRushListVisible(true)
		end)

		trProgressListFrame.MouseLeave:Connect(function()
			setRushListVisible(false)
		end)
	end
end

Player:GetAttributeChangedSignal("BoostItemNames"):Connect(updateBoostList)
Player:GetAttributeChangedSignal("CurrentTowerRush"):Connect(updateTowerRush)
Player:GetAttributeChangedSignal("CurrentTowerRushIndex"):Connect(updateTowerRush)

return TowerGUI
