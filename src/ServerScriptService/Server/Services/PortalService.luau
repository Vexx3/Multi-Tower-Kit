local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage.Framework.Log)
local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared

local PlayerService = require("./PlayerService")
local TowerRushService = require("./TowerRushService")
local TowerService = require("./TowerService")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local MARKERS = workspace.Markers
local PORTALS = workspace.Portals

local PortalService = {}

local function canEnter(playerName: string, targetTower: string?)
	local player = PlayerService.getSession(playerName)
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
				local player = PlayerService.getSession(playerName)
				if player then
					TowerService.loadTower(player, value, true)
				end
			end
		end)
		return
	end

	local TowerRush = portalPart:FindFirstChild("TowerRush") :: StringValue
	if TowerRush then
		RegisterStringPortal(portalPart, TowerRush, function(playerName, value)
			if canEnter(playerName) then
				local player = PlayerService.getSession(playerName)
				if player then
					TowerRushService.loadTowerRush(player, value)
				end
			end
		end)
		return
	end

	local LobbyTeleporter = portalPart:FindFirstChild("LobbyTeleporter") :: StringValue
	if not LobbyTeleporter then
		Log({
			type = "warn",
			[1] = `Part "{portalPart.Name}" was found in the portal folder but it isn't a portal`,
		})
		return
	end

	local targetPart = MARKERS:FindFirstChild(LobbyTeleporter.Value, true) :: BasePart
	if targetPart and targetPart:IsA("BasePart") then
		Util.registerTouch(portalPart, function(playerName)
			local player: PlayerInfo = PlayerService.getSession(playerName)
			if player and not player.touchEventBusy then
				player.touchEventBusy = true
				Util.teleportPlayerToPart(player.player, targetPart)
				player.touchEventBusy = false
			end
		end)
	else
		Log({
			type = "warn",
			[1] = `Could not setup teleporter "{portalPart:GetFullName()}" because it does not reference a BasePart`,
		})
	end
	return
end

function PortalService.init()
	for _, child in PORTALS:GetChildren() do
		if child:IsA("BasePart") then
			Setup(child)
		end
	end
end

return PortalService
