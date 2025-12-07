--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local DataInfo = require("./DataInfo")
local Teleport = require("../Utils/Teleport")
local TowerManager = require("./TowerManager")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type Dictionary<T> = Types.Dictionary<T>
type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local Markers = workspace.Markers
local Portals = workspace.Portals

local PortalHandler = {}

local function RegisterStringPortal(part: BasePart, stringValue: Instance, onTouch: (playerName: string, value: string) -> ())
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
			TowerManager:PlayerLoadTower(playerName, value, true)			
		end)
		return
	end
	
	local TowerRush = portalPart:FindFirstChild("TowerRush") :: StringValue
	if TowerRush then
		RegisterStringPortal(portalPart, TowerRush, function(playerName, value)
			TowerManager:PlayerLoadTowerRush(playerName, value)			
		end)
		return
	end	
	
	local LobbyTeleporter = portalPart:FindFirstChild("LobbyTeleporter") :: StringValue
	if LobbyTeleporter then
		local targetPart = Markers:FindFirstChild(LobbyTeleporter.Value, true) :: BasePart
		if targetPart and targetPart:IsA("BasePart") then
			Util:RegisterTouch(portalPart, function(playerName)
				local player: PlayerInfo = DataInfo.PlayerInfo[playerName]
				if player and not player.TouchEventBusy then
					player.TouchEventBusy = true
					Teleport:TeleportPlayerToPart(player.Player, targetPart)
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
	for _, v in Portals:GetChildren() do
		if v:IsA("BasePart") then
			Setup(v)
		end
	end
end

return PortalHandler
