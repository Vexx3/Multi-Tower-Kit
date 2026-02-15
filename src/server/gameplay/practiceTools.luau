--[[
	Practice Tools — Gives and removes Practice Noclip / Practice Heal
	when a player toggles Practice Mode.

	The tools are cloned from ServerStorage.practiceTools, which are
	duplicates of the studio Noclip/Heal tools with practice-specific
	modifications (the noclip script includes tower boundary clamping).

	Scripts inside the cloned tools handle all behaviour — no extra server
	wiring is needed.
]]

local ServerStorage = game:GetService("ServerStorage")

local PRACTICE_TAG = "PracticeTool"

local practiceToolsFolder = ServerStorage:WaitForChild("practiceTools")
local noclipTemplate = practiceToolsFolder:WaitForChild("PracticeNoclip") :: Tool
local healTemplate = practiceToolsFolder:WaitForChild("PracticeHeal") :: Tool

local practiceTools = {}

--- Removes all tools tagged as PracticeTool from backpack, starter gear,
--- and character.
local function removeAll(player: Player)
	local backpack = player:FindFirstChild("Backpack") :: Backpack?
	local starterGear = player:FindFirstChild("StarterGear") :: StarterGear?
	local character = player.Character

	local containers = { backpack, starterGear, character }
	for _, container in containers do
		if not container then
			continue
		end
		for _, child in container:GetChildren() do
			if child:HasTag(PRACTICE_TAG) then
				child:Destroy()
			end
		end
	end
end

--- Gives Practice Noclip and Practice Heal to the player.
function practiceTools.give(player: Player)
	removeAll(player) -- prevent duplicates

	local backpack = player:FindFirstChild("Backpack") :: Backpack?
	local starterGear = player:FindFirstChild("StarterGear") :: StarterGear?

	-- Clone and tag each tool, then parent to both Backpack and StarterGear
	-- so they persist through respawns.
	for _, template in { noclipTemplate, healTemplate } do
		local backpackCopy = template:Clone()
		backpackCopy:AddTag(PRACTICE_TAG)

		local starterCopy = template:Clone()
		starterCopy:AddTag(PRACTICE_TAG)

		if backpack then
			backpackCopy.Parent = backpack
		else
			backpackCopy:Destroy()
		end

		if starterGear then
			starterCopy.Parent = starterGear
		else
			starterCopy:Destroy()
		end
	end
end

--- Removes all practice tools from the player.
function practiceTools.remove(player: Player)
	removeAll(player)
end

return practiceTools
