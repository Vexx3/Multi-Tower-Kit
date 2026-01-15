-- Main client entry point for Multi-Tower Kit.
-- Handles tower loading/unloading, HUD updates, client objects, and input.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local BlinkClient = require(ReplicatedStorage.TowerGame.Network.BlinkClient)

local Shared = ReplicatedStorage.TowerGame.Shared

local Framework = ReplicatedStorage.Framework
local Kit = Framework.Kit
local Log = require(Framework.Log)
local Utility = require(Kit.Utility)
local Character = Utility.Character

-- Modules
local Announcements = require("@self/Game/Announcements")
local ClientObjects = require("@self/Game/ClientObjects")
local GameConfig = require(ReplicatedStorage.TowerGame.Shared.Data.Config)
local ModuleLoader = require(Shared.ModuleLoader)
local TowerGUI = require("@self/UI/TowerGUI")
local TowerSignManager = require("@self/Game/TowerSignManager")
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
local towerTimer = 0
local restartTime = 0
local restartTimeMax = 1
local restartDebounce = false
local currentTower = ""

local lastDisplayedTimer = -1
local lastRestartProgress = -1
local TIMER_UPDATE_THRESHOLD = 0.01

local function loadTower(acronym: string, purist: boolean, resetTimer: boolean): ()
	if currentTower ~= "" then
		LightingManager:ResetLighting()
	end

	currentTower = acronym

	if resetTimer then
		towerTimer = 0
		TowerGUI.setBoostsUsed(false)
	end

	TowerGUI.setTowerAcronym(acronym)
	ResetEffectGui:Fire()

	restartTime = 0

	-- If the restart time is hitting the maximum, enable the debounce so that we don't accidentally restart again
	if restartTime >= restartTimeMax then
		restartDebounce = true
	end

	-- If this tower is purist we can skip it
	if not purist then
		local coFolder: Instance? = LocalPlayer:WaitForChild("ClientSidedObjects", 10)
		if coFolder then
			-- Let the module dedicated to loading client objects load the client objects
			ClientObjects.loadClientObjects(coFolder, false, acronym)
		else
			Log({
				type = "error",
				[1] = "A tower has attempted to loaded in. It wasn't marked as purist but no ClientSidedObjects folder was sent over. Bad internet connection?",
			})
		end
	end
end

local function unloadTower(): ()
	if currentTower ~= "" then
		LightingManager:ResetLighting()
	end

	currentTower = ""
	towerTimer = 0
	restartTime = 0

	ResetEffectGui:Fire()
	ClientObjects.unloadClientObjects()

	TowerGUI.setTowerAcronym("")
	TowerGUI.setTowerTimer(0)
	TowerGUI.setTowerRush(0, 0)
	TowerGUI.setBoostsUsed(false)
	TowerGUI.setRestartLabel(0)
end

-- Should fire every ~2 or so seconds to ensure the client's timer and the server's timer aren't out of sync
-- If they are out of sync, both are using DeltaTime to increment the timer so the margin of error should be very small
local function correctTimer(time: number): ()
	towerTimer = time
end

local function updateTowerRush(index: number, end_: number): ()
	TowerGUI.setTowerRush(index, end_)
end

local function onCharacterAdded(character: Model): ()
	local humanoid = Character.getHumanoid()
	if not humanoid then
		return
	end

	character.ChildAdded:Connect(function(ins: Instance)
		-- If item equipped:
		if ins:IsA("Tool") then
			local boostName = ins:GetAttribute("BoostName") :: string?

			-- If this is a boost item and the player is in a tower
			if boostName and boostName ~= "" and currentTower then
				TowerGUI.setBoostsUsed(true)
			end
		end
	end)
end

local function onStep(deltaTime: number): ()
	if currentTower == "" then
		if towerTimer ~= 0 then
			towerTimer = 0
			TowerGUI.setTowerTimer(0)
			lastDisplayedTimer = 0
		end
		restartTime = 0
	else
		towerTimer += deltaTime

		-- If the user is holding the restart key, and the debounce is false
		if UserInputService:IsKeyDown(Enum.KeyCode.R) then
			if not restartDebounce then
				restartTime = math.min(restartTime + deltaTime, restartTimeMax)
				if restartTime >= restartTimeMax then
					-- Enable the debounce so that we don't spam the server
					restartDebounce = true
					BlinkClient.RestartRequested.Fire()
				end
			end
		else
			restartTime = math.max(restartTime - deltaTime, 0)
			restartDebounce = false
		end

		-- Only update timer display when it visually changes (every 10ms)
		if math.abs(towerTimer - lastDisplayedTimer) >= TIMER_UPDATE_THRESHOLD then
			TowerGUI.setTowerTimer(towerTimer)
			lastDisplayedTimer = towerTimer
		end
	end

	-- Only update restart label when progress changes
	local restartProgress = restartTime / restartTimeMax
	if restartProgress ~= lastRestartProgress then
		TowerGUI.setRestartLabel(restartProgress)
		lastRestartProgress = restartProgress
	end
end

local function init(): ()
	Log({ "Initializing Client Framework..." })

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

	TowerGUI.showLoadingScreen("Loading data...", false)

	-- Initialize v6 managers
	CharacterManager:Init()
	ClientObjectManager:Init()
	FlipManager:Init()
	GuiManager:Init()
	LightingManager:Init()

	-- Initialize packages
	require(ReplicatedStorage.Packages.satchel)
	require(Shared.ConchTypes)

	conch.initiate_default_lifecycle()
	conchui.bind_to(GameConfig.adminHotkey)

	Announcements.init()
	TowerSignManager.init()

	ModuleLoader.loadAndInit(script, { script.Game, script.UI })

	-- Request everpresent client objects
	local success, ecoFolder = BlinkClient.RequestEverpresentCOs.Invoke()
	if success and ecoFolder then
		ClientObjects.loadClientObjects(ecoFolder, true, "EverpresentCOs")
	end

	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	BlinkClient.UpdateTowerTimer.On(correctTimer)
	BlinkClient.UpdateTowerRush.On(updateTowerRush)
	BlinkClient.LoadTower.On(loadTower)
	BlinkClient.UnloadTower.On(unloadTower)
	RunService.RenderStepped:Connect(onStep)

	TowerGUI.setTowerTimer(0)
	TowerGUI.setTowerAcronym("")
	TowerGUI.setTowerRush(0, 0)

	local dataLoaded = LocalPlayer:GetAttribute("DataLoaded")
	if dataLoaded then
		TowerGUI.hideLoadingScreen()
	else
		LocalPlayer:GetAttributeChangedSignal("DataLoaded"):Connect(function()
			local loaded = LocalPlayer:GetAttribute("DataLoaded")
			if loaded == true then
				TowerGUI.hideLoadingScreen()
			end
		end)
	end

	Log({ "Client Framework Initialization Complete." })
end

init()
