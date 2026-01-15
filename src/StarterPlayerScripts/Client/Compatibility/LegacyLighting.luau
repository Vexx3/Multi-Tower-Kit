--[=[
	Legacy lighting compatibility layer for old v5 tower scripts.
	
	@class LegacyLighting
	@client
]=]

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local framework = replicatedStorage.Framework
local kit = framework.Kit

local lightingManager = require(kit.Managers.LightingManager)

export type LegacyLightingConfig = { [string]: unknown } | "Default"

local localPlayer = players.LocalPlayer

--[=[
	Changes lighting using the v6 LightingManager.
	Wraps v5 flat config with Type = "Lighting".
]=]
local function setLighting(config: LegacyLightingConfig): ()
	lightingManager:ChangeLighting({
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

local function init(): ()
	if localPlayer.Character then
		task.spawn(onCharacterAdded, localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(onCharacterAdded)

	_G.setLighting = setLighting

	local changeLighting = replicatedStorage:FindFirstChild("ChangeLighting")
	if changeLighting and changeLighting:IsA("BindableEvent") then
		changeLighting.Event:Connect(function(config: unknown)
			lightingManager:ChangeLighting(config :: any)
		end)
	end
end

return {
	init = init,
}
