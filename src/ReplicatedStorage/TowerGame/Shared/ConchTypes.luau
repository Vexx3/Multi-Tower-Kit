-- Defines custom types for the Conch command system.
-- Registers tower names, marker names, and difficulty names as command arguments.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local DifficultiesModule = require("./Data/Difficulties")
local conch = require(Packages.conch)

local Markers = workspace:WaitForChild("Markers")
local Towers = workspace:WaitForChild("Towers")

local Difficulties = DifficultiesModule.data

local markerMap: { [string]: BasePart } = {}
local towerArray: { string } = {}
local difficultyArray: { string } = {}

for _, child in Markers:GetChildren() do
	if child:IsA("BasePart") then
		if child.Name == "LobbyTP" then
			continue
		end
		markerMap[child.Name] = child
	end
end

for _, tower in Towers:GetChildren() do
	if tower:IsA("Folder") then
		if tower.Name == "EverpresentCOs" then
			continue
		end
		table.insert(towerArray, tower.Name)
	end
end

for name in Difficulties do
	table.insert(difficultyArray, name)
end

local difficultyName = conch.register_type("difficulty_name", conch.args.enum_new(difficultyArray))
local markerName = conch.register_type("marker_name", conch.args.enum_map(markerMap))
local towerName = conch.register_type("tower_name", conch.args.enum_new(towerArray))

local ConchTypes = {
	difficultyName = difficultyName,
	markerName = markerName,
	towerName = towerName,
}

return ConchTypes
