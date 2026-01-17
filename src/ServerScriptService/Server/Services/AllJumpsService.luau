--[=[
	Handles All Jumps Mode checkpoint storage and teleportation on the server.

	When a player in All Jumps Mode places a checkpoint, the full state is stored here.
	When they take damage that would kill them, PlayerService calls this to teleport
	them back to their checkpoint and restore full state (CFrame, velocity, humanoid state).

	@class AllJumpsService
	@server
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared

local BlinkServer = require("../Network/BlinkServer")
local Types = require(Shared.Types)

-- Checkpoint state type matching Blink struct
export type CheckpointState = {
	CharacterCFrame: CFrame,
	CameraCFrame: CFrame,
	LinearVelocity: Vector3,
	AngularVelocity: Vector3,
	HumanoidState: string,
}

-- Store full checkpoint state per player
local playerCheckpoints: { [string]: CheckpointState } = {}

--- Sets a checkpoint for a player with full state.
--- @param playerInstance Player -- The player setting the checkpoint
--- @param state any -- The full checkpoint state from client
local function onAllJumpsSetCheckpoint(playerInstance: Player, state: any)
	-- Store full state (Blink sends vectors, we keep as-is for sending back)
	playerCheckpoints[playerInstance.Name] = {
		CharacterCFrame = state.CharacterCFrame,
		CameraCFrame = state.CameraCFrame,
		LinearVelocity = Vector3.new(state.LinearVelocity.x, state.LinearVelocity.y, state.LinearVelocity.z),
		AngularVelocity = Vector3.new(state.AngularVelocity.x, state.AngularVelocity.y, state.AngularVelocity.z),
		HumanoidState = state.HumanoidState,
	}
end

--- Removes the checkpoint for a player.
--- @param playerInstance Player -- The player removing the checkpoint
local function onAllJumpsRemoveCheckpoint(playerInstance: Player)
	playerCheckpoints[playerInstance.Name] = nil
end

local AllJumpsService = {}

--- Teleports a player to their checkpoint or tower spawn with full state restoration.
--- Called by PlayerService when health hits 0 in All Jumps Mode.
--- @param player Types.PlayerInfo -- The player info
--- @param tower any -- The tower data with spawnLocation
function AllJumpsService.teleportToCheckpoint(player: Types.PlayerInfo, tower: any)
	local character = player.player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoidRootPart or not humanoid then
		return
	end

	local checkpoint = playerCheckpoints[player.player.Name]

	if checkpoint then
		-- Full state restoration
		humanoidRootPart.CFrame = checkpoint.CharacterCFrame
		humanoidRootPart.AssemblyLinearVelocity = checkpoint.LinearVelocity
		humanoidRootPart.AssemblyAngularVelocity = checkpoint.AngularVelocity

		-- Restore humanoid state
		local stateType = checkpoint.HumanoidState
		if stateType == "Jumping" or stateType == "Seated" then
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		else
			local state = (Enum.HumanoidStateType :: any)[stateType]
			if state then
				humanoid:ChangeState(state)
			end
		end

		-- Tell client to restore camera (can't do server-side)
		BlinkServer.AllJumpsRestoreState.Fire(player.player, {
			CharacterCFrame = checkpoint.CharacterCFrame,
			CameraCFrame = checkpoint.CameraCFrame,
			LinearVelocity = Vector3.new(
				checkpoint.LinearVelocity.X,
				checkpoint.LinearVelocity.Y,
				checkpoint.LinearVelocity.Z
			),
			AngularVelocity = Vector3.new(
				checkpoint.AngularVelocity.X,
				checkpoint.AngularVelocity.Y,
				checkpoint.AngularVelocity.Z
			),
			HumanoidState = checkpoint.HumanoidState,
		})
	else
		-- No checkpoint, teleport to tower spawn
		humanoidRootPart.CFrame = CFrame.new(tower.spawnLocation.Position + Vector3.new(0, 3, 0))
	end
end

--- Clears checkpoint for a player (when leaving All Jumps mode or tower).
--- @param playerName string -- The player's name
function AllJumpsService.clearCheckpoint(playerName: string)
	playerCheckpoints[playerName] = nil
end

--- Initializes the AllJumps service and registers event handlers.
function AllJumpsService.Start()
	BlinkServer.AllJumpsSetCheckpoint.On(onAllJumpsSetCheckpoint)
	BlinkServer.AllJumpsRemoveCheckpoint.On(onAllJumpsRemoveCheckpoint)
end

return AllJumpsService
