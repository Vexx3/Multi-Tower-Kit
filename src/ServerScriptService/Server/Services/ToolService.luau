--[[
	Handles tool equipment logic, boost tracking, and debug tools.
	Merged from ToolService + DebugService for simplicity.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Framework = ReplicatedStorage.Framework

local Log = require(Framework.Log)
local PlayerData = require("../Player/PlayerData")
local Types = require(Shared.Types)

local TowerRushes = require(Shared.Data.TowerRushes)

local COMPLETION_TOOLS = ServerStorage:FindFirstChild("CompletionTools") :: Folder?
local STARTER_PACK_STUDIO = ServerStorage:FindFirstChild("StarterPackStudio") :: Folder?

local ToolService = {}

--- Handles tool equipment logic for anti-cheat and boost tracking.
--- @param player PlayerInfo -- The player who equipped the tool
--- @param item Tool -- The tool that was equipped
function ToolService.handleToolEquipped(player: Types.PlayerInfo, item: Tool)
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

	-- Kill player if using boost in no-boost rush
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
--- @param player Player -- The player to give tools to
--- @param towerAcronym string -- The tower acronym to look up tools for
function ToolService.giveTowerTools(player: Player, towerAcronym: string)
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
--- @param player Player -- The player to give tools to
function ToolService.giveAllCompletedTowerTools(player: Player)
	local data = PlayerData.getData(player)
	if not data or not data.completedTowers then
		return
	end

	for _, acronym in data.completedTowers do
		ToolService.giveTowerTools(player, acronym)
	end
end

--- Initializes debug tools in Studio and validates boost item configuration.
function ToolService.initializeDebugTools()
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

function ToolService.Start()
	ToolService.initializeDebugTools()
end

return ToolService
