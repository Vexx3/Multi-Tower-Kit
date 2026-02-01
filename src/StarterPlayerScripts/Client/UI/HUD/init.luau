--[=[
	Client-side tower HUD coordinator module.
	Orchestrates UI components: tower name/acronym, rush progress, timer,
	boosts-used state, restart prompt, loading screen, and FPS overlay.

	@class HUD
	@client
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared

local Dash = require(Modules.Dash)
local Types = require(Shared.Types)
local Util = require(Shared.Util)

local LoadingScreen = require("@self/LoadingScreen")
local TowerHUD = require("@self/TowerHUD")

type TowerRush = Types.TowerRush

local TowerRushes = require(Shared.Data.TowerRushes)

local RUSH_COLOR_CURRENT = Color3.fromRGB(255, 234, 138)
local RUSH_COLOR_DONE = Color3.fromRGB(152, 255, 152)
local RUSH_COLOR_TODO = Color3.fromRGB(255, 140, 140)

local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui")

local screenGui = PlayerGui:WaitForChild("TowerGUI") :: ScreenGui
screenGui.Enabled = true

local towerRushProgressLabel = screenGui:FindFirstChild("TowerRushProgress", true) :: TextLabel?
local towerRushNameLabel = screenGui:FindFirstChild("TowerRushName", true) :: TextLabel?
local boostsUsedLabel = screenGui:FindFirstChild("BoostsUsed", true) :: TextLabel?
local trProgressListFrame = screenGui:FindFirstChild("TRProgressList", true) :: Frame?
local trProgressItemTemplate = trProgressListFrame and trProgressListFrame:FindFirstChild("TowerName") :: TextLabel?
local boostListFrame = screenGui:FindFirstChild("BoostList", true) :: Frame?
local boostListItemTemplate = boostListFrame and boostListFrame:FindFirstChild("ItemName") :: TextLabel?

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

	Dash.forEach(boostListFrame:GetChildren(), function(child: Instance)
		if child:IsA("TextLabel") and child ~= template then
			child:Destroy()
		end
	end)

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
	local list = Dash.filter(pieces, function(part)
		return part ~= ""
	end)

	currentBoostList = list
	rebuildBoostList(currentBoostList)
end

local function rebuildTowerRushList(): ()
	if not trProgressListFrame or not trProgressItemTemplate then
		return
	end
	local template = trProgressItemTemplate :: TextLabel

	Dash.forEach(trProgressListFrame:GetChildren(), function(child: Instance)
		if child:IsA("TextLabel") and child ~= template then
			child:Destroy()
		end
	end)

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

--[=[
	Shows the loading screen with the specified message.

	@param message string -- The message to display
	@param showAttention boolean? -- Whether to show the attention label
]=]
function TowerGUI.showLoadingScreen(message: string, showAttention: boolean?): ()
	LoadingScreen.show(message, showAttention)
end

--[=[
	Hides the loading screen with a fade transition.
]=]
function TowerGUI.hideLoadingScreen(): ()
	LoadingScreen.hide()
end

--[=[
	Sets the tower acronym display and caches the full tower name.

	@param acronym string -- The tower acronym to display
]=]
function TowerGUI.setTowerAcronym(acronym: string): ()
	TowerHUD.setAcronym(acronym)
end

--[=[
	Updates tower rush progress text and toggles visibility when no rush is active.

	@param progress number -- Current progress in the rush
	@param max number -- Total towers in the rush
]=]
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

--[=[
	Sets the displayed tower timer using formatted seconds.

	@param seconds number -- The time in seconds to display
]=]
function TowerGUI.setTowerTimer(seconds: number): ()
	TowerHUD.setTimer(seconds)
end

--[=[
	Shows or hides the boosts-used indicator and refreshes the boost list.

	@param value boolean -- Whether boosts were used
]=]
function TowerGUI.setBoostsUsed(value: boolean): ()
	if boostsUsedLabel then
		boostsUsedLabel.Visible = value
	end

	updateBoostList()

	if boostListFrame then
		boostListFrame.Visible = false
	end
end

--[=[
	Fades the restart label based on a normalized progress value.

	@param t number -- Progress value from 0 (hidden) to 1 (fully visible)
]=]
function TowerGUI.setRestartLabel(t: number): ()
	TowerHUD.setRestartProgress(t)
end

-- Initialize split modules
TowerHUD.Start()

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
