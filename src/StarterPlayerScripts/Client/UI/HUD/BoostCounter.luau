--[=[
	Displays the number of boosts used during a tower attempt.
	Updates visibility based on boost count.

	@class BoostCounter
	@client
]=]

local Players = game:GetService("Players")

local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui")

local screenGui = PlayerGui:WaitForChild("TowerGUI") :: ScreenGui

local boostsUsedLabel = screenGui:FindFirstChild("BoostsUsed", true) :: TextLabel?

local BoostCounter = {}

--[=[
	Updates the boost counter display.
	Hides the label when no boosts have been used.

	@param count number -- The number of boosts used
]=]
function BoostCounter.update(count: number): ()
	if not boostsUsedLabel then
		return
	end

	boostsUsedLabel.Visible = count > 0
	boostsUsedLabel.Text = tostring(count)
end

--[=[
	Hides the boost counter.
]=]
function BoostCounter.hide(): ()
	if boostsUsedLabel then
		boostsUsedLabel.Visible = false
	end
end

--[=[
	Returns whether the boost counter is visible.

	@return boolean -- True if visible
]=]
function BoostCounter.isVisible(): boolean
	return boostsUsedLabel ~= nil and boostsUsedLabel.Visible
end

return BoostCounter
