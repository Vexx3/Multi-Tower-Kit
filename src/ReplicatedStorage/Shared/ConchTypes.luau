local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameData = ReplicatedStorage.GameData
local Packages = ReplicatedStorage.Packages

local Badges = require(GameData.Badges)
local conch = require(Packages.conch_standalone)

local Markers = workspace.Markers
local Towers = workspace.Towers

local markerMap = {}
local towerArray = {}

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

local badge_name = conch.register_type("badge_name", conch.args.enum_map(Badges))

local marker_name = conch.register_type("marker_name", conch.args.enum_map(markerMap))

local tower_name = conch.register_type("tower_name", conch.args.enum_new(towerArray))

return {
	badge_name = badge_name,
	marker_name = marker_name,
	tower_name = tower_name,
}
