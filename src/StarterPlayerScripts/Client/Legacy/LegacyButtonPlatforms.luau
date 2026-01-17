--[[
	Legacy ButtonActivatedPlatform compatibility for v5 towers.
]]

type ConnectionMap = { [Instance]: RBXScriptConnection }

local connections: ConnectionMap = {}

local LegacyButtonPlatforms = {}

-- Sets up property sync for a ButtonActivatedPlatform.
local function setupSync(platform: BasePart): ()
	if connections[platform] then
		return
	end

	platform:SetAttribute("Activated", platform.CanCollide)
	connections[platform] = platform:GetPropertyChangedSignal("CanCollide"):Connect(function()
		platform:SetAttribute("Activated", platform.CanCollide)
	end)
end

-- Checks if a part is a ButtonActivatedPlatform.
local function isBap(part: BasePart): boolean
	return part.Name == "ButtonActivatedPlatform" or part:FindFirstChild("ButtonActivated") ~= nil
end

-- Monitors a folder for ButtonActivatedPlatforms.
local function monitorFolder(folder: Instance): ()
	for _, desc in folder:GetDescendants() do
		if desc:IsA("BasePart") and isBap(desc) then
			setupSync(desc)
		end
	end

	folder.DescendantAdded:Connect(function(desc: Instance)
		if desc:IsA("BasePart") and isBap(desc) then
			task.defer(setupSync, desc)
		end
	end)

	folder.DescendantRemoving:Connect(function(desc: Instance)
		local conn = connections[desc]
		if conn then
			conn:Disconnect()
			connections[desc] = nil
		end
	end)
end

--- Initializes monitoring for legacy ButtonActivatedPlatforms in workspace.
function LegacyButtonPlatforms.init(): ()
	workspace.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Folder") and child:GetAttribute("KitVersion") == nil then
			monitorFolder(child)
		end
	end)

	for _, child in workspace:GetChildren() do
		if child:IsA("Folder") and child:GetAttribute("KitVersion") == nil then
			monitorFolder(child)
		end
	end
end

return LegacyButtonPlatforms
