--[=[
	Client-side tower HUD: shows tower name/acronym, rush progress, timer,
	boosts-used state, restart prompt, and a simple FPS/ping overlay.

	@class GUI
	@client
]=]

-- Important
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Icon = require(ReplicatedStorage.Packages.topbarplus)
local TowerRushes = require(ReplicatedStorage.RealmData.TowerRushes)
local Util = require(ReplicatedStorage.Shared.Util)

local LocalPlayer = Players.LocalPlayer :: Player
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Towers = workspace.Towers

local TowerGui = PlayerGui:WaitForChild("TowerGUI") :: ScreenGui
TowerGui.Enabled = true

-- Elements
local TowerAcronym = TowerGui:FindFirstChild("TowerAcronym", true) :: TextLabel?
local TowerRushProgress = TowerGui:FindFirstChild("TowerRushProgress", true) :: TextLabel?
local TowerRushName = TowerGui:FindFirstChild("TowerRushName", true) :: TextLabel?
local Timer = TowerGui:FindFirstChild("Timer", true) :: TextLabel?
local BoostsUsed = TowerGui:FindFirstChild("BoostsUsed", true) :: TextLabel?
local RestartLabel = TowerGui:FindFirstChild("RestartLabel", true) :: TextLabel?
local TRProgressList = TowerGui:FindFirstChild("TRProgressList", true) :: Frame?
local TRProgressItemTemplate = TRProgressList
	and TRProgressList:FindFirstChild("TowerName") :: TextLabel?
local BoostListFrame = TowerGui:FindFirstChild("BoostList", true) :: Frame?
local BoostListItemTemplate = BoostListFrame
	and BoostListFrame:FindFirstChild("ItemName") :: TextLabel?

local restartTransparency = 0
local restartStrokeTransparency = 1

if RestartLabel then
	restartTransparency = RestartLabel.TextTransparency
	restartStrokeTransparency = RestartLabel.TextStrokeTransparency
end

local currentAcronym = ""
local towerName = ""
local currentBoostList: { string } = {}
local currentRushList: { string } = {}
local currentRushIndex = 0
local currentRushName = ""
local currentRushDifficultyColor = Color3.new(1, 1, 1)

local RUSH_COLOR_CURRENT = Color3.fromRGB(255, 234, 138)
local RUSH_COLOR_DONE = Color3.fromRGB(152, 255, 152)
local RUSH_COLOR_TODO = Color3.fromRGB(255, 140, 140)

local function setBoostListVisible(isVisible: boolean)
	if BoostListFrame then
		BoostListFrame.Visible = isVisible
	end
end

local function setRushListVisible(isVisible: boolean)
	local hasRush = #currentRushList > 0
	if TRProgressList then
		TRProgressList.Visible = isVisible and hasRush
	end
	if TowerRushName then
		TowerRushName.Visible = isVisible and currentRushName ~= ""
	end
end

local GUI = {}

local function rebuildBoostList(list: { string })
	if not BoostListFrame or not BoostListItemTemplate then
		return
	end

	-- Clear existing clones
	for _, child in BoostListFrame:GetChildren() do
		if child:IsA("TextLabel") and child ~= BoostListItemTemplate then
			child:Destroy()
		end
	end

	BoostListItemTemplate.Visible = false

	for _, name in list do
		local clone = BoostListItemTemplate:Clone()
		clone.Name = `Item_{name}`
		clone.Text = name
		clone.Visible = true
		clone.Parent = BoostListFrame
	end
end

local function updateBoostList()
	local boostAttr = LocalPlayer:GetAttribute("BoostItemNames") :: string?
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

local function rebuildTowerRushList()
	if not TRProgressList or not TRProgressItemTemplate then
		return
	end

	for _, child in TRProgressList:GetChildren() do
		if child:IsA("TextLabel") and child ~= TRProgressItemTemplate then
			child:Destroy()
		end
	end

	TRProgressItemTemplate.Visible = false

	for index, acronym in currentRushList do
		local clone = TRProgressItemTemplate:Clone()
		clone.Name = `RushTower_{acronym}`
		clone.Text = acronym

		local textColor, strokeColor = Util:GetTowerColors(acronym)
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
		clone.Parent = TRProgressList
	end
end

local function refreshTowerRushUI()
	if TowerRushName then
		TowerRushName.Text = currentRushName
		TowerRushName.TextColor3 = currentRushDifficultyColor
		TowerRushName.TextStrokeColor3 = Color3.new(
			currentRushDifficultyColor.R * 0.35,
			currentRushDifficultyColor.G * 0.35,
			currentRushDifficultyColor.B * 0.35
		)
	end

	rebuildTowerRushList()
	setRushListVisible(false)
end

local function updateTowerRush()
	local rushIdAttr = LocalPlayer:GetAttribute("CurrentTowerRush") :: string?
	local rushId = if rushIdAttr then rushIdAttr else ""
	local rush = if rushId ~= "" then TowerRushes[rushId] else nil

	if rush then
		currentRushName = rush.Title
		local textColor = Util:GetDifficultyColors(rush.Difficulty)
		currentRushDifficultyColor = textColor

		local list = {}
		for _, name in rush.Towers do
			table.insert(list, name)
		end
		currentRushList = list
	else
		currentRushName = ""
		currentRushDifficultyColor = Color3.new(1, 1, 1)
		currentRushList = {}
	end

	local idx = LocalPlayer:GetAttribute("CurrentTowerRushIndex") :: number?
	if idx then
		currentRushIndex = idx
	end

	refreshTowerRushUI()
end

function GUI:SetTowerAcronym(acronym: string)
	if not TowerAcronym then
		return
	end

	currentAcronym = acronym
	TowerAcronym.Visible = acronym ~= ""
	TowerAcronym.Text = acronym

	local textColor, strokeColor = Util:GetTowerColors(acronym)
	TowerAcronym.TextColor3 = textColor
	TowerAcronym.TextStrokeColor3 = strokeColor

	local tower = Towers:FindFirstChild(acronym)
	if tower then
		local properName = tower:FindFirstChild("ProperName") :: StringValue?
		if properName then
			towerName = properName.Value
		end
	end
end

--[=[
	Updates tower rush progress text and toggles visibility when no rush is active.

	@within GUI
]=]
function GUI:SetTowerRush(progress: number, max: number)
	if TowerRushProgress then
		TowerRushProgress.Text = `{progress}/{max}`
		TowerRushProgress.Visible = max ~= 0

		local progressColor, progressStroke =
			currentRushDifficultyColor,
			Color3.new(
				currentRushDifficultyColor.R * 0.35,
				currentRushDifficultyColor.G * 0.35,
				currentRushDifficultyColor.B * 0.35
			)
		TowerRushProgress.TextColor3 = progressColor
		TowerRushProgress.TextStrokeColor3 = progressStroke
	end

	currentRushIndex = progress
	updateTowerRush()

	if max == 0 then
		setRushListVisible(false)
	end
end

--[=[
	Sets the displayed tower timer using formatted seconds.

	@within GUI
	@param time number
]=]
function GUI:SetTowerTimer(_time: number)
	if Timer then
		Timer.Text = Util:FormatTimer(_time)
	end
end

--[=[
	Shows or hides the boosts-used indicator.

	@within GUI
]=]
function GUI:SetBoostsUsed(value: boolean)
	if BoostsUsed then
		BoostsUsed.Visible = value
	end

	-- Refresh the hover list from the replicated attribute so late updates still show
	updateBoostList()

	if BoostListFrame then
		BoostListFrame.Visible = false
	end
end

--[=[
	Fades the restart label based on a normalized progress value.

	@within GUI
	@param t number -- 0-1 visibility factor
]=]
function GUI:SetRestartLabel(t: number)
	if RestartLabel then
		RestartLabel.Visible = t > 0
		RestartLabel.TextTransparency = 1 - (t * (1 - restartTransparency))
		RestartLabel.TextStrokeTransparency = 1 - (t * (1 - restartStrokeTransparency))
	end
end

-- performance display
local timeFunction = if RunService:IsRunning() then time else os.clock

local frameUpdateTable = {}

local start = timeFunction()
local lastIteration = start
local function getPlayerFPS()
	lastIteration = timeFunction()

	for index = #frameUpdateTable, 1, -1 do
		frameUpdateTable[index + 1] = if frameUpdateTable[index] >= lastIteration - 1
			then frameUpdateTable[index]
			else nil
	end

	frameUpdateTable[1] = lastIteration

	return math.floor(
		if timeFunction() - start >= 1
			then #frameUpdateTable
			else #frameUpdateTable / (timeFunction() - start)
	)
end

local function getPlayerPing()
	local ping = LocalPlayer:GetNetworkPing()
	return math.floor(ping * 1000)
end

local performance = Icon.new():lock():modifyTheme({
	{
		"IconLabel",
		"FontFace",
		Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium),
	},
	{ "IconLabel", "TextSize", 14 },
})

local function onHeartbeat()
	local playerFPS = getPlayerFPS()
	local playerPing = getPlayerPing()
	performance:setLabel(`FPS: {playerFPS}\nPing: {playerPing}MS`)
end

RunService.Heartbeat:Connect(onHeartbeat)

if TowerAcronym then
	TowerAcronym.MouseEnter:Connect(function()
		if currentAcronym ~= "" then
			TowerAcronym.Text = towerName
		end
	end)
	TowerAcronym.MouseLeave:Connect(function()
		TowerAcronym.Text = currentAcronym
	end)
end

if BoostsUsed and BoostListFrame then
	BoostsUsed.MouseEnter:Connect(function()
		setBoostListVisible(true)
	end)

	BoostsUsed.MouseLeave:Connect(function()
		setBoostListVisible(false)
	end)
end

if TowerRushProgress then
	TowerRushProgress.MouseEnter:Connect(function()
		setRushListVisible(true)
	end)

	TowerRushProgress.MouseLeave:Connect(function()
		setRushListVisible(false)
	end)

	if TRProgressList then
		TRProgressList.MouseEnter:Connect(function()
			setRushListVisible(true)
		end)

		TRProgressList.MouseLeave:Connect(function()
			setRushListVisible(false)
		end)
	end
end

LocalPlayer:GetAttributeChangedSignal("BoostItemNames"):Connect(updateBoostList)
LocalPlayer:GetAttributeChangedSignal("CurrentTowerRush"):Connect(updateTowerRush)
LocalPlayer:GetAttributeChangedSignal("CurrentTowerRushIndex"):Connect(updateTowerRush)

return GUI
