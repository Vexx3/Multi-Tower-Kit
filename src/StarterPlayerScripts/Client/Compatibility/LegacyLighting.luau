-- Licensed under the MIT License
-- Copyright (c) 2025 Zylx

--[=[
	Legacy lighting compatibility layer for old v5 tower scripts.
	
	Handles:
	- Parts named "LightingChanger" with Configuration ModuleScript children
	- _G.SetLighting global function for manual lighting changes
	- ChangeLighting BindableEvent for remote lighting changes

	This script automatically hooks into the local player's humanoid touch events
	so you don't need to edit the CharacterManager script.

	@class LegacyLighting
	@client
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = ReplicatedStorage.Framework
local Kit = Framework.Kit

local LightingManager = require(Kit.Managers.LightingManager)

export type LegacyLightingConfig = { [string]: any } | "Default"

local LocalPlayer = Players.LocalPlayer

--[=[
	Changes lighting using the v6 LightingManager.
	Wraps v5 flat config with Type = "Lighting".
]=]
local function setLighting(config: LegacyLightingConfig): ()
	LightingManager:ChangeLighting({
		Type = "Lighting",
		Configuration = config,
	} :: any)
end

--[=[
	Handles humanoid touch events for legacy v5 lighting configurations.
	v5 specifically checks for parts named "LightingChanger" with a Configuration ModuleScript.
]=]
local function onHumanoidTouched(touchingPart: BasePart, _limb: BasePart)
	if not touchingPart:IsA("BasePart") then
		return
	end

	-- v5 specifically checks for "LightingChanger" named parts
	if touchingPart.Name ~= "LightingChanger" then
		return
	end

	local configuration = touchingPart:FindFirstChild("Configuration")
	if configuration and configuration:IsA("ModuleScript") then
		local success, config = pcall(require, configuration)
		if success and config then
			setLighting(config)
		end
	end
end

--[=[
	Sets up touch detection for the character's humanoid.
]=]
local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end

	humanoid.Touched:Connect(onHumanoidTouched)
end

local LegacyLighting = {}

function LegacyLighting.Init(): ()
	if LocalPlayer.Character then
		task.spawn(onCharacterAdded, LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

	_G.SetLighting = setLighting

	local changeLighting = ReplicatedStorage:FindFirstChild("ChangeLighting")
	if changeLighting and changeLighting:IsA("BindableEvent") then
		changeLighting.Event:Connect(function(config: any)
			LightingManager:ChangeLighting(config)
		end)
	end
end

return LegacyLighting
