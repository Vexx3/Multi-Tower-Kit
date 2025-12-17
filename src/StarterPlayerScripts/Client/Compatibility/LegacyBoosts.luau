--!strict
-- Licensed under the MIT License
-- Copyright (c) 2025 Zylx

--[=[
	Legacy boost compatibility for v5 speed/jump boosters.
	
	v5 boosters create NumberValue children on Humanoid (SpeedBoost, JumpBoost)
	and tween the humanoid properties directly.
	
	This script detects those NumberValues and uses CharacterManager's
	StartBoost with the real v6 "Speed"/"Jump" boost types.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Framework = ReplicatedStorage.Framework
local Kit = Framework.Kit

local CharacterManager = require(Kit.Managers.CharacterManager)

local LocalPlayer = Players.LocalPlayer

-- Map v5 NumberValue names to v6 boost types
local LEGACY_BOOST_CONFIG = {
	SpeedBoost = {
		type = "Speed", -- v6 boost type
		property = "WalkSpeed",
	},
	JumpBoost = {
		type = "Jump", -- v6 boost type
		property = "JumpPower",
	},
}

type TrackedBoost = {
	lastValue: number,
	connection: RBXScriptConnection?,
	power: number?, -- cached power from first touch
}

local activeBoosts: { [NumberValue]: TrackedBoost } = {}

local LegacyBoosts = {}

--[=[
	Starts or refreshes a v6 boost based on v5 NumberValue.
]=]
local function triggerBoost(
	humanoid: Humanoid,
	valueInstance: NumberValue,
	config: typeof(LEGACY_BOOST_CONFIG.SpeedBoost),
	cachedPower: number?
): ()
	local boostModule = CharacterManager:GetBoostModule(config.type)
	if not boostModule then
		return
	end

	-- Use cached power if available, otherwise read from humanoid
	-- We cache power because v5 tweens the property and we might read mid-tween
	local power = cachedPower or (humanoid :: any)[config.property]
	local duration = valueInstance.Value

	local boostData = {
		startTime = os.clock(),
		mode = "Default",
		type = config.type,
		power = power,
		duration = duration,
		timerDecimals = 1,
		hideGUI = false,
		startTweenInfo = TweenInfo.new(0),
		endTweenInfo = TweenInfo.new(0.5),
		module = boostModule,
		infinite = false,
		multiplier = 1,
		timeLeft = duration,
	}

	CharacterManager:StartBoost(boostData)
end

--[=[
	Handles a legacy v5 boost NumberValue being added to humanoid.
]=]
local function onLegacyBoostAdded(humanoid: Humanoid, valueInstance: NumberValue, boostName: string): ()
	local config = LEGACY_BOOST_CONFIG[boostName]
	if not config then
		return
	end

	-- Already tracking this NumberValue - refresh will be handled by the Heartbeat loop
	if activeBoosts[valueInstance] then
		return
	end

	-- Wait a moment for v5 tween to reach target value
	task.wait(0.1)

	-- Get power after short delay (v5 uses 0.5s tween, but we get close enough)
	local power = (humanoid :: any)[config.property]

	-- Trigger initial boost with power
	triggerBoost(humanoid, valueInstance, config, power)

	local tracked: TrackedBoost = {
		lastValue = valueInstance.Value,
		connection = nil,
		power = power, -- cache for refresh
	}

	-- Cleanup function to avoid duplication
	local cleanedUp = false
	local function cleanup()
		if cleanedUp then
			return
		end
		cleanedUp = true

		if tracked.connection then
			tracked.connection:Disconnect()
			tracked.connection = nil
		end
		activeBoosts[valueInstance] = nil

		-- Remove the v6 boost from CharacterManager
		local activeBoost = CharacterManager:GetActiveBoost(config.type)
		if activeBoost then
			CharacterManager:RemoveBoost(activeBoost)
		end
	end

	-- Watch for value changes (v5 refreshes by setting value back up)
	tracked.connection = RunService.Heartbeat:Connect(function()
		   if not valueInstance or not valueInstance.Parent then
			   -- NumberValue gone, clean up
			   cleanup()
			   return
		   end

		   local currentValue = valueInstance.Value

		   -- Sync v6 boost timer to v5 NumberValue
		   local activeBoost = CharacterManager:GetActiveBoost(config.type)
		   if activeBoost then
			   activeBoost.timeLeft = currentValue
			   activeBoost.duration = currentValue
			   -- Update the GUI immediately
			   local GuiManager = require(Kit.Managers.GuiManager)
			   GuiManager:UpdateBoostFrame(activeBoost)
		   end

		   -- If value jumped up significantly, v5 refreshed the boost
		   if currentValue > tracked.lastValue + 0.5 then
			   -- Use cached power to avoid reading mid-tween
			   triggerBoost(humanoid, valueInstance, config, tracked.power)
		   end

		   tracked.lastValue = currentValue
	end)

	activeBoosts[valueInstance] = tracked

	-- Clean up when destroyed (e.g. by v5 remover parts)
	valueInstance.Destroying:Once(cleanup)
end

--[=[
	Sets up monitoring for a character's humanoid.
]=]
local function onCharacterAdded(character: Model): ()
	-- Clear any leftover tracked boosts from previous character
	for _, tracked in activeBoosts do
		if tracked.connection then
			tracked.connection:Disconnect()
		end
	end
	table.clear(activeBoosts)

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end

	-- Check for existing boosts (in case script loads after booster touched)
	for boostName in LEGACY_BOOST_CONFIG do
		local existing = humanoid:FindFirstChild(boostName)
		if existing and existing:IsA("NumberValue") then
			onLegacyBoostAdded(humanoid, existing, boostName)
		end
	end

	-- Watch for new boosts being created by v5 scripts
	humanoid.ChildAdded:Connect(function(child)
		if child:IsA("NumberValue") and LEGACY_BOOST_CONFIG[child.Name] then
			-- Small delay to let v5 script set up the humanoid property first
			task.defer(function()
				onLegacyBoostAdded(humanoid, child, child.Name)
			end)
		end
	end)
end

function LegacyBoosts.Init(): ()
	if LocalPlayer.Character then
		task.spawn(onCharacterAdded, LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

return LegacyBoosts
