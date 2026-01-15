-- Handles updating PortalSign and ChartLine ObjectValues in tower folders
-- to green when a player has beaten the tower. Changes persist locally.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerGame = ReplicatedStorage.TowerGame

local BlinkClient = require(TowerGame.Network.BlinkClient)

local TOWERS = workspace:WaitForChild("Towers")
local COMPLETED_COLOR = Color3.fromRGB(44, 101, 29)
local AJ_COMPLETED_COLOR = Color3.fromRGB(245, 205, 48)

local currentCompleted: { string } = {}
local currentCompletedAj: { string } = {}

local TowerSignManager = {}

TowerSignManager.COMPLETED_COLOR = COMPLETED_COLOR
TowerSignManager.AJ_COMPLETED_COLOR = AJ_COMPLETED_COLOR

local function setPartColor(instance: Instance?, color: Color3)
	if not instance or not instance:IsA("ObjectValue") then
		return
	end

	local part = instance.Value
	if part and part:IsA("BasePart") then
		part.Color = color
	end
end

-- Updates the color of PortalSign and ChartLine ObjectValues to indicate completion.
function TowerSignManager.markTowerCompleted(towerName: string, color: Color3?)
	local towerFolder = TOWERS:FindFirstChild(towerName)
	if not towerFolder then
		return
	end

	local finalColor = color or COMPLETED_COLOR

	setPartColor(towerFolder:FindFirstChild("PortalSign", true), finalColor)
	setPartColor(towerFolder:FindFirstChild("ChartLine", true), finalColor)
end

-- Updates tower signs for all towers the player has completed.
-- Expected data format: { completedTowers: {string}, completedAjTowers: {string} }
function TowerSignManager.updateCompletedTowers(data: any)
	if not data then
		return
	end

	local shouldUpdate = false

	if data.completedTowers then
		currentCompleted = data.completedTowers
		shouldUpdate = true
	end

	if data.completedAjTowers then
		currentCompletedAj = data.completedAjTowers
		shouldUpdate = true
	end

	if not shouldUpdate then
		return
	end

	local processed: { [string]: boolean } = {}

	for _, towerName in currentCompleted do
		TowerSignManager.markTowerCompleted(towerName, COMPLETED_COLOR)
		processed[towerName] = true
	end

	for _, towerName in currentCompletedAj do
		if not processed[towerName] then
			TowerSignManager.markTowerCompleted(towerName, AJ_COMPLETED_COLOR)
		end
	end
end

-- Initializes the TowerSignManager on the client.
function TowerSignManager.init()
	BlinkClient.PlayerDataUpdate.On(function(changes)
		TowerSignManager.updateCompletedTowers(changes)
	end)
end

return TowerSignManager
