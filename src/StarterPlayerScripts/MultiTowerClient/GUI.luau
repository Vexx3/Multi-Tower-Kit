--!strict
-- Written by fanofpixels

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
local TweenService = game:GetService("TweenService")

local Icon = require(ReplicatedStorage.Packages.TopbarPlus.Icon)
local Util = require(ReplicatedStorage.Shared.Util)

local LocalPlayer = Players.LocalPlayer :: Player
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Towers = workspace:FindFirstChild("Towers")

local TowerGui = PlayerGui:WaitForChild("TowerGUI") :: ScreenGui
TowerGui.Enabled = true

-- Elements
local TowerAcronym = TowerGui:FindFirstChild("TowerAcronym", true) :: TextLabel?
local TowerName = TowerGui:FindFirstChild("TowerName", true) :: TextLabel?
local TowerRushProgress = TowerGui:FindFirstChild("TowerRushProgress", true) :: TextLabel?
local Timer = TowerGui:FindFirstChild("Timer", true) :: TextLabel?
local BoostsUsed = TowerGui:FindFirstChild("BoostsUsed", true) :: TextLabel?
local RestartLabel = TowerGui:FindFirstChild("RestartLabel", true) :: TextLabel?

local restartTransparency = 0
local restartStrokeTransparency = 1

if RestartLabel then
	restartTransparency = RestartLabel.TextTransparency
	restartStrokeTransparency = RestartLabel.TextStrokeTransparency
end

local GUI = {}

local function fadeText(label: TextLabel, target: number)
	local tween = TweenService:Create(
		label,
		TweenInfo.new(0.15, Enum.EasingStyle.Linear),
		{ TextTransparency = target }
	)
	tween:Play()
end

local function onMouseEnter()
	if TowerName then
		fadeText(TowerName, 0)
	end
end

local function onMouseLeave()
	if TowerName then
		fadeText(TowerName, 1)
	end
end

function GUI:SetTowerAcronym(acronym: string)
	if not TowerAcronym then
		return
	end

	TowerAcronym.Text = acronym
	TowerAcronym.Visible = acronym ~= ""

	if not TowerName then
		return
	end

	local tower = Towers:FindFirstChild(acronym)
	if not tower then
		return
	end

	local difficultyName = tower:FindFirstChild("Difficulty") :: StringValue
	if difficultyName then
		local difficulty = Util:GetDifficulty(difficultyName.Value)
		local color = difficulty.Color
		local factor = 0.35
		local stroke = Color3.new(color.R * factor, color.G * factor, color.B * factor)

		TowerAcronym.TextColor3 = color
		TowerAcronym.TextStrokeColor3 = stroke

		TowerName.TextColor3 = color
		TowerName.TextStrokeColor3 = stroke
	end

	local properName = tower:FindFirstChild("ProperName") :: StringValue
	if not properName then
		return
	end

	TowerName.Text = properName.Value
end

--[=[
	Updates tower rush progress text and toggles visibility when no rush is active.

	@within GUI
]=]
function GUI:SetTowerRush(progress: number, max: number)
	if TowerRushProgress then
		TowerRushProgress.Text = `{progress}/{max}`
		TowerRushProgress.Visible = max ~= 0
	end
end

--[=[
	Sets the displayed tower timer using formatted seconds.

	@within GUI
	@param time number
]=]
function GUI:SetTowerTimer(time: number)
	if Timer then
		Timer.Text = Util:FormatTimer(time)
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
	TowerAcronym.MouseEnter:Connect(onMouseEnter)
	TowerAcronym.MouseLeave:Connect(onMouseLeave)
end

return GUI
