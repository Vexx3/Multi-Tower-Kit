local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

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

local function CanEnterTower(playerName: string, targetTower: string): boolean
	local player = DataInfo.PlayerInfo[playerName]
	if not player then
		return false
	end

	-- Block other tower entries while in a rush or already inside a tower
	if player.CurrentTowerRush ~= "" then
		return false
	end

	if player.CurrentTower ~= "" and player.CurrentTower ~= targetTower then
		return false
	end

	return true
end

local function CanStartTowerRush(playerName: string): boolean
	local player = DataInfo.PlayerInfo[playerName]
	if not player then
		return false
	end

	-- Cannot start a rush while already in one or inside a tower
	if player.CurrentTowerRush ~= "" then
		return false
	end

	if player.CurrentTower ~= "" then
		return false
	end

	return true
end

local function RegisterStringPortal(
	part: BasePart,
	stringValue: Instance,
	onTouch: (playerName: string, value: string) -> ()
)
	if stringValue and stringValue:IsA("StringValue") then
		Util:RegisterTouch(part, function(playerName)
			onTouch(playerName, stringValue.Value)
		end)
	end
end

local function Setup(portalPart: BasePart)
	local TowerPortal = portalPart:FindFirstChild("TowerPortal") :: StringValue
	if TowerPortal then
		RegisterStringPortal(portalPart, TowerPortal, function(playerName, value)
			if not CanEnterTower(playerName, value) then
				return
			end

			TowerManager:LoadTower(playerName, value, true)
		end)
		return
	end

	local TowerRush = portalPart:FindFirstChild("TowerRush") :: StringValue
	if TowerRush then
		RegisterStringPortal(portalPart, TowerRush, function(playerName, value)
			if not CanStartTowerRush(playerName) then
				return
			end

			TowerRushManager:LoadTowerRush(playerName, value)
		end)
		return
	end

	local LobbyTeleporter = portalPart:FindFirstChild("LobbyTeleporter") :: StringValue
	if LobbyTeleporter then
		local targetPart = MARKERS:FindFirstChild(LobbyTeleporter.Value, true) :: BasePart
		if targetPart and targetPart:IsA("BasePart") then
			Util:RegisterTouch(portalPart, function(playerName)
				local player: PlayerInfo = DataInfo.PlayerInfo[playerName]
				if player and not player.TouchEventBusy then
					player.TouchEventBusy = true
					Util:TeleportPlayerToPart(player.Player, targetPart)
					player.TouchEventBusy = false
				end
			end)
		else
			Util:Warn(
				`Could not setup teleporter "{portalPart:GetFullName()}" because it does not reference a BasePart`
			)
		end
		return
	end

	Util:Warn(`Part "{portalPart.Name}" was found in the portal folder but it isn't a portal`)
end

function PortalHandler:InitPortals()
	for _, child in PORTALS:GetChildren() do
		if child:IsA("BasePart") then
			Setup(child)
		end
	end
end

return PortalHandler
