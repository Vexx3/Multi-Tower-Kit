--[=[
	AllJumpsController - Handles All Jumps Mode checkpoint placement and state restoration.
	Uses OOP Checkpoint class for cleaner state management.
	@class AllJumpsController
	@client
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local TowerGame = ReplicatedStorage.TowerGame

local BlinkClient = require(TowerGame.Network.BlinkClient)

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
-- AllJumpsController
--------------------------------------------------------------------------------

local AllJumpsController = {}
AllJumpsController._checkpoints = {} :: { CheckpointData }
AllJumpsController._isActive = false
AllJumpsController._currentTower = ""
AllJumpsController._character = LocalPlayer.Character
AllJumpsController._folder = nil :: Folder?

local function getOrCreateFolder(): Folder
	if AllJumpsController._folder then
		return AllJumpsController._folder
	end

	local existing = workspace:FindFirstChild("AllJumpsHandler")
	if existing and existing:IsA("Folder") then
		AllJumpsController._folder = existing
	else
		local newFolder = Instance.new("Folder")
		newFolder.Name = "AllJumpsHandler"
		newFolder.Parent = workspace
		AllJumpsController._folder = newFolder
	end

	return AllJumpsController._folder :: any
end

local function captureCurrentState(): (BasePart?, Humanoid?, CheckpointState?)
	local character = AllJumpsController._character
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
function AllJumpsController.Place(): number?
	if not AllJumpsController._isActive or AllJumpsController._currentTower == "" then
		return nil
	end

	local root, _, state = captureCurrentState()
	if not root or not state then
		return nil
	end

	local id = #AllJumpsController._checkpoints + 1
	local checkpoint = Checkpoint.new(id, state, getOrCreateFolder())
	table.insert(AllJumpsController._checkpoints, checkpoint)

	BlinkClient.AllJumpsSetCheckpoint.Fire(state)
	return id
end

--- Removes the most recently placed checkpoint.
function AllJumpsController.Remove()
	local checkpoints = AllJumpsController._checkpoints
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
function AllJumpsController.Teleport(index: number?)
	local root, humanoid, _ = captureCurrentState()
	local targetIndex = index or #AllJumpsController._checkpoints
	local checkpoint = AllJumpsController._checkpoints[targetIndex]

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
function AllJumpsController.Reset(requestServerRestart: boolean?)
	for _, checkpoint in AllJumpsController._checkpoints do
		checkpoint:destroy()
	end
	table.clear(AllJumpsController._checkpoints)

	if requestServerRestart then
		BlinkClient.RestartRequested.Fire()
	end
end

function AllJumpsController.IsActive(): boolean
	return AllJumpsController._isActive
end

function AllJumpsController.GetCheckpointCount(): number
	return #AllJumpsController._checkpoints
end

--- Initializes the controller.
function AllJumpsController.Start()
	LocalPlayer.CharacterAdded:Connect(function(char)
		AllJumpsController._character = char
		local currentTowerAttr = LocalPlayer:GetAttribute("CurrentTower")
		if
			AllJumpsController._isActive
			and AllJumpsController._currentTower ~= ""
			and currentTowerAttr
			and currentTowerAttr ~= ""
		then
			task.wait(0.25)
			AllJumpsController.Teleport()
		end
	end)

	BlinkClient.AllJumpsRestoreState.On(function(state: CheckpointState)
		if AllJumpsController._isActive and AllJumpsController._currentTower ~= "" and currentCamera then
			currentCamera.CFrame = state.CameraCFrame
		end
	end)

	BlinkClient.LoadTower.On(function(acronym: string, _purist: boolean, isRestart: boolean)
		if isRestart then
			AllJumpsController.Reset()
		end
		AllJumpsController._currentTower = acronym
	end)

	BlinkClient.UnloadTower.On(function()
		AllJumpsController._currentTower = ""
		AllJumpsController.Reset()
	end)

	LocalPlayer:GetAttributeChangedSignal("AllJumpsMode"):Connect(function()
		AllJumpsController._isActive = LocalPlayer:GetAttribute("AllJumpsMode") == true
		if not AllJumpsController._isActive then
			AllJumpsController.Reset()
		end
	end)

	AllJumpsController._isActive = LocalPlayer:GetAttribute("AllJumpsMode") == true

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not AllJumpsController._isActive or AllJumpsController._currentTower == "" then
			return
		end

		local action = INPUT_BINDINGS[input.KeyCode]
		if action == "place" then
			AllJumpsController.Place()
		elseif action == "remove" then
			AllJumpsController.Remove()
		elseif action == "teleport" then
			AllJumpsController.Teleport()
		end
	end)
end

return AllJumpsController
