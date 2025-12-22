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
local StarterPlayer = game:GetService("StarterPlayer")

local Kit = ReplicatedStorage.Framework.Kit
local Packages = ReplicatedStorage.Packages

local CharacterManager = require(Kit.Managers.CharacterManager)
local GuiManager = require(Kit.Managers.GuiManager)
local Janitor = require(Packages.Janitor)

local LocalPlayer = Players.LocalPlayer

type BoostConfig = {
	type: string,
	property: string,
}

type BoostsMap = { [string]: BoostConfig }
type ActiveMap = { [NumberValue]: boolean }

local LEGACY_BOOST_TYPES: BoostsMap = {
	SpeedBoost = { type = "Speed", property = "WalkSpeed" },
	JumpBoost = { type = "Jump", property = "JumpPower" },
}

local trackedBoosts: ActiveMap = {}

local LegacyBoosts = {}

local function startBoost(
	humanoid: Humanoid,
	boostValue: NumberValue,
	boostConfig: BoostConfig,
	boostPower: number?,
	startTime: number?
): number
	local boostModule = CharacterManager:GetBoostModule(boostConfig.type)
	if not boostModule then
		return os.clock()
	end

	local now = os.clock()
	CharacterManager:StartBoost({
		startTime = startTime or now,
		mode = "Default",
		type = boostConfig.type,
		power = boostPower or (humanoid :: any)[boostConfig.property],
		duration = boostValue.Value,
		timerDecimals = 1,
		hideGUI = false,
		startTweenInfo = TweenInfo.new(0),
		endTweenInfo = TweenInfo.new(0.5),
		module = boostModule,
		infinite = false,
		multiplier = 1,
		timeLeft = boostValue.Value,
	})
	return startTime or now
end

local function getDefaultProperty(boostConfig: BoostConfig): number
	if boostConfig.type == "Speed" then
		return StarterPlayer.CharacterWalkSpeed
	elseif boostConfig.type == "Jump" then
		return StarterPlayer.CharacterJumpPower
	end
	return 0
end

local function trackLegacyBoost(humanoid: Humanoid, boostValue: NumberValue, boostName: string): ()
	local boostConfig = LEGACY_BOOST_TYPES[boostName]
	if not boostConfig or trackedBoosts[boostValue] then
		return
	end

	local initialPower = (humanoid :: any)[boostConfig.property]
	local boostStartTime = os.clock()
	local boostDuration = boostValue.Value
	boostStartTime = startBoost(humanoid, boostValue, boostConfig, initialPower, boostStartTime)

	local lastValue: number = boostValue.Value
	local janitor = Janitor.new()

	local function cleanup()
		janitor:Cleanup()
		trackedBoosts[boostValue] = nil
		local activeBoost = CharacterManager:GetActiveBoost(boostConfig.type)
		if activeBoost then
			CharacterManager:RemoveBoost(activeBoost)
		end
	end

	janitor:Add(RunService.Heartbeat:Connect(function()
		if not boostValue or not boostValue.Parent then
			cleanup()
			return
		end

		local now = os.clock()
		local elapsed = now - boostStartTime
		local currentValue: number = boostValue.Value
		local activeBoost = CharacterManager:GetActiveBoost(boostConfig.type)

		if activeBoost then
			local timeLeft = math.max(0, boostDuration - elapsed)
			activeBoost.timeLeft = timeLeft
			activeBoost.duration = boostDuration

			local currentPower = (humanoid :: any)[boostConfig.property]
			activeBoost.power = currentPower

			local defaultValue = getDefaultProperty(boostConfig)
			if defaultValue > 0 then
				activeBoost.multiplier = math.max(currentPower / defaultValue, 0)
			else
				activeBoost.multiplier = 1
			end

			GuiManager:UpdateBoostFrame(activeBoost)
		end

		-- If the boostValue increases (e.g. new boost applied), restart boost
		if currentValue > lastValue + 0.5 then
			boostDuration = currentValue
			boostStartTime = startBoost(humanoid, boostValue, boostConfig, (humanoid :: any)[boostConfig.property], now)
		end
		lastValue = currentValue
	end))

	trackedBoosts[boostValue] = true
	boostValue.Destroying:Once(cleanup)
end

local function onCharacterAdded(character: Model): ()
	for boostValue in pairs(trackedBoosts) do
		if boostValue and boostValue.Parent then
			boostValue:Destroy()
		end
	end

	table.clear(trackedBoosts)

	local humanoid = character:FindFirstChild("Humanoid") or character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end

	for boostName in LEGACY_BOOST_TYPES do
		local existingBoost = humanoid:FindFirstChild(boostName)
		if existingBoost and existingBoost:IsA("NumberValue") then
			trackLegacyBoost(humanoid, existingBoost, boostName)
		end
	end

	humanoid.ChildAdded:Connect(function(child: Instance)
		if child:IsA("NumberValue") and LEGACY_BOOST_TYPES[child.Name] then
			task.defer(function()
				trackLegacyBoost(humanoid, child :: NumberValue, child.Name)
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
