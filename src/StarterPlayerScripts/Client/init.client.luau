-- Main client entry point for Multi-Tower Kit.
-- Handles tower loading/unloading, HUD updates, client objects, and input.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Packages = ReplicatedStorage.Packages
local Framework = ReplicatedStorage.Framework
local Kit = Framework.Kit

local Announcements = require(script.Game.Announcements)
local BlinkClient = require(TowerGame.Network.BlinkClient)
local Character = require(Kit.Utility).Character
local ClientObjects = require(script.Game.ClientObjects)
local GameConfig = require(Shared.Data.Config)
local Log = require(Framework.Log)
local ModuleLoader = require(Shared.ModuleLoader)
local TowerGUI = require(script.UI.TowerGUI)
local TowerSignManager = require(script.Game.TowerSignManager)
local conch = require(Packages.conch)
local conchui = require(Packages["conch-ui"])

-- EToH v6 Managers
local CharacterManager = require(Kit.Managers.CharacterManager)
local ClientObjectManager = require(Kit.Managers.ClientObjectManager)
local FlipManager = require(Kit.Managers.FlipManager)
local GuiManager = require(Kit.Managers.GuiManager)
local LightingManager = require(Kit.Managers.LightingManager)

local ResetEffectGui = ReplicatedStorage:WaitForChild("ResetEffectGui") :: BindableEvent
local LocalPlayer = Players.LocalPlayer :: Player

local TIMER_UPDATE_THRESHOLD = 0.01
local RESTART_TIME_MAX = 1

local towerTimer = 0
local restartTime = 0
local restartDebounce = false
local currentTower = ""
local lastDisplayedTimer = -1
local lastRestartProgress = -1

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

	if restartTime >= RESTART_TIME_MAX then
		restartDebounce = true
	end

	if not purist then
		local coFolder: Instance? = LocalPlayer:WaitForChild("ClientSidedObjects", 10)
		if coFolder then
			ClientObjects.loadClientObjects(coFolder, false, acronym)
		else
			Log({
				type = "error",
				[1] = "Tower load failed: No ClientSidedObjects folder received. Possible connection issue.",
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
		if ins:IsA("Tool") then
			local boostName = ins:GetAttribute("BoostName") :: string?
			if boostName and boostName ~= "" and currentTower then
				TowerGUI.setBoostsUsed(true)
			end
		end
	end)
end

local function onStep(deltaTime: number): ()
	-- Handle tower timer
	if currentTower == "" then
		if towerTimer ~= 0 then
			towerTimer = 0
			TowerGUI.setTowerTimer(0)
			lastDisplayedTimer = 0
		end
		restartTime = 0
	else
		towerTimer += deltaTime

		-- Handle restart key hold
		if UserInputService:IsKeyDown(Enum.KeyCode.R) then
			if not restartDebounce then
				restartTime = math.min(restartTime + deltaTime, RESTART_TIME_MAX)
				if restartTime >= RESTART_TIME_MAX then
					restartDebounce = true
					BlinkClient.RestartRequested.Fire()
				end
			end
		else
			restartTime = math.max(restartTime - deltaTime, 0)
			restartDebounce = false
		end

		-- Only update timer display when it visually changes
		if math.abs(towerTimer - lastDisplayedTimer) >= TIMER_UPDATE_THRESHOLD then
			TowerGUI.setTowerTimer(towerTimer)
			lastDisplayedTimer = towerTimer
		end
	end

	-- Only update restart label when progress changes
	local restartProgress = restartTime / RESTART_TIME_MAX
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
	require(Packages.satchel)
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

	-- Set up event listeners
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	BlinkClient.UpdateTowerTimer.On(correctTimer)
	BlinkClient.UpdateTowerRush.On(updateTowerRush)
	BlinkClient.LoadTower.On(loadTower)
	BlinkClient.UnloadTower.On(unloadTower)
	RunService.RenderStepped:Connect(onStep)

	-- Initialize UI state
	TowerGUI.setTowerTimer(0)
	TowerGUI.setTowerAcronym("")
	TowerGUI.setTowerRush(0, 0)

	-- Handle data loading state
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
