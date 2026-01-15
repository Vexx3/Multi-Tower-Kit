--[=[
	Legacy ButtonActivatedPlatform compatibility for v5 towers.
	Syncs CanCollide → Activated attribute for CharacterManager.
]=]

local connections: { [Instance]: RBXScriptConnection } = {}

local function setupSync(platform: BasePart): ()
	if connections[platform] then
		return
	end

	platform:SetAttribute("Activated", platform.CanCollide)
	connections[platform] = platform:GetPropertyChangedSignal("CanCollide"):Connect(function()
		platform:SetAttribute("Activated", platform.CanCollide)
	end)
end

local function isBap(part: BasePart): boolean
	return part.Name == "ButtonActivatedPlatform" or part:FindFirstChild("ButtonActivated") ~= nil
end

local function monitorFolder(folder: Instance): ()
	for _, desc in folder:GetDescendants() do
		if desc:IsA("BasePart") and isBap(desc) then
			setupSync(desc)
		end
	end

	folder.DescendantAdded:Connect(function(desc)
		if desc:IsA("BasePart") and isBap(desc) then
			task.defer(setupSync, desc)
		end
	end)

	folder.DescendantRemoving:Connect(function(desc)
		local conn = connections[desc]
		if conn then
			conn:Disconnect()
			connections[desc] = nil
		end
	end)
end

local function init(): ()
	workspace.ChildAdded:Connect(function(child)
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

return {
	init = init,
}
