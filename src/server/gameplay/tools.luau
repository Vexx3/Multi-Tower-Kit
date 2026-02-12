--[[
	Tool equipment logic, boost tracking, and debug tools.
]]

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")

local Log = require("../../../Framework/Log")
local Types = require("../../shared/types")
local accounts = require("../accounts")

local TowerRushes = require("../../shared/constants/towerRushes")

local COMPLETION_TOOLS = ServerStorage:FindFirstChild("CompletionTools") :: Folder?
local STARTER_PACK_STUDIO = ServerStorage:FindFirstChild("StarterPackStudio") :: Folder?

local tools = {}

--- Handles tool equipment logic for anti-cheat and boost tracking.
function tools.handleToolEquipped(player: Types.PlayerInfo, item: Tool)
	if player.currentTower == "" then
		return
	end

	local isDebugItem = item:GetAttribute("DebugItem") :: boolean?
	local boostName = item:GetAttribute("BoostName") :: string?
	local hasBoost = boostName ~= nil and boostName ~= ""

	if isDebugItem or hasBoost then
		player.debugItemUsed = true
	end

	if not hasBoost then
		return
	end

	player.boostItemUsed = true
	player.boostItemNames[item.Name] = boostName or "Boost Item"

	if player.currentTowerRush ~= "" then
		local rush = TowerRushes[player.currentTowerRush]
		if rush and rush.noBoosts then
			local character = player.player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
	end
end

--- Gives tools from a tower's folder in ServerStorage to a player.
function tools.giveTowerTools(player: Player, towerAcronym: string)
	if not COMPLETION_TOOLS then
		return
	end

	local towerFolder = COMPLETION_TOOLS:FindFirstChild(towerAcronym)
	if not towerFolder then
		return
	end

	local backpack = player:FindFirstChild("Backpack") :: Backpack?
	local starterGear = player:FindFirstChild("StarterGear") :: StarterGear?
	local character = player.Character

	for _, tool in towerFolder:GetChildren() do
		if not tool:IsA("Tool") then
			continue
		end

		local toolName = tool.Name
		local hasTool = (backpack and backpack:FindFirstChild(toolName))
			or (character and character:FindFirstChild(toolName))
			or (starterGear and starterGear:FindFirstChild(toolName))

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

--- Gives tools for all towers the player has completed.
function tools.giveAllCompletedTowerTools(player: Player)
	local data = accounts.getData(player)
	if not data or not data.completedTowers then
		return
	end

	for _, acronym in data.completedTowers do
		tools.giveTowerTools(player, acronym)
	end
end

--- Initializes debug tools in Studio and validates boost item configuration.
function tools.init()
	if RunService:IsStudio() and STARTER_PACK_STUDIO then
		Log({ "Running in Studio, loading debug tools..." })
		for _, tool in STARTER_PACK_STUDIO:GetChildren() do
			tool:SetAttribute("DebugItem", true)
			tool.Parent = StarterPack
		end
	end

	for _, tool in StarterPack:GetChildren() do
		if not tool:IsA("Tool") then
			continue
		end

		local boostNameValue = tool:FindFirstChild("BoostName")
		if boostNameValue and boostNameValue:IsA("StringValue") then
			Log({
				type = "warn",
				[1] = `Boost item {tool.Name} uses a StringValue for BoostName, please change it to an attribute`,
			})
			tool:SetAttribute("BoostName", boostNameValue.Value)
		end
	end
end

return tools
