--[[
	Bridges legacy speed and jump changes to the v6 Boost HUD.
	
	This module monitors Humanoid children for legacy SpeedBoost/JumpBoost values
	and properties, bridging them to the v6 HUD ONLY for older towers.
]]

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local starterPlayer = game:GetService("StarterPlayer")

local framework = replicatedStorage.Framework

local guiManager = require(framework.Kit.Managers.GuiManager)
local log = require(framework.Log)
local utility = require(framework.Kit.Utility)

local characterUtility = utility.Character
local localPlayer = players.LocalPlayer

local walkSpeedProperty = "WalkSpeed"
local jumpPowerProperty = "JumpPower"
local minimumThreshold = 0.1

local legacyMarkers = {
	Speed = "SpeedBoost",
	Jump = "JumpBoost",
}

local activeBoosts: { [string]: any } = {}
local peakDurations: { [string]: number } = {}
local propertyConnections: { [string]: RBXScriptConnection } = {}
local markerConnections: { [string]: RBXScriptConnection } = {}
local markerValueConnections: { [string]: RBXScriptConnection } = {}

--[[
	Returns the base value for a given humanoid property.
]]
local function getBaseValue(property: string): number
	if property == walkSpeedProperty then
		return starterPlayer.CharacterWalkSpeed
	elseif property == jumpPowerProperty then
		return starterPlayer.CharacterJumpPower
	end

	return 0
end

local function isLegacyTower(): boolean
	-- Check for ClientSidedObjects on the player (MTK v6 standard)
	local co = localPlayer:FindFirstChild("ClientSidedObjects")
	if co then
		return co:GetAttribute("KitVersion") == nil
	end

	-- Check the tower folder as a backup
	local currentTower = localPlayer:GetAttribute("CurrentTower")
	if currentTower then
		local towerFolder = workspace:FindFirstChild(currentTower)
		if towerFolder and towerFolder:IsA("Folder") then
			if towerFolder:GetAttribute("KitVersion") then
				return false
			end
			-- Some towers might have COs inside them
			local coInTower = towerFolder:FindFirstChild("ClientSidedObjects")
			if coInTower then
				return coInTower:GetAttribute("KitVersion") == nil
			end
		end
	end

	-- If we have no info, assume legacy for compatibility (will be re-checked on attribute change)
	return true
end

--[[
	Updates or removes the v6 boost state based on the current property value.
]]
local function updateBoostState(humanoid: Humanoid, property: string)
	local boostCategory = if property == walkSpeedProperty then "Speed" else "Jump"
	local currentPower = (humanoid :: any)[property]
	local baseValue = getBaseValue(property)

	local active = activeBoosts[boostCategory]

	if currentPower > baseValue + minimumThreshold then
		local markerName = legacyMarkers[boostCategory]
		local markerValue = if markerName then humanoid:FindFirstChild(markerName) else nil

		if markerValue and markerValue:IsA("NumberValue") then
			if not markerValueConnections[boostCategory] then
				markerValueConnections[boostCategory] = markerValue:GetPropertyChangedSignal("Value"):Connect(function()
					updateBoostState(humanoid, property)
				end)

				markerValue.Destroying:Once(function()
					if markerValueConnections[boostCategory] then
						markerValueConnections[boostCategory]:Disconnect()
						markerValueConnections[boostCategory] = nil
					end
				end)
			end
		elseif markerValueConnections[boostCategory] then
			markerValueConnections[boostCategory]:Disconnect()
			markerValueConnections[boostCategory] = nil
		end

		local rawDuration = if markerValue and markerValue:IsA("NumberValue") then markerValue.Value else 0
		local duration = math.max(0, rawDuration)
		local isTimed = (markerValue ~= nil)

		-- Immediate exit for timed boosts that reached 0
		if isTimed and duration <= 0 then
			if active then
				characterUtility.removeBoost(active)
				activeBoosts[boostCategory] = nil
				peakDurations[boostCategory] = nil
			end
			return
		end

		if isTimed then
			if not peakDurations[boostCategory] or (duration > peakDurations[boostCategory] + 0.1) then
				peakDurations[boostCategory] = duration
			end
		else
			peakDurations[boostCategory] = 1
		end

		local visualMaxDuration = peakDurations[boostCategory]

		if active then
			active.power = currentPower
			active.multiplier = active.module.GetMultiplier(active)
			active.duration = visualMaxDuration
			active.infinite = not isTimed

			local targetTime = if isTimed then duration else 1
			active.startTime = os.clock() - (visualMaxDuration - targetTime)
			active.timeLeft = targetTime

			local newMode = if isTimed then "Default" else "Pad"
			if active.mode ~= newMode then
				active.mode = newMode
				active.isPad = newMode == "Pad"
				characterUtility.removeBoost(active)

				local newData = {
					isPad = active.isPad,
					startTime = active.startTime,

					mode = newMode,
					type = boostCategory,
					power = currentPower,
					duration = visualMaxDuration,
					timerDecimals = 1,
					hideGUI = false,
					startTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
					endTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),

					module = active.module,

					infinite = not isTimed,
					multiplier = active.multiplier,
					timeLeft = targetTime,
				}
				activeBoosts[boostCategory] = newData
				characterUtility.startBoost(newData)
			else
				guiManager:UpdateBoostFrame(active)
			end
		else
			local boostModule = characterUtility.getBoostModule(boostCategory)
			if not boostModule then
				return
			end

			local newMode = if isTimed then "Default" else "Pad"
			local targetTime = if isTimed then duration else 1
			local newBoost = {
				isPad = newMode == "Pad",
				startTime = os.clock() - (visualMaxDuration - targetTime),

				mode = newMode,
				type = boostCategory,
				power = currentPower,
				duration = visualMaxDuration,
				timerDecimals = 1,
				hideGUI = false,
				startTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
				endTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),

				module = boostModule,

				infinite = not isTimed,
				multiplier = 1,
				timeLeft = targetTime,
			}

			activeBoosts[boostCategory] = newBoost
			characterUtility.startBoost(newBoost)
		end
	elseif active then
		characterUtility.removeBoost(active)
		activeBoosts[boostCategory] = nil
		peakDurations[boostCategory] = nil

		if markerValueConnections[boostCategory] then
			markerValueConnections[boostCategory]:Disconnect()
			markerValueConnections[boostCategory] = nil
		end
	end
end

local function setupHumanoid(humanoid: Humanoid)
	for _, connection in propertyConnections do
		connection:Disconnect()
	end
	for _, connection in markerConnections do
		connection:Disconnect()
	end
	for _, connection in markerValueConnections do
		connection:Disconnect()
	end

	table.clear(propertyConnections)
	table.clear(markerConnections)
	table.clear(markerValueConnections)

	for _, active in activeBoosts do
		characterUtility.removeBoost(active)
	end
	table.clear(activeBoosts)
	table.clear(peakDurations)

	if not isLegacyTower() then
		return
	end

	propertyConnections.WalkSpeed = humanoid:GetPropertyChangedSignal(walkSpeedProperty):Connect(function()
		updateBoostState(humanoid, walkSpeedProperty)
	end)

	propertyConnections.JumpPower = humanoid:GetPropertyChangedSignal(jumpPowerProperty):Connect(function()
		updateBoostState(humanoid, jumpPowerProperty)
	end)

	-- Listen for legacy marker values being added/removed
	markerConnections.ChildAdded = humanoid.ChildAdded:Connect(function(child)
		if child.Name == legacyMarkers.Speed then
			updateBoostState(humanoid, walkSpeedProperty)
		elseif child.Name == legacyMarkers.Jump then
			updateBoostState(humanoid, jumpPowerProperty)
		end
	end)

	markerConnections.ChildRemoved = humanoid.ChildRemoved:Connect(function(child)
		if child.Name == legacyMarkers.Speed then
			updateBoostState(humanoid, walkSpeedProperty)
		elseif child.Name == legacyMarkers.Jump then
			updateBoostState(humanoid, jumpPowerProperty)
		end
	end)

	-- Initial property check
	updateBoostState(humanoid, walkSpeedProperty)
	updateBoostState(humanoid, jumpPowerProperty)
end

local function init()
	localPlayer.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 10)

		if humanoid and humanoid:IsA("Humanoid") then
			setupHumanoid(humanoid)
		end
	end)

	localPlayer:GetAttributeChangedSignal("CurrentTower"):Connect(function()
		local character = localPlayer.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid and humanoid:IsA("Humanoid") then
				setupHumanoid(humanoid)
			end
		end
	end)

	if localPlayer.Character then
		local humanoid = localPlayer.Character:FindFirstChild("Humanoid")

		if humanoid and humanoid:IsA("Humanoid") then
			setupHumanoid(humanoid)
		end
	end

	log({ "Initialized universal LegacyBoostPads bridge." })
end

return {
	init = init,
}
