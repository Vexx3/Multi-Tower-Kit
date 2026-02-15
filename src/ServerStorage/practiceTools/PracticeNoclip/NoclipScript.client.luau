-- Practice Noclip — based on the studio Noclip tool by funwolf7 / bLockerman666,
-- with tower boundary clamping so the player can't fly outside their current tower.

local tool = script.Parent

local keys: { [string]: Enum.KeyCode } = {
	UpButton = Enum.KeyCode.Space,
	DownButton = Enum.KeyCode.LeftControl,
	SpeedUpButton = Enum.KeyCode.E,
	SpeedDownButton = Enum.KeyCode.Q,
	SpeedResetButton = Enum.KeyCode.R,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
local controlModule = playerModule:GetControls()

local TOWERS = workspace:WaitForChild("Towers") :: Folder
local BOUNDARY_PADDING = 30 -- studs of extra room beyond the tower bounding box

local equipped = false
local connection = nil
local hrpPivot

local defaultSpeed = tool:FindFirstChild("Speed") and tool.Speed.Value or 60
local speed = 0

---------------------------------------------------------------------------
-- Tower boundary helpers
---------------------------------------------------------------------------

type Bounds = { min: Vector3, max: Vector3 }
local cachedBounds: { [string]: Bounds } = {}

--- Compute the axis-aligned bounding box of every BasePart in a container.
local function computeBoundingBox(container: Instance): Bounds?
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	local found = false

	for _, desc in container:GetDescendants() do
		if not desc:IsA("BasePart") then
			continue
		end

		found = true
		local cf = desc.CFrame
		local size = desc.Size

		for _, sx in { -0.5, 0.5 } do
			for _, sy in { -0.5, 0.5 } do
				for _, sz in { -0.5, 0.5 } do
					local corner = cf:PointToWorldSpace(size * Vector3.new(sx, sy, sz))
					minX = math.min(minX, corner.X)
					minY = math.min(minY, corner.Y)
					minZ = math.min(minZ, corner.Z)
					maxX = math.max(maxX, corner.X)
					maxY = math.max(maxY, corner.Y)
					maxZ = math.max(maxZ, corner.Z)
				end
			end
		end
	end

	if not found then
		return nil
	end

	return {
		min = Vector3.new(minX, minY, minZ),
		max = Vector3.new(maxX, maxY, maxZ),
	}
end

local function getTowerBounds(acronym: string): Bounds?
	local cached = cachedBounds[acronym]
	if cached then
		return cached
	end

	local towerFolder = TOWERS:FindFirstChild(acronym)
	if not towerFolder then
		return nil
	end

	local bounds = computeBoundingBox(towerFolder)
	if not bounds then
		return nil
	end

	local pad = Vector3.new(BOUNDARY_PADDING, BOUNDARY_PADDING, BOUNDARY_PADDING)
	bounds = {
		min = bounds.min - pad,
		max = bounds.max + pad,
	}

	cachedBounds[acronym] = bounds
	return bounds
end

--- Returns the acronym of the tower the player is currently in, or "".
local function getCurrentTower(): string
	local acronym = player:GetAttribute("CurrentTower")
	if typeof(acronym) == "string" and acronym ~= "" then
		return acronym
	end
	return ""
end

--- Clamp a position inside the current tower's bounding box (if any).
local function clampPosition(position: Vector3): Vector3
	local tower = getCurrentTower()
	if tower == "" then
		return position
	end

	local bounds = getTowerBounds(tower)
	if not bounds then
		return position
	end

	return Vector3.new(
		math.clamp(position.X, bounds.min.X, bounds.max.X),
		math.clamp(position.Y, bounds.min.Y, bounds.max.Y),
		math.clamp(position.Z, bounds.min.Z, bounds.max.Z)
	)
end

---------------------------------------------------------------------------
-- Speed key handling
---------------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(key, typing)
	if not equipped or typing then
		return
	end

	for name, keyCode in keys do
		if key.KeyCode == keyCode then
			speed = name == "SpeedUpButton" and speed + 1
				or name == "SpeedDownButton" and speed - 1
				or name == "SpeedResetButton" and 0
				or speed
		end
	end
end)

tool.ToolTip =
	`Move Upwards: {keys.UpButton.Name} | Move Downwards: {keys.DownButton.Name} | Speed Up: {keys.SpeedUpButton.Name} | Slow Down: {keys.SpeedDownButton.Name} | Reset Speed: {keys.SpeedResetButton.Name}`

---------------------------------------------------------------------------
-- Equip / Unequip
---------------------------------------------------------------------------

tool.Equipped:Connect(function()
	equipped = true

	connection = RunService.Heartbeat:Connect(function(step: number)
		local character = player.Character
		local humanoid = character and character:FindFirstChild("Humanoid")
		local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
		local camera = workspace.CurrentCamera

		if humanoid then
			humanoid.PlatformStand = true
		end

		if humanoidRootPart and camera then
			hrpPivot = humanoidRootPart:GetPivot()
			humanoidRootPart.Anchored = true
			humanoidRootPart.Velocity = Vector3.zero

			local moveAmount = controlModule:GetMoveVector() or Vector3.zero

			if not UserInputService:GetFocusedTextBox() then
				if UserInputService:IsKeyDown(keys.UpButton) then
					moveAmount = Vector3.new(moveAmount.X, 1, moveAmount.Z)
				end

				if UserInputService:IsKeyDown(keys.DownButton) then
					moveAmount = Vector3.new(moveAmount.X, moveAmount.Y - 1, moveAmount.Z)
				end
			end

			moveAmount = moveAmount.Magnitude > 1 and moveAmount.Unit or moveAmount
			moveAmount *= step * defaultSpeed * 1.25 ^ speed

			local newCFrame = CFrame.new(
				humanoidRootPart.Position,
				humanoidRootPart.Position + camera.CFrame.LookVector
			) * CFrame.new(moveAmount)

			-- Clamp to tower boundaries
			local clampedPos = clampPosition(newCFrame.Position)
			humanoidRootPart.CFrame = CFrame.new(clampedPos) * (newCFrame - newCFrame.Position)
		end
	end)
end)

tool.Unequipped:Connect(function()
	equipped = false

	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

	if humanoid then
		humanoid.PlatformStand = false
	end

	if humanoidRootPart then
		humanoidRootPart.Anchored = false

		if hrpPivot then
			local _, RY, RZ = hrpPivot:ToOrientation()
			humanoidRootPart.CFrame = CFrame.new(hrpPivot.Position) * CFrame.fromOrientation(0, RY, RZ)
		end
	end

	if connection then
		connection:Disconnect()
		connection = nil
	end
end)
