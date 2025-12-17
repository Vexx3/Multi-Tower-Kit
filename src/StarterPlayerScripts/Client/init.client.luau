-- Licensed under the MIT License
-- Copyright (c) 2025 Zylx

--[=[
	Main client entry point for Multi-Tower Kit.
	Handles tower loading/unloading, HUD updates, client objects, and input.

	@client
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local BlinkClient = require(ReplicatedStorage.Network.BlinkClient)

local Shared = ReplicatedStorage.Shared

local Framework = ReplicatedStorage.Framework
local Kit = Framework.Kit

-- Modules
local Announcements = require("@self/Game/Announcements")
local ClientObjects = require("@self/Game/ClientObjects")
local GameConfig = require(ReplicatedStorage.GameData.Config)
local ModuleLoader = require(Shared.ModuleLoader)
local TowerHUD = require("@self/UI/TowerHUD")
local conch = require(ReplicatedStorage.Packages.conch)
local conchui = require(ReplicatedStorage.Packages["conch-ui"])

-- EToH v6 Managers
local CharacterManager = require(Kit.Managers.CharacterManager)
local ClientObjectManager = require(Kit.Managers.ClientObjectManager)
local FlipManager = require(Kit.Managers.FlipManager)
local GuiManager = require(Kit.Managers.GuiManager)
local LightingManager = require(Kit.Managers.LightingManager)

-- Remotes
local ResetEffectGui = ReplicatedStorage:WaitForChild("ResetEffectGui") :: BindableEvent

-- State
local LocalPlayer = Players.LocalPlayer :: Player
local TowerTimer = 0
local RestartTime = 0
local RestartTimeMax = 1
local RestartDebounce = false
local CurrentTower = ""

local function loadTower(acronym: string, purist: boolean, resetTimer: boolean)
	CurrentTower = acronym

	if resetTimer then
		TowerTimer = 0
		TowerHUD:SetBoostsUsed(false)
	end

	TowerHUD:SetTowerAcronym(acronym)
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

local function unloadTower()
	if CurrentTower ~= "" then
		LightingManager:ResetLighting()
	end

	CurrentTower = ""
	TowerTimer = 0
	RestartTime = 0

	ResetEffectGui:Fire()
	ClientObjects:UnloadClientObjects()

	TowerHUD:SetTowerAcronym("")
	TowerHUD:SetTowerTimer(0)
	TowerHUD:SetTowerRush(0, 0)
	TowerHUD:SetBoostsUsed(false)
	TowerHUD:SetRestartLabel(0)
end

-- Should fire every ~2 or so seconds to ensure the client's timer and the server's timer aren't out of sync
-- If they are out of sync, both are using DeltaTime to increment the timer so the margin of error should be very small
local function correctTimer(time: number)
	TowerTimer = time
end

local function updateTowerRush(index: number, end_: number)
	TowerHUD:SetTowerRush(index, end_)
end

local function onCharacterAdded(character: Model)
	character.ChildAdded:Connect(function(ins: Instance)
		-- If item equipped:
		if ins:IsA("Tool") then
			local BoostName = ins:GetAttribute("BoostName") :: string?

			-- If this is a boost item and the player is in a tower
			if BoostName and BoostName ~= "" and CurrentTower ~= "" then
				TowerHUD:SetBoostsUsed(true)
			end
		end
	end)
end

local lastDisplayedTimer = -1
local lastRestartProgress = -1
local TIMER_UPDATE_THRESHOLD = 0.01

local mathMin = math.min
local mathMax = math.max
local mathAbs = math.abs

local function onStep(deltaTime: number)
	if CurrentTower == "" then
		if TowerTimer ~= 0 then
			TowerTimer = 0
			TowerHUD:SetTowerTimer(0)
			lastDisplayedTimer = 0
		end
		RestartTime = 0
	else
		TowerTimer += deltaTime

		-- If the user is holding the restart key, and the debounce is false
		if UserInputService:IsKeyDown(Enum.KeyCode.R) then
			if not RestartDebounce then
				RestartTime = mathMin(RestartTime + deltaTime, RestartTimeMax)
				if RestartTime >= RestartTimeMax then
					-- Enable the debounce so that we don't spam the server
					RestartDebounce = true
					BlinkClient.RestartRequested.Fire()
				end
			end
		else
			RestartTime = mathMax(RestartTime - deltaTime, 0)
			RestartDebounce = false
		end

		-- Only update timer display when it visually changes (every 10ms)
		if mathAbs(TowerTimer - lastDisplayedTimer) >= TIMER_UPDATE_THRESHOLD then
			TowerHUD:SetTowerTimer(TowerTimer)
			lastDisplayedTimer = TowerTimer
		end
	end

	-- Only update restart label when progress changes
	local restartProgress = RestartTime / RestartTimeMax
	if restartProgress ~= lastRestartProgress then
		TowerHUD:SetRestartLabel(restartProgress)
		lastRestartProgress = restartProgress
	end
end

local function init()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

	TowerHUD:ShowLoadingScreen("Loading Data...", false)

	CharacterManager:Init()
	ClientObjectManager:Init()
	FlipManager:Init()
	GuiManager:Init()
	LightingManager:Init()

	-- Initialize packages
	require(ReplicatedStorage.Packages.satchel)
	require(Shared.ConchTypes)

	conch.initiate_default_lifecycle()
	conchui.bind_to(GameConfig.ADMIN_HOTKEY)

	Announcements:Init()

	ModuleLoader.LoadAndInit(script, { script.Game, script.UI })

	-- Request everpresent client objects
	local ECOs: boolean, ECOFolder: Folder? = BlinkClient.RequestEverpresentCOs.Invoke()
	if ECOs and ECOFolder then
		ClientObjects:LoadClientObjects(ECOFolder, true, "EverpresentCOs")
	end

	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	BlinkClient.UpdateTowerTimer.On(correctTimer)
	BlinkClient.UpdateTowerRush.On(updateTowerRush)
	BlinkClient.LoadTower.On(loadTower)
	BlinkClient.UnloadTower.On(unloadTower)
	RunService.RenderStepped:Connect(onStep)

	TowerHUD:SetTowerTimer(0)
	TowerHUD:SetTowerAcronym("")
	TowerHUD:SetTowerRush(0, 0)

	local dataLoaded = LocalPlayer:GetAttribute("DataLoaded")
	if dataLoaded then
		TowerHUD:HideLoadingScreen()
	else
		LocalPlayer:GetAttributeChangedSignal("DataLoaded"):Connect(function()
			local loaded = LocalPlayer:GetAttribute("DataLoaded")
			if loaded == true then
				TowerHUD:HideLoadingScreen()
			end
		end)
	end
end

init()
