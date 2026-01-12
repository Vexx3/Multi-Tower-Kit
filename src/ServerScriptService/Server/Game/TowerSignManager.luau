--[=[
	Handles updating PortalSign and ChartLine ObjectValues in tower folders
	to green when a player has beaten the tower. Changes persist across
	rejoins by checking CompletedTowers data.

	@class TowerSignManager
	@server
]=]

local PlayerData = require("../Player/PlayerData")

local TOWERS = workspace.Towers

local COMPLETED_COLOR = Color3.fromRGB(44, 101, 29)
local AJ_COMPLETED_COLOR = Color3.fromRGB(245, 205, 48)

local TowerSignManager = {}
TowerSignManager.COMPLETED_COLOR = COMPLETED_COLOR
TowerSignManager.AJ_COMPLETED_COLOR = AJ_COMPLETED_COLOR

local function setPartColor(objectValue: ObjectValue?, color: Color3)
	if not objectValue or not objectValue:IsA("ObjectValue") then
		return
	end
	local part = objectValue.Value
	if part and part:IsA("BasePart") then
		part.Color = color
	end
end

--[=[
	Updates the color of PortalSign and ChartLine ObjectValues in a tower to
	indicate completion.

	@within TowerSignManager
]=]
function TowerSignManager.markTowerCompleted(towerName: string, color: Color3?)
	local towerFolder = TOWERS:FindFirstChild(towerName)
	if not towerFolder then
		return
	end

	local finalColor: Color3 = color or COMPLETED_COLOR

	setPartColor(towerFolder:FindFirstChild("PortalSign", true), finalColor)
	setPartColor(towerFolder:FindFirstChild("ChartLine", true), finalColor)
end

--[=[
	Updates tower signs for all towers the player has completed. Called on
	player join.

	@within TowerSignManager
]=]
function TowerSignManager.updateCompletedTowersForPlayer(player: Player)
	local data = PlayerData.getData(player)
	if not data then
		return
	end

	local processed = {}

	if data.CompletedTowers then
		for _, towerName in data.CompletedTowers do
			TowerSignManager.markTowerCompleted(towerName, COMPLETED_COLOR)
			processed[towerName] = true
		end
	end

	if data.CompletedAJTowers then
		for _, towerName in data.CompletedAJTowers do
			if not processed[towerName] then
				TowerSignManager.markTowerCompleted(towerName, AJ_COMPLETED_COLOR)
			end
		end
	end
end

return TowerSignManager
