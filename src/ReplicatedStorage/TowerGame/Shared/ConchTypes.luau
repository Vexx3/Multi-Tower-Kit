-- Defines custom types for the Conch command system.

local DifficultiesModule = require("./Data/Difficulties")
local conch = require("@game/ReplicatedStorage/Packages/conch")

local markers = workspace:WaitForChild("Markers")
local towers = workspace:WaitForChild("Towers")

local difficulties = DifficultiesModule.data
local markerMap: { [string]: BasePart } = {}
local towerArray: { string } = {}
local difficultyArray: { string } = {}

for _, child in ipairs(markers:GetChildren()) do
	if child:IsA("BasePart") then
		if child.Name == "LobbyTP" then
			continue
		end
		markerMap[child.Name] = child
	end
end

for _, tower in ipairs(towers:GetChildren()) do
	if tower:IsA("Folder") then
		if tower.Name == "EverpresentCOs" then
			continue
		end
		table.insert(towerArray, tower.Name)
	end
end

for name, _ in pairs(difficulties) do
	table.insert(difficultyArray, name)
end

local difficultyName = conch.register_type("difficulty_name", conch.args.enum_new(difficultyArray))
local markerName = conch.register_type("marker_name", conch.args.enum_map(markerMap))
local towerName = conch.register_type("tower_name", conch.args.enum_new(towerArray))

local ConchTypes = {}

ConchTypes.difficultyName = difficultyName
ConchTypes.markerName = markerName
ConchTypes.towerName = towerName

return ConchTypes
