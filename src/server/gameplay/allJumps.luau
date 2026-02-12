--[[
	All Jumps Mode checkpoint storage and teleportation.
	Stores checkpoint state per player and restores it when they take fatal damage.
]]

local BlinkServer = require("../Network/BlinkServer")

local playerCheckpoints = {}

local allJumps = {}

--- Sets a checkpoint for a player with full state.
function allJumps.setCheckpoint(playerName: string, state: any)
	playerCheckpoints[playerName] = {
		CharacterCFrame = state.CharacterCFrame,
		CameraCFrame = state.CameraCFrame,
		LinearVelocity = Vector3.new(state.LinearVelocity.x, state.LinearVelocity.y, state.LinearVelocity.z),
		AngularVelocity = Vector3.new(state.AngularVelocity.x, state.AngularVelocity.y, state.AngularVelocity.z),
		HumanoidState = state.HumanoidState,
	}
end

--- Removes the checkpoint for a player.
function allJumps.removeCheckpoint(playerName: string)
	playerCheckpoints[playerName] = nil
end

--- Clears checkpoint for a player.
function allJumps.clearCheckpoint(playerName: string)
	playerCheckpoints[playerName] = nil
end

--- Gets the checkpoint for a player.
function allJumps.getCheckpoint(playerName: string)
	return playerCheckpoints[playerName]
end

--- Teleports a player to their checkpoint or tower spawn with full state restoration.
function allJumps.teleportToCheckpoint(player: any, tower: any)
	local character = player.player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoidRootPart or not humanoid then
		return
	end

	local checkpoint = playerCheckpoints[player.player.Name]

	if checkpoint then
		humanoidRootPart.CFrame = checkpoint.CharacterCFrame
		humanoidRootPart.AssemblyLinearVelocity = checkpoint.LinearVelocity
		humanoidRootPart.AssemblyAngularVelocity = checkpoint.AngularVelocity

		local stateType = checkpoint.HumanoidState
		if stateType == "Jumping" or stateType == "Seated" then
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		else
			local state = (Enum.HumanoidStateType :: any)[stateType]
			if state then
				humanoid:ChangeState(state)
			end
		end

		BlinkServer.AllJumpsRestoreState.Fire(player.player, {
			CharacterCFrame = checkpoint.CharacterCFrame,
			CameraCFrame = checkpoint.CameraCFrame,
			LinearVelocity = checkpoint.LinearVelocity,
			AngularVelocity = checkpoint.AngularVelocity,
			HumanoidState = checkpoint.HumanoidState,
		})
	else
		humanoidRootPart.CFrame = CFrame.new(tower.spawnLocation.Position + Vector3.new(0, 3, 0))
	end
end

--- Registers Blink event handlers for checkpoint management.
function allJumps.init()
	BlinkServer.AllJumpsSetCheckpoint.On(function(playerInstance: Player, state: any)
		allJumps.setCheckpoint(playerInstance.Name, state)
	end)

	BlinkServer.AllJumpsRemoveCheckpoint.On(function(playerInstance: Player)
		allJumps.removeCheckpoint(playerInstance.Name)
	end)
end

return allJumps
