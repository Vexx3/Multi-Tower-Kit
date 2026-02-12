--[=[
	Displays the current tower name/acronym with difficulty colors.
	Shows the full tower name on hover.

	@class TowerHUD
	@client
]=]

local Players = game:GetService("Players")

local Util = require("../../../shared/utils/util")

local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui")

local screenGui = PlayerGui:WaitForChild("TowerGUI") :: ScreenGui

local towerAcronymLabel = screenGui:FindFirstChild("TowerAcronym", true) :: TextLabel?
local timerLabel = screenGui:FindFirstChild("Timer", true) :: TextLabel?
local restartLabelElement = screenGui:FindFirstChild("RestartLabel", true) :: TextLabel?

local restartTransparency = 0
local restartStrokeTransparency = 1

if restartLabelElement then
	restartTransparency = restartLabelElement.TextTransparency
	restartStrokeTransparency = restartLabelElement.TextStrokeTransparency
end

local currentAcronym = ""
local currentTowerName = ""

local TowerHUD = {}

--[=[
	Sets the tower acronym display and caches the full tower name.
	Applies difficulty-based colors to the label.

	@param acronym string -- The tower acronym to display (empty string hides the label)
]=]
function TowerHUD.setAcronym(acronym: string): ()
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

--[=[
	Sets the displayed tower timer using formatted seconds.

	@param seconds number -- The time in seconds to display
]=]
function TowerHUD.setTimer(seconds: number): ()
	if timerLabel then
		timerLabel.Text = Util.formatTimer(seconds)
	end
end

--[=[
	Fades the restart label based on a normalized progress value.

	@param t number -- Progress value from 0 (hidden) to 1 (fully visible)
]=]
function TowerHUD.setRestartProgress(t: number): ()
	if restartLabelElement then
		restartLabelElement.Visible = t > 0
		restartLabelElement.TextTransparency = 1 - (t * (1 - restartTransparency))
		restartLabelElement.TextStrokeTransparency = 1 - (t * (1 - restartStrokeTransparency))
	end
end

--[=[
	Returns the current tower acronym.

	@return string -- The current tower acronym
]=]
function TowerHUD.getAcronym(): string
	return currentAcronym
end

--[=[
	Returns the full tower name.

	@return string -- The full tower name
]=]
function TowerHUD.getTowerName(): string
	return currentTowerName
end

--[=[
	Initializes hover behavior for the tower acronym label.
	Shows full tower name on hover.
]=]
function TowerHUD.Start(): ()
	if towerAcronymLabel then
		local label = towerAcronymLabel
		label.MouseEnter:Connect(function()
			if currentAcronym ~= "" then
				label.Text = currentTowerName
			end
		end)
		label.MouseLeave:Connect(function()
			label.Text = currentAcronym
		end)
	end
end

return TowerHUD
