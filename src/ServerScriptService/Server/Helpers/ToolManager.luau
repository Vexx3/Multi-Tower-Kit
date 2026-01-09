local ServerStorage = game:GetService("ServerStorage")

local PlayerData = require("../Player/PlayerData")

local CompletionTools = ServerStorage:FindFirstChild("CompletionTools")

local ToolManager = {}

--[=[
	Gives tools from a tower's folder in ServerStorage to a player.
	Ensures no duplicates are given.
]=]
function ToolManager.giveTowerTools(player: Player, towerAcronym: string)
	local towerFolder = CompletionTools:FindFirstChild(towerAcronym)
	if not towerFolder then
		return
	end

	local backpack = player:FindFirstChild("Backpack") :: Folder
	local starterGear = player:FindFirstChild("StarterGear") :: Folder
	local character = player.Character

	for _, tool in towerFolder:GetChildren() do
		if not tool:IsA("Tool") then
			continue
		end

		-- Check if player already has this tool
		local hasTool = (backpack and backpack:FindFirstChild(tool.Name))
			or (character and character:FindFirstChild(tool.Name))
			or (starterGear and starterGear:FindFirstChild(tool.Name))

		if not hasTool then
			if starterGear then
				tool:Clone().Parent = starterGear
			end
			if backpack then
				tool:Clone().Parent = backpack
			end
		end
	end
end

--[=[
	Gives tools for all towers the player has completed.
]=]
function ToolManager.giveAllCompletedTowerTools(player: Player)
	local data = PlayerData.getData(player)
	if not data or not data.CompletedTowers then
		return
	end

	for _, acronym in data.CompletedTowers do
		ToolManager.giveTowerTools(player, acronym)
	end
end

return ToolManager
