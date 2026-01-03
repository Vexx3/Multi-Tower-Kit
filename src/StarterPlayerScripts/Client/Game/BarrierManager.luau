local Players = game:GetService("Players")

local BarrierManager = {}
local barrierShown = false
local activeBarriers = {}

function BarrierManager:ShowBarrier(acronym: string)
	if barrierShown then
		return
	end

	local LocalPlayer = Players.LocalPlayer
	local barriers = LocalPlayer:WaitForChild(acronym, 5)
	if not barriers then
		return
	end

	local towerFolder = workspace.Towers:FindFirstChild(acronym)

	barrierShown = true

	for _, child in barriers:GetChildren() do
		if child:IsA("BasePart") or child:IsA("Model") then
			local clone = child:Clone()
			clone.Parent = towerFolder or workspace
			table.insert(activeBarriers, clone)

			-- Play sound if it exists
			local sound = clone:FindFirstChildOfClass("Sound")
			if sound then
				sound:Play()
			end
		end
	end
end

function BarrierManager:Reset()
	barrierShown = false
	for _, barrier in activeBarriers do
		if barrier then
			barrier:Destroy()
		end
	end
	activeBarriers = {}
end

return BarrierManager
