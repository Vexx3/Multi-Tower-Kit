--!strict
-- Written by fanofpixels

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local ZapClient = require(Shared.ZapClient)

-- Folders
local Framework = ReplicatedStorage.Framework
local Kit = Framework.Kit

-- Modules
local Announcements = require(script.Announcements)
local ClientObjects = require(script.ClientObjects)
local Config = require(ReplicatedStorage.GameData.Config)
local GUI = require(script.GUI)
local conch = require(ReplicatedStorage.Packages.conch_standalone)
local conchui = require(ReplicatedStorage.Packages.conch_standalone.roblox_packages.ui)
-- etoh v6
local CharacterManager = require(Kit.Managers.CharacterManager)
local ClientObjectManager = require(Kit.Managers.ClientObjectManager)
local FlipManager = require(Kit.Managers.FlipManager)
local GuiManager = require(Kit.Managers.GuiManager)
local LightingManager = require(Kit.Managers.LightingManager)

-- Remotes
local ResetEffectGui = ReplicatedStorage:WaitForChild("ResetEffectGui") :: BindableEvent

-- Misc Stuff
local LocalPlayer = Players.LocalPlayer :: Player
local TowerTimer = 0
local RestartTime = 0
local RestartTimeMax = 5
local RestartDebounce = false
local CurrentTower = ""

function LoadTower(acronym: string, purist: boolean, resetTimer: boolean)
	CurrentTower = acronym

	if resetTimer then
		TowerTimer = 0
		GUI:SetBoostsUsed(false)
	end

	GUI:SetTowerAcronym(acronym)
	ResetEffectGui:Fire()

	RestartTime = 0

	-- If the restart time is hitting the maximum, enable the debounce so that we don't accidentally restart again
	if RestartTime >= RestartTimeMax then
		RestartDebounce = true
	end

	-- If this tower is purist we can skip it
	if not purist then
		local COFolder: Instance? = LocalPlayer:WaitForChild("ClientSidedObjects", 10)
		if COFolder then
			-- Let the module dedicated to loading client objects load the client objects
			ClientObjects:LoadClientObjects(COFolder, false, acronym)
		else
			error(
				"A tower has attempted to loaded in. It wasn't marked as purist but no ClientSidedObjects folder was sent over. Bad internet connection?"
			)
		end
	end
end

function UnloadTower()
	-- reset lighting from v6
	if CurrentTower ~= "" then
		LightingManager:ResetLighting()
	end

	CurrentTower = ""
	TowerTimer = 0
	RestartTime = 0

	ResetEffectGui:Fire()
	ClientObjects:UnloadClientObjects()

	GUI:SetTowerAcronym("")
	GUI:SetTowerTimer(0)
	GUI:SetTowerRush(0, 0)
	GUI:SetBoostsUsed(false)
	GUI:SetRestartLabel(0)
end

-- Should fire every ~2 or so seconds to ensure the client's timer and the server's timer aren't out of sync
-- If they are out of sync, both are using DeltaTime to increment the timer so the margin of error should be very small
function CorrectTimer(time: number)
	TowerTimer = time
end

function UpdateTowerRush(index: number, end_: number)
	GUI:SetTowerRush(index, end_)
end

function CharacterAdded(character: Model)
	character.ChildAdded:Connect(function(ins: Instance)
		-- If item equipped:
		if ins:IsA("Tool") then
			local BoostName = ins:GetAttribute("BoostName") :: string?

			-- If this is a boost item and the player is in a tower
			if BoostName and BoostName ~= "" and CurrentTower ~= "" then
				GUI:SetBoostsUsed(true)
			end
		end
	end)
end

function Step(deltaTime: number)
	if CurrentTower == "" then
		TowerTimer = 0
		RestartTime = 0
	else
		TowerTimer += deltaTime

		-- If the user is holding the restart key, and the debounce is false
		if UserInputService:IsKeyDown(Enum.KeyCode.R) then
			if not RestartDebounce then
				RestartTime = math.min(RestartTime + deltaTime, RestartTimeMax)
				if RestartTime >= RestartTimeMax then
					-- Enable the debounce so that we don't spam the server
					RestartDebounce = true
					ZapClient.RestartRequested.Fire()
				end
			end
		else
			RestartTime = math.max(RestartTime - deltaTime, 0)
			RestartDebounce = false
		end
	end

	GUI:SetRestartLabel(RestartTime / RestartTimeMax)
	GUI:SetTowerTimer(TowerTimer)
end

ZapClient.UpdateTowerTimer.SetCallback(CorrectTimer)
ZapClient.UpdateTowerRush.SetCallback(UpdateTowerRush)
ZapClient.LoadTower.SetCallback(LoadTower)
ZapClient.UnloadTower.SetCallback(UnloadTower)

RunService.RenderStepped:Connect(Step)

do
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

	CharacterManager:Init()
	ClientObjectManager:Init()
	FlipManager:Init()
	GuiManager:Init()
	LightingManager:Init()

	require(Shared.ConchTypes)

	conch.initiate_default_lifecycle()
	conchui.bind_to(Config.ADMIN_HOTKEY)

	Announcements:Init()

	local ECOs: boolean, ECOFolder: Folder? = ZapClient.RequestEverpresentCOs.Call()
	if ECOs and ECOFolder then
		ClientObjects:LoadClientObjects(ECOFolder, true, "EverpresentCOs")
	end

	LocalPlayer.CharacterAdded:Connect(CharacterAdded)

	GUI:SetTowerTimer(0)
	GUI:SetTowerAcronym("")
	GUI:SetTowerRush(0, 0)
end
