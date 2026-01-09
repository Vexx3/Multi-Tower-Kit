local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared

local DataInfo = require("./DataInfo")
local TowerManager = require("./TowerManager")
local TowerRushManager = require("./TowerRushManager")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local MARKERS = workspace.Markers
local PORTALS = workspace.Portals

local PortalHandler = {}

local function canEnter(playerName: string, targetTower: string?)
	local player = DataInfo.PlayerInfo[playerName]
	if not player then
		return false
	end

	if player.CurrentTowerRush ~= "" then
		return false
	end

	if player.CurrentTower ~= "" and targetTower and player.CurrentTower ~= targetTower then
		return false
	end

	return true
end

local function RegisterStringPortal(
	part: BasePart,
	value: StringValue,
	onTouch: (playerName: string, value: string) -> ()
)
	Util.registerTouch(part, function(playerName)
		onTouch(playerName, value.Value)
	end)
end

local function Setup(portalPart: BasePart)
	local TowerPortal = portalPart:FindFirstChild("TowerPortal") :: StringValue
	if TowerPortal then
		RegisterStringPortal(portalPart, TowerPortal, function(playerName, value)
			if canEnter(playerName, value) then
				TowerManager.loadTower(playerName, value, true)
			end
		end)
		return
	end

	local TowerRush = portalPart:FindFirstChild("TowerRush") :: StringValue
	if TowerRush then
		RegisterStringPortal(portalPart, TowerRush, function(playerName, value)
			if canEnter(playerName) then
				TowerRushManager.loadTowerRush(playerName, value)
			end
		end)
		return
	end

	local LobbyTeleporter = portalPart:FindFirstChild("LobbyTeleporter") :: StringValue
	if not LobbyTeleporter then
		Util.warn(`Part "{portalPart.Name}" was found in the portal folder but it isn't a portal`)
		return
	end

	local targetPart = MARKERS:FindFirstChild(LobbyTeleporter.Value, true) :: BasePart
	if targetPart and targetPart:IsA("BasePart") then
		Util.registerTouch(portalPart, function(playerName)
			local player: PlayerInfo = DataInfo.PlayerInfo[playerName]
			if player and not player.TouchEventBusy then
				player.TouchEventBusy = true
				Util.teleportPlayerToPart(player.Player, targetPart)
				player.TouchEventBusy = false
			end
		end)
	else
		Util.warn(`Could not setup teleporter "{portalPart:GetFullName()}" because it does not reference a BasePart`)
	end
	return
end

function PortalHandler.initPortals()
	for _, child in PORTALS:GetChildren() do
		if child:IsA("BasePart") then
			Setup(child)
		end
	end
end

return PortalHandler
