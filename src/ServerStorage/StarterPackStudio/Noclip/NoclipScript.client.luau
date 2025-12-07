--!strict
-- Noclip tool made by funwolf7, modified by bLockerman666

local tool = script.Parent

local keys: {[string]: Enum.KeyCode} = {
	UpButton = Enum.KeyCode.Space,
	DownButton = Enum.KeyCode.LeftControl,
	SpeedUpButton = Enum.KeyCode.E,
	SpeedDownButton = Enum.KeyCode.Q,
	SpeedResetButton = Enum.KeyCode.R,
}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
local controlModule = playerModule:GetControls()

local equipped = false
local connection = nil
local hrpPivot

local defaultSpeed = tool:FindFirstChild("Speed") and tool.Speed.Value or 60
local speed = 0

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

tool.ToolTip = `Move Upwards: {keys.UpButton.Name} | Move Downwards: {keys.DownButton.Name} | Speed Up: {keys.SpeedUpButton.Name} | Slow Down: {keys.SpeedDownButton.Name} | Reset Speed: {keys.SpeedResetButton.Name}`

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

			humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + camera.CFrame.LookVector) * CFrame.new(moveAmount)
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