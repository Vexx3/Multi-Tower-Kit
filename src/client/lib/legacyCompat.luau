--[[
	LegacyCompat - Unified legacy compatibility layer for older tower scripts.
	Handles v5 buttons, button-activated platforms, and lighting.
	Merged from LegacyButtons, LegacyButtonPlatforms, LegacyLighting.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LightingManager = require("../../../Framework/Kit/Managers/LightingManager")

local LocalPlayer = Players.LocalPlayer

-- Types
export type ButtonInstance = Model & {
	ClientObject: Instance,
	Pressed: BoolValue,
}

export type LegacyLightingConfig = { [string]: unknown } | "Default"

type ButtonMetatable = {
	__newindex: (self: ButtonTable, key: unknown, value: unknown) -> (),
	__index: (self: ButtonTable, color: Color3 | string) -> { ButtonInstance },
	__call: (self: ButtonTable, mode: string, value: boolean?, color: Color3?) -> { ButtonInstance }?,
}

type ButtonTable = typeof(setmetatable({} :: {}, {} :: ButtonMetatable))

type ConnectionMap = { [Instance]: RBXScriptConnection }

-- State
local bapConnections: ConnectionMap = {}

local legacyCompat = {}

--------------------------------------------------------------------------------
-- BUTTONS (from LegacyButtons)
--------------------------------------------------------------------------------

local function getAllButtons(color: Color3?): { ButtonInstance }
	debug.profilebegin("MTK_GetAllButtons")

	local buttonTable: { ButtonInstance } = {}

	for _, v in workspace:GetDescendants() do
		if v.Name == "Button" and v:FindFirstChild("ClientObject") and v:FindFirstChild("Pressed") then
			local shouldInsert = false

			if color then
				for _, b in v:GetDescendants() do
					if b:IsA("BasePart") and b.Color == color then
						shouldInsert = true
						break
					end
				end
			else
				shouldInsert = true
			end

			if shouldInsert then
				table.insert(buttonTable, v :: ButtonInstance)
			end
		end
	end

	debug.profileend()
	return buttonTable
end

local buttonMt: ButtonMetatable = {} :: ButtonMetatable

function buttonMt:__newindex(_key: unknown, _value: unknown): ()
	-- Prevent modifications to the table
end

function buttonMt:__index(color: Color3 | string): { ButtonInstance }
	if color == "All" then
		return getAllButtons()
	end
	return getAllButtons(color :: Color3)
end

function buttonMt:__call(mode: string, value: boolean?, color: Color3?): { ButtonInstance }?
	if mode == "Get" then
		return getAllButtons()
	elseif mode == "SetAll" then
		for _, button in getAllButtons(color) do
			button.Pressed.Value = value or false
		end
	end
	return nil
end

local function initButtons()
	_G.Buttons = setmetatable({}, buttonMt)
end

--------------------------------------------------------------------------------
-- BUTTON ACTIVATED PLATFORMS (from LegacyButtonPlatforms)
--------------------------------------------------------------------------------

local function setupBapSync(platform: BasePart)
	if bapConnections[platform] then
		return
	end

	platform:SetAttribute("Activated", platform.CanCollide)
	bapConnections[platform] = platform:GetPropertyChangedSignal("CanCollide"):Connect(function()
		platform:SetAttribute("Activated", platform.CanCollide)
	end)
end

local function isBap(part: BasePart): boolean
	return part.Name == "ButtonActivatedPlatform" or part:FindFirstChild("ButtonActivated") ~= nil
end

local function monitorBapFolder(folder: Instance)
	for _, desc in folder:GetDescendants() do
		if desc:IsA("BasePart") and isBap(desc) then
			setupBapSync(desc)
		end
	end

	folder.DescendantAdded:Connect(function(desc: Instance)
		if desc:IsA("BasePart") and isBap(desc) then
			task.defer(setupBapSync, desc)
		end
	end)

	folder.DescendantRemoving:Connect(function(desc: Instance)
		local conn = bapConnections[desc]
		if conn then
			conn:Disconnect()
			bapConnections[desc] = nil
		end
	end)
end

local function initButtonPlatforms()
	workspace.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Folder") and child:GetAttribute("KitVersion") == nil then
			monitorBapFolder(child)
		end
	end)

	for _, child in workspace:GetChildren() do
		if child:IsA("Folder") and child:GetAttribute("KitVersion") == nil then
			monitorBapFolder(child)
		end
	end
end

--------------------------------------------------------------------------------
-- LIGHTING (from LegacyLighting)
--------------------------------------------------------------------------------

local function setLighting(config: LegacyLightingConfig)
	LightingManager:ChangeLighting({
		Type = "Lighting",
		Configuration = config,
	} :: any)
end

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

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end

	humanoid.Touched:Connect(onHumanoidTouched)
end

local function initLighting()
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

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

--- Initializes all legacy compatibility layers.
function legacyCompat.init()
	initButtons()
	initButtonPlatforms()
	initLighting()
end

return legacyCompat
