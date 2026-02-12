--[=[
	AllJumpsController - Handles All Jumps Mode checkpoint placement and state restoration.
	Uses OOP Checkpoint class for cleaner state management.
	@class allJumps
	@client
]=]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local BlinkClient = require("../../shared/Network/BlinkClient")

local LocalPlayer = Players.LocalPlayer :: Player
local currentCamera = workspace.CurrentCamera

export type CheckpointState = {
	CharacterCFrame: CFrame,
	CameraCFrame: CFrame,
	LinearVelocity: Vector3,
	AngularVelocity: Vector3,
	HumanoidState: string,
}

type ActionName = "place" | "remove" | "teleport"

local INPUT_BINDINGS: { [Enum.KeyCode]: ActionName } = {
	[Enum.KeyCode.Z] = "place",
	[Enum.KeyCode.X] = "remove",
	[Enum.KeyCode.R] = "teleport",
}

type CheckpointData = {
	id: number,
	state: CheckpointState,
	visual: BasePart,
	destroy: (self: CheckpointData) -> (),
}

--------------------------------------------------------------------------------
-- Checkpoint class
--------------------------------------------------------------------------------

local Checkpoint = {}
Checkpoint.__index = Checkpoint

Checkpoint.VISUAL_SETTINGS = {
	Transparency = 0.5,
	Size = Vector3.new(2, 2, 1),
	Color = BrickColor.White(),
}

function Checkpoint.new(id: number, state: CheckpointState, parent: Instance): CheckpointData
	local self = setmetatable({}, Checkpoint)
	self.id = id
	self.state = state
	self.visual = Checkpoint._createVisual(id, state.CharacterCFrame, parent)
	return (self :: any) :: CheckpointData
end

function Checkpoint._createVisual(id: number, cframe: CFrame, parent: Instance): BasePart
	local visual = Instance.new("Part")
	visual.Name = tostring(id)
	visual.Size = Checkpoint.VISUAL_SETTINGS.Size
	visual.BrickColor = Checkpoint.VISUAL_SETTINGS.Color
	visual.Transparency = Checkpoint.VISUAL_SETTINGS.Transparency
	visual.Material = Enum.Material.Neon
	visual.Anchored = true
	visual.CanCollide = false
	visual.CanQuery = false
	visual.CanTouch = false
	visual:PivotTo(cframe)
	visual.Parent = parent
	return visual
end

function Checkpoint:destroy()
	if self.visual then
		self.visual:Destroy()
	end
end

--------------------------------------------------------------------------------
-- allJumps
--------------------------------------------------------------------------------

local allJumps = {}
allJumps._checkpoints = {} :: { CheckpointData }
allJumps._isActive = false
allJumps._currentTower = ""
allJumps._character = LocalPlayer.Character
allJumps._folder = nil :: Folder?

local function getOrCreateFolder(): Folder
	if allJumps._folder then
		return allJumps._folder
	end

	local existing = workspace:FindFirstChild("AllJumpsHandler")
	if existing and existing:IsA("Folder") then
		allJumps._folder = existing
	else
		local newFolder = Instance.new("Folder")
		newFolder.Name = "AllJumpsHandler"
		newFolder.Parent = workspace
		allJumps._folder = newFolder
	end

	return allJumps._folder :: any
end

local function captureCurrentState(): (BasePart?, Humanoid?, CheckpointState?)
	local character = allJumps._character
	if not character then
		return nil, nil, nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid or not currentCamera then
		return nil, nil, nil
	end

	local state: CheckpointState = {
		CharacterCFrame = rootPart.CFrame,
		CameraCFrame = currentCamera.CFrame,
		LinearVelocity = rootPart.AssemblyLinearVelocity,
		AngularVelocity = rootPart.AssemblyAngularVelocity,
		HumanoidState = humanoid:GetState().Name,
	}

	return rootPart, humanoid, state
end

--- Creates a new checkpoint at the player's current position.
function allJumps.Place(): number?
	if not allJumps._isActive or allJumps._currentTower == "" then
		return nil
	end

	local root, _, state = captureCurrentState()
	if not root or not state then
		return nil
	end

	local id = #allJumps._checkpoints + 1
	local checkpoint = Checkpoint.new(id, state, getOrCreateFolder())
	table.insert(allJumps._checkpoints, checkpoint)

	BlinkClient.AllJumpsSetCheckpoint.Fire(state)
	return id
end

--- Removes the most recently placed checkpoint.
function allJumps.Remove()
	local checkpoints = allJumps._checkpoints
	local lastIndex = #checkpoints
	if lastIndex == 0 then
		return
	end

	local checkpoint = checkpoints[lastIndex]
	checkpoint:destroy()
	checkpoints[lastIndex] = nil

	BlinkClient.AllJumpsRemoveCheckpoint.Fire()
end

--- Teleports to a checkpoint by index (defaults to last).
function allJumps.Teleport(index: number?)
	local root, humanoid, _ = captureCurrentState()
	local targetIndex = index or #allJumps._checkpoints
	local checkpoint = allJumps._checkpoints[targetIndex]

	if not checkpoint or not root or not humanoid or not currentCamera then
		return
	end

	local state = checkpoint.state
	currentCamera.CFrame = state.CameraCFrame
	root.CFrame = state.CharacterCFrame
	root.AssemblyLinearVelocity = state.LinearVelocity
	root.AssemblyAngularVelocity = state.AngularVelocity

	local stateEnum: any = (Enum.HumanoidStateType :: any)[state.HumanoidState]
	if stateEnum then
		if stateEnum == Enum.HumanoidStateType.Jumping then
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		else
			humanoid:ChangeState(stateEnum)
		end
	end
end

--- Clears all checkpoints.
function allJumps.Reset(requestServerRestart: boolean?)
	for _, checkpoint in allJumps._checkpoints do
		checkpoint:destroy()
	end
	table.clear(allJumps._checkpoints)

	if requestServerRestart then
		BlinkClient.RestartRequested.Fire()
	end
end

function allJumps.IsActive(): boolean
	return allJumps._isActive
end

function allJumps.GetCheckpointCount(): number
	return #allJumps._checkpoints
end

--- Initializes the controller.
function allJumps.Start()
	LocalPlayer.CharacterAdded:Connect(function(char)
		allJumps._character = char
		local currentTowerAttr = LocalPlayer:GetAttribute("CurrentTower")
		if allJumps._isActive and allJumps._currentTower ~= "" and currentTowerAttr and currentTowerAttr ~= "" then
			task.wait(0.25)
			allJumps.Teleport()
		end
	end)

	BlinkClient.AllJumpsRestoreState.On(function(state: CheckpointState)
		if allJumps._isActive and allJumps._currentTower ~= "" and currentCamera then
			currentCamera.CFrame = state.CameraCFrame
		end
	end)

	BlinkClient.LoadTower.On(function(acronym: string, _purist: boolean, isRestart: boolean)
		if isRestart then
			allJumps.Reset()
		end
		allJumps._currentTower = acronym
	end)

	BlinkClient.UnloadTower.On(function()
		allJumps._currentTower = ""
		allJumps.Reset()
	end)

	LocalPlayer:GetAttributeChangedSignal("AllJumpsMode"):Connect(function()
		allJumps._isActive = LocalPlayer:GetAttribute("AllJumpsMode") == true
		if not allJumps._isActive then
			allJumps.Reset()
		end
	end)

	allJumps._isActive = LocalPlayer:GetAttribute("AllJumpsMode") == true

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not allJumps._isActive or allJumps._currentTower == "" then
			return
		end

		local action = INPUT_BINDINGS[input.KeyCode]
		if action == "place" then
			allJumps.Place()
		elseif action == "remove" then
			allJumps.Remove()
		elseif action == "teleport" then
			allJumps.Teleport()
		end
	end)
end

return allJumps
