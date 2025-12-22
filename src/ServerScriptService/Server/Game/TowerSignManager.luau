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

local TowerSignManager = {}

local function setPartColor(objectValue: ObjectValue?)
	if not objectValue or not objectValue:IsA("ObjectValue") then
		return
	end
	local part = objectValue.Value
	if part and part:IsA("BasePart") then
		part.Color = COMPLETED_COLOR
	end
end

--[=[
	Updates the color of PortalSign and ChartLine ObjectValues in a tower to
	indicate completion.

	@within TowerSignManager
]=]
function TowerSignManager:MarkTowerCompleted(towerName: string)
	local towerFolder = TOWERS:FindFirstChild(towerName)
	if not towerFolder then
		return
	end

	setPartColor(towerFolder:FindFirstChild("PortalSign", true))
	setPartColor(towerFolder:FindFirstChild("ChartLine", true))
end

--[=[
	Updates tower signs for all towers the player has completed. Called on
	player join.

	@within TowerSignManager
]=]
function TowerSignManager:UpdateCompletedTowersForPlayer(player: Player)
	local data = PlayerData:GetData(player)
	if not data or not data.CompletedTowers then
		return
	end

	for _, towerName in data.CompletedTowers do
		self:MarkTowerCompleted(towerName)
	end
end

return TowerSignManager
