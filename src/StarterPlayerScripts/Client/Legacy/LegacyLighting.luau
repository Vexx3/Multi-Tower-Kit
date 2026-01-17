--[[
	Legacy lighting compatibility for old v5 tower scripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = ReplicatedStorage.Framework
local Kit = Framework.Kit

local LightingManager = require(Kit.Managers.LightingManager)

export type LegacyLightingConfig = { [string]: unknown } | "Default"

local LocalPlayer = Players.LocalPlayer

local LegacyLighting = {}

-- Changes lighting using the v6 LightingManager.
-- Wraps v5 flat config with Type = "Lighting".
local function setLighting(config: LegacyLightingConfig): ()
	LightingManager:ChangeLighting({
		Type = "Lighting",
		Configuration = config,
	} :: any)
end

-- Handles humanoid touch events for legacy v5 lighting configurations.
-- v5 specifically checks for parts named "LightingChanger" with a Configuration ModuleScript.
local function onHumanoidTouched(touchingPart: BasePart, _limb: BasePart)
	if not touchingPart:IsA("BasePart") then
		return
	end

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

-- Sets up touch detection for the character's humanoid.
local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end

	humanoid.Touched:Connect(onHumanoidTouched)
end

--- Initializes the legacy lighting compatibility layer.
--- Sets up _G.setLighting and handles ChangeLighting BindableEvent.
function LegacyLighting.init(): ()
	if LocalPlayer.Character then
		task.spawn(onCharacterAdded, LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

	_G.setLighting = setLighting

	local changeLighting = ReplicatedStorage:FindFirstChild("ChangeLighting")
	if changeLighting and changeLighting:IsA("BindableEvent") then
		changeLighting.Event:Connect(function(config: unknown)
			LightingManager:ChangeLighting(config :: any)
		end)
	end
end

return LegacyLighting
