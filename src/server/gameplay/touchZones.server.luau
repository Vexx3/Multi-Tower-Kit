--[[
	Unified handler for all touch-based interactions.
	Manages portals, markers, teleporters, and custom zones.

	## CUSTOM ZONES (for extending the game)

	You can add your own touch-triggered parts WITHOUT editing this file!

	Method 1: Workspace Tags
	  1. Create a Part anywhere in workspace.
	  2. Add a Roblox Tag called "CustomZone" to the part.
	  3. Register a handler in your own script:

	  ```luau
	  local Hooks = require("path/to/shared/hooks")

	  Hooks.on("CustomZoneTouched", function(player: Player, zoneName: string, part: BasePart)
	      if zoneName == "MySpecialZone" then
	          -- Do something cool!
	          print(player.Name, "touched", zoneName)
	      end
	  end)
	  ```

	Method 2: Custom Portals
	  1. Create a Part in workspace.Portals.
	  2. Add a StringValue child named "TowerPortal" (loads a tower),
	     "TowerRush" (starts a rush), or "LobbyTeleporter" (teleports to a marker).

	All portal/marker/zone types are documented in the setup functions below.
]]

local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")

local Hooks = require("../../shared/hooks")
local Log = require("../../../Framework/Log")
local Util = require("../../shared/utils/util")
local players = require("../lib/players")
local sessionStore = require("../stores/sessionStore")
local towerRush = require("./towerRush")
local towers = require("./towers")

type ZoneData = {
	part: BasePart,
	connection: RBXScriptConnection?,
}

local MARKERS = workspace:FindFirstChild("Markers") :: Folder?
local PORTALS = workspace:FindFirstChild("Portals") :: Folder?

local zones: { ZoneData } = {}

local function registerZone(part: BasePart, onTouch: (playerName: string, part: BasePart) -> ())
	Util.registerTouch(part, onTouch)
	table.insert(zones, { part = part } :: ZoneData)
end

local function canEnterTower(playerName: string, targetTower: string?): boolean
	local player = players.getSession(playerName)
	if not player then
		return false
	end

	if player.currentTowerRush ~= "" then
		return false
	end

	if player.currentTower ~= "" and targetTower and player.currentTower ~= targetTower then
		return false
	end

	return true
end

--- Sets up a portal that loads a tower when touched.
local function setupPortal(portalPart: BasePart)
	local towerPortal = portalPart:FindFirstChild("TowerPortal") :: StringValue?
	if towerPortal then
		registerZone(portalPart, function(playerName)
			if canEnterTower(playerName, towerPortal.Value) then
				local player = players.getSession(playerName)
				if player then
					towers.loadTower(player, towerPortal.Value, true)
				end
			end
		end)
		return
	end

	--- Sets up a portal that starts a tower rush when touched.
	local towerRushValue = portalPart:FindFirstChild("TowerRush") :: StringValue?
	if towerRushValue then
		registerZone(portalPart, function(playerName)
			if canEnterTower(playerName) then
				local player = players.getSession(playerName)
				if player then
					towerRush.loadTowerRush(player, towerRushValue.Value)
				end
			end
		end)
		return
	end

	--- Sets up a teleporter that moves the player to a marker location.
	local lobbyTeleporter = portalPart:FindFirstChild("LobbyTeleporter") :: StringValue?
	if not lobbyTeleporter then
		Log({
			type = "warn",
			[1] = `Part "{portalPart.Name}" was found in the portal folder but it isn't a portal`,
		})
		return
	end

	local targetPart = MARKERS and MARKERS:FindFirstChild(lobbyTeleporter.Value, true) :: BasePart?
	if targetPart and targetPart:IsA("BasePart") then
		registerZone(portalPart, function(playerName)
			local player = players.getSession(playerName)
			if player and not player.touchEventBusy then
				sessionStore.setTouchBusy(playerName, true)
				Util.teleportPlayerToPart(player.player, targetPart)
				sessionStore.setTouchBusy(playerName, false)
			end
		end)
	else
		Log({
			type = "warn",
			[1] = `Could not setup teleporter "{portalPart:GetFullName()}" because it does not reference a BasePart`,
		})
	end
end

local function setupMarker(marker: BasePart)
	if marker.Name == "LobbyTP" then
		local spawnLocation = MARKERS and MARKERS:FindFirstChild("SpawnLocation") :: BasePart?
		if spawnLocation and spawnLocation:IsA("BasePart") then
			registerZone(marker, function(playerName)
				local playerInfo = players.getSession(playerName)
				if playerInfo then
					playerInfo.player.Team = Teams.Start
					Util.teleportPlayerToPart(playerInfo.player, spawnLocation)
				end
			end)
		else
			Log({
				type = "error",
				[1] = "Could not initialize LobbyTP because a SpawnLocation couldn't be found",
			})
		end
	end
end

-- Discover and set up all portals, markers, teleporters, and custom zones
if PORTALS then
	for _, child in PORTALS:GetChildren() do
		if child:IsA("BasePart") then
			setupPortal(child)
		end
	end
end

if MARKERS then
	for _, child in MARKERS:GetChildren() do
		if child:IsA("BasePart") then
			setupMarker(child)
		end
	end
end

-- Custom zones: any BasePart tagged "CustomZone" in workspace.
-- Touch events fire the "CustomZoneTouched" hook with (player, partName, part).
for _, part in CollectionService:GetTagged("CustomZone") do
	if part:IsA("BasePart") then
		registerZone(part, function(playerName)
			local playerInfo = players.getSession(playerName)
			if playerInfo then
				Hooks.fire("CustomZoneTouched", playerInfo.player, part.Name, part)
			end
		end)
	end
end

-- Listen for custom zones added at runtime (e.g., from tower loads)
CollectionService:GetInstanceAddedSignal("CustomZone"):Connect(function(part)
	if part:IsA("BasePart") then
		registerZone(part, function(playerName)
			local playerInfo = players.getSession(playerName)
			if playerInfo then
				Hooks.fire("CustomZoneTouched", playerInfo.player, part.Name, part)
			end
		end)
	end
end)
