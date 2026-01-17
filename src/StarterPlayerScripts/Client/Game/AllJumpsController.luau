--[=[
    Handles All Jumps Mode checkpoint placement and state restoration.
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

-- Config
local INPUT_BINDINGS: { [Enum.KeyCode]: ActionName } = {
	[Enum.KeyCode.Z] = "place",
	[Enum.KeyCode.X] = "remove",
	[Enum.KeyCode.R] = "teleport",
}

local VISUAL_SETTINGS = {
	Transparency = 0.5,
	Size = Vector3.new(2, 2, 1),
	Color = BrickColor.White(),
}

-- State
local activeStates: { [number]: CheckpointState } = {}
local isAllJumpsActive = false
local currentTowerAcronym = ""
local character = LocalPlayer.Character

local checkpointFolder = workspace:FindFirstChild("AllJumpsHandler") :: Folder
if not checkpointFolder then
	checkpointFolder = Instance.new("Folder")
	checkpointFolder.Name = "AllJumpsHandler"
	checkpointFolder.Parent = workspace
end

--- Retrieves the current player's physical and state data.
local function captureCurrentState(): (BasePart?, Humanoid?, CheckpointState?)
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
local function createCheckpoint(): number?
	if not isAllJumpsActive or currentTowerAcronym == "" then
		return nil
	end

	local root, _, state = captureCurrentState()
	if not root or not state then
		return nil
	end

	local id = #activeStates + 1
	activeStates[id] = state

	local visual = Instance.new("Part")
	visual.Name = tostring(id)
	visual.Size = VISUAL_SETTINGS.Size
	visual.BrickColor = VISUAL_SETTINGS.Color
	visual.Transparency = VISUAL_SETTINGS.Transparency
	visual.Material = Enum.Material.Neon
	visual.Anchored = true
	visual.CanCollide = false
	visual.CanQuery = false
	visual.CanTouch = false
	visual:PivotTo(state.CharacterCFrame)
	visual.Parent = checkpointFolder

	BlinkClient.AllJumpsSetCheckpoint.Fire(state)

	return id
end

--- Removes the most recently placed checkpoint.
local function removeLastCheckpoint(): ()
	local id = #activeStates
	if id == 0 then
		return
	end

	local visual = checkpointFolder:FindFirstChild(tostring(id))
	if visual then
		visual:Destroy()
	end

	activeStates[id] = nil
	BlinkClient.AllJumpsRemoveCheckpoint.Fire()
end

--- Restores the player to a previous checkpoint state.
local function teleportToCheckpoint(index: number?): ()
	local root, humanoid, _ = captureCurrentState()
	local targetIndex = index or #activeStates
	local state = activeStates[targetIndex]

	if not state or not root or not humanoid or not currentCamera then
		return
	end

	currentCamera.CFrame = state.CameraCFrame
	root.CFrame = state.CharacterCFrame
	root.AssemblyLinearVelocity = state.LinearVelocity
	root.AssemblyAngularVelocity = state.AngularVelocity

	-- Attempt to restore humanoid state, defaulting to Freefall if Jumping to prevent physics glitches
	local stateEnum: any = (Enum.HumanoidStateType :: any)[state.HumanoidState]
	if stateEnum then
		if stateEnum == Enum.HumanoidStateType.Jumping then
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		else
			humanoid:ChangeState(stateEnum)
		end
	end
end

--- Clears all local checkpoints and optional server state.
local function clearAllCheckpoints(requestServerRestart: boolean?): ()
	checkpointFolder:ClearAllChildren()
	table.clear(activeStates)

	if requestServerRestart then
		BlinkClient.RestartRequested.Fire()
	end
end

local AllJumpsController = {}

--- Initialize listeners for All Jumps Mode.
function AllJumpsController.Start(): ()
	LocalPlayer.CharacterAdded:Connect(function(char)
		character = char
		if isAllJumpsActive and currentTowerAcronym ~= "" then
			task.wait(0.25)
			teleportToCheckpoint()
		end
	end)

	BlinkClient.AllJumpsRestoreState.On(function(state: CheckpointState)
		if isAllJumpsActive and currentTowerAcronym ~= "" and currentCamera then
			currentCamera.CFrame = state.CameraCFrame
		end
	end)

	BlinkClient.LoadTower.On(function(acronym: string, _purist: boolean, isRestart: boolean)
		if isRestart then
			clearAllCheckpoints()
		end
		currentTowerAcronym = acronym
	end)

	BlinkClient.UnloadTower.On(function()
		currentTowerAcronym = ""
	end)

	LocalPlayer:GetAttributeChangedSignal("AllJumpsMode"):Connect(function()
		isAllJumpsActive = LocalPlayer:GetAttribute("AllJumpsMode") == true
		if not isAllJumpsActive then
			clearAllCheckpoints()
		end
	end)

	isAllJumpsActive = LocalPlayer:GetAttribute("AllJumpsMode") == true

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not isAllJumpsActive or currentTowerAcronym == "" then
			return
		end

		local action = INPUT_BINDINGS[input.KeyCode]
		if action == "place" then
			createCheckpoint()
		elseif action == "remove" then
			removeLastCheckpoint()
		elseif action == "teleport" then
			teleportToCheckpoint()
		end
	end)
end

-- Public API
function AllJumpsController.Place(): number?
	return createCheckpoint()
end

function AllJumpsController.Remove(): ()
	removeLastCheckpoint()
end

function AllJumpsController.Teleport(index: number?): ()
	teleportToCheckpoint(index)
end

function AllJumpsController.Reset(restart: boolean?): ()
	clearAllCheckpoints(restart)
end

function AllJumpsController.IsActive(): boolean
	return isAllJumpsActive
end

function AllJumpsController.GetCheckpointCount(): number
	return #activeStates
end

return AllJumpsController
