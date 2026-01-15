--[=[
	Handles updating PortalSign and ChartLine ObjectValues in tower folders
	to green when a player has beaten the tower. Changes persist locally.

	@class TowerSignManager
	@client
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BlinkClient = require(ReplicatedStorage.TowerGame.Network.BlinkClient)

local TOWERS = workspace:WaitForChild("Towers")

local TowerSignManager = {}

TowerSignManager.COMPLETED_COLOR = Color3.fromRGB(44, 101, 29)
TowerSignManager.AJ_COMPLETED_COLOR = Color3.fromRGB(245, 205, 48)

local currentCompleted = {}
local currentCompletedAj = {}

local function setPartColor(instance: Instance?, color: Color3)
	if not instance or not instance:IsA("ObjectValue") then
		return
	end

	local part = instance.Value
	if part and part:IsA("BasePart") then
		part.Color = color
	end
end

--[=[
	Updates the color of PortalSign and ChartLine ObjectValues in a tower to
	indicate completion.
]=]
function TowerSignManager.markTowerCompleted(towerName: string, color: Color3?)
	local towerFolder = TOWERS:FindFirstChild(towerName)
	if not towerFolder then
		return
	end

	local finalColor = color or TowerSignManager.COMPLETED_COLOR

	setPartColor(towerFolder:FindFirstChild("PortalSign", true), finalColor)
	setPartColor(towerFolder:FindFirstChild("ChartLine", true), finalColor)
end

--[=[
	Updates tower signs for all towers the player has completed.
	Expected data format: { completedTowers: {string}, completedAjTowers: {string} }
]=]
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

	local processed = {}

	for _, towerName in currentCompleted do
		TowerSignManager.markTowerCompleted(towerName, TowerSignManager.COMPLETED_COLOR)
		processed[towerName] = true
	end

	for _, towerName in currentCompletedAj do
		if not processed[towerName] then
			TowerSignManager.markTowerCompleted(towerName, TowerSignManager.AJ_COMPLETED_COLOR)
		end
	end
end

--[=[
	Initializes the TowerSignManager on the client.
	Fetches initial data and listens for updates.
]=]
function TowerSignManager.init()
	BlinkClient.PlayerDataUpdate.On(function(changes)
		TowerSignManager.updateCompletedTowers(changes)
	end)
end

return TowerSignManager
