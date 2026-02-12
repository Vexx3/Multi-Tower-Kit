--[[
	Main client entry point for Multi-Tower Kit.
	Uses TowerState (Charm) for reactive state management.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local BlinkClient = require("../../shared/Network/BlinkClient")
local allJumps = require("./allJumps")
local Character = require("../../../Framework/Kit/Utility").Character
local ClientObjects = require("./clientObjects")
local GameConfig = require("../../shared/constants/config")
local HUD = require("../ui/hud")
local Log = require("../../../Framework/Log")
local MenuController = require("../ui/menu")
local TowerStateModule = require("../stores/towerState")
local chat = require("./chat")
local display = require("./display")
local legacyCompat = require("./legacyCompat")
local TowerState = TowerStateModule.atom
local DEFAULT_TOWER_STATE = TowerStateModule.DEFAULT
local conch = require("../../../Packages/conch")
local conchui = require("../../../Packages/conch-ui")

type TowerStateData = TowerStateModule.TowerStateData

-- Helper to update a single field in TowerState
local function updateState(key: string, value: any)
	TowerState(function(s: TowerStateData): TowerStateData
		local new: any = table.clone(s)
		new[key] = value
		return new
	end)
end

-- EToH v6 Managers
local CharacterManager = require("../../../Framework/Kit/Managers/CharacterManager")
local ClientObjectManager = require("../../../Framework/Kit/Managers/ClientObjectManager")
local FlipManager = require("../../../Framework/Kit/Managers/FlipManager")
local GuiManager = require("../../../Framework/Kit/Managers/GuiManager")
local LightingManager = require("../../../Framework/Kit/Managers/LightingManager")

local ResetEffectGui = ReplicatedStorage:WaitForChild("ResetEffectGui") :: BindableEvent
local LocalPlayer = Players.LocalPlayer :: Player

local TIMER_UPDATE_THRESHOLD = 0.01

local restartTimeMax = 1
local restartDebounce = false
local isRestartKeyHeld = false
local lastDisplayedTimer = -1
local lastRestartProgress = -1

local function loadTower(acronym: string, purist: boolean, resetTimer: boolean): ()
	local state = TowerState()
	if state.currentTower ~= "" then
		LightingManager:ResetLighting()
	end

	TowerState({
		currentTower = acronym,
		towerTimer = 0,
		rushIndex = state.rushIndex,
		rushTotal = state.rushTotal,
		isBoostUsed = false,
		restartProgress = 0,
	})

	if resetTimer then
		HUD.setBoostsUsed(false)
	end

	HUD.setTowerAcronym(acronym)
	ResetEffectGui:Fire()
	restartDebounce = false

	if not purist then
		local coFolder: Instance? = LocalPlayer:WaitForChild("ClientSidedObjects", 10)
		if coFolder then
			ClientObjects.loadClientObjects(coFolder, false, acronym)
		else
			Log({ type = "error", [1] = "Tower load failed: No ClientSidedObjects folder received." })
		end
	end
end

local function unloadTower(): ()
	local state = TowerState()
	if state.currentTower ~= "" then
		LightingManager:ResetLighting()
	end

	TowerState(table.clone(DEFAULT_TOWER_STATE))

	ResetEffectGui:Fire()
	ClientObjects.unloadClientObjects()

	HUD.setTowerAcronym("")
	HUD.setTowerTimer(0)
	HUD.setTowerRush(0, 0)
	HUD.setBoostsUsed(false)
	HUD.setRestartLabel(0)
end

local function correctTimer(time: number): ()
	updateState("towerTimer", time)
end

local function updateTowerRush(index: number, total: number): ()
	TowerState(function(s: TowerStateData): TowerStateData
		local new = table.clone(s)
		new.rushIndex = index
		new.rushTotal = total
		return new
	end)
	HUD.setTowerRush(index, total)
end

local function onCharacterAdded(character: Model): ()
	local humanoid = Character.getHumanoid()
	if not humanoid then
		return
	end

	character.ChildAdded:Connect(function(ins: Instance)
		if ins:IsA("Tool") then
			local boostName = ins:GetAttribute("BoostName") :: string?
			local state = TowerState()
			if boostName and boostName ~= "" and state.currentTower ~= "" then
				updateState("isBoostUsed", true)
				HUD.setBoostsUsed(true)
			end
		end
	end)
end

local function onStep(deltaTime: number): ()
	debug.profilebegin("MTK_ClientStep")

	local state = TowerState()
	local newTimer = state.towerTimer
	local newProgress = state.restartProgress

	if state.currentTower == "" then
		newTimer = 0
		newProgress = 0
	else
		newTimer += deltaTime

		if isRestartKeyHeld and not restartDebounce then
			newProgress = math.min(newProgress + deltaTime / restartTimeMax, 1)
			if newProgress >= 1 then
				restartDebounce = true
				BlinkClient.RestartRequested.Fire()
			end
		elseif not isRestartKeyHeld then
			newProgress = math.max(newProgress - deltaTime / restartTimeMax, 0)
			restartDebounce = false
		end
	end

	-- Single atom write per frame (only if something changed)
	if newTimer ~= state.towerTimer or newProgress ~= state.restartProgress then
		TowerState(function(s: TowerStateData): TowerStateData
			local new = table.clone(s)
			new.towerTimer = newTimer
			new.restartProgress = newProgress
			return new
		end)
	end

	-- Update HUD displays
	if state.currentTower == "" then
		if state.towerTimer ~= 0 then
			HUD.setTowerTimer(0)
			lastDisplayedTimer = 0
		end
	elseif math.abs(newTimer - lastDisplayedTimer) >= TIMER_UPDATE_THRESHOLD then
		HUD.setTowerTimer(newTimer)
		lastDisplayedTimer = newTimer
	end

	if newProgress ~= lastRestartProgress then
		HUD.setRestartLabel(newProgress)
		lastRestartProgress = newProgress
	end

	debug.profileend()
end

local function onInputBegan(input: InputObject, gameProcessed: boolean): ()
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		isRestartKeyHeld = true
	end
end

local function onInputEnded(input: InputObject): ()
	if input.KeyCode == Enum.KeyCode.R then
		isRestartKeyHeld = false
	end
end

do
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

	HUD.showLoadingScreen("Loading data...", false)

	-- Initialize v6 managers
	CharacterManager:Init()
	ClientObjectManager:Init()
	FlipManager:Init()
	GuiManager:Init()
	LightingManager:Init()

	-- Initialize packages
	require("../../../Packages/satchel")
	require("../../shared/conchTypes")

	conch.initiate_default_lifecycle()
	conchui.bind_to(GameConfig.adminHotkey)

	-- Initialize controllers
	chat.init()
	display.init()
	legacyCompat.init()
	allJumps.Start()

	-- Initialize UI modules
	MenuController.Start()

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
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)

	-- Initialize UI state
	HUD.setTowerTimer(0)
	HUD.setTowerAcronym("")
	HUD.setTowerRush(0, 0)

	-- Handle data loading state
	local function applyPlayerSettings(data: any)
		local settings = data and data.settings
		if settings then
			restartTimeMax = settings.quickResetDelay
		end

		-- Update tower sign colors based on completed towers
		display.updateCompletedTowers(data)
	end

	local dataLoaded = LocalPlayer:GetAttribute("DataLoaded")
	if dataLoaded then
		HUD.hideLoadingScreen()
	else
		LocalPlayer:GetAttributeChangedSignal("DataLoaded"):Connect(function()
			local loaded = LocalPlayer:GetAttribute("DataLoaded")
			if loaded == true then
				HUD.hideLoadingScreen()
			end
		end)
	end

	-- Listen for data updates (also fires on initial load)
	BlinkClient.PlayerDataUpdate.On(applyPlayerSettings)
end
