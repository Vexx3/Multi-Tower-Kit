--[[
	ClientObjects - Loads and unloads client objects for towers.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = ReplicatedStorage.Framework
local Kit = Framework.Kit

local ClientObjectManager = require(Kit.Managers.ClientObjectManager)
local Log = require(Framework.Log)
local Utility = require(Kit.Utility)

local Controllers = script.Parent
local EverpresentThreads = Controllers and Controllers:FindFirstChild("EverpresentClientObjectThreads")
local ClientObjectThreads = Controllers and Controllers:FindFirstChild("ClientObjectThreads")
local ClientObjectThread = script:FindFirstChild("ClientObjectThread") :: LocalScript
local ScriptRepo = Controllers and Controllers:FindFirstChild("ScriptRepo")
local customRepository = ReplicatedStorage:FindFirstChild("ExternalRepositories")

local clientObjects: Instance?
local objectScope: any?

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function loadScript(context: Instance, orphaned: boolean)
	local thread = ClientObjectThread:Clone()
	thread.Name = Utility.Functions.generateUID()
	local contextValue = thread:FindFirstChild("Context")
	if contextValue and contextValue:IsA("ObjectValue") then
		contextValue.Value = context
	end
	thread.Parent = if orphaned then EverpresentThreads else ClientObjectThreads
	thread.Enabled = true
end

local function processDescendant(v: Instance, orphaned: boolean)
	local parent = v.Parent
	if not parent then
		return
	end

	local name = v.Name

	if name == "ClientObject" then
		-- Remove duplicate ClientObject values
		local found = false
		for _, child in parent:GetChildren() do
			if child.Name == "ClientObject" then
				if found then
					Log({ type = "warn", [1] = `Double ClientObject in: {parent.Name}` })
					child:Destroy()
				else
					found = true
				end
			end
		end
	elseif name == "ClientObjectScript" or name == "RunRepoScript" then
		if v:IsA("ModuleScript") or v:IsA("StringValue") or Utility.Instance.isPointer(v) then
			loadScript(v, orphaned)
		end
	elseif name == "SetCollisionGroup" and v:IsA("StringValue") and parent:IsA("BasePart") then
		parent.CollisionGroup = v.Value
	elseif v:IsA("BasePart") and (name == "LightingChanger" or v:FindFirstChild("Invisible")) then
		v.Transparency = 1
	end
end

local function unloadClientObjects()
	if objectScope then
		objectScope:cleanup(false, true)
		objectScope = nil
	end
	if clientObjects then
		clientObjects:Destroy()
		clientObjects = nil
	end
	if ClientObjectThreads then
		ClientObjectThreads:ClearAllChildren()
	end
end

local function loadClientObjects(coFolder: Instance, orphaned: boolean, acronym: string)
	if not orphaned then
		unloadClientObjects()
	end

	for _, v in coFolder:GetDescendants() do
		processDescendant(v, orphaned)
	end

	local customRepo = customRepository and customRepository:FindFirstChild(acronym)

	if orphaned then
		local folder = getOrCreateFolder(workspace, "EverpresentCOs")
		ClientObjectManager:LoadClientObjects(coFolder, folder, acronym, customRepo)
	else
		coFolder.Parent = workspace
		clientObjects = coFolder

		if coFolder:GetAttribute("KitVersion") then
			local folder = getOrCreateFolder(workspace, "ClientParts")
			objectScope = ClientObjectManager:LoadClientObjects(coFolder, folder, acronym, customRepo)
			clientObjects = folder
		end
	end
end

-- Set up repository reference
local repoRef = ClientObjectThread:FindFirstChild("Repository")
if repoRef and repoRef:IsA("ObjectValue") and ScriptRepo then
	repoRef.Value = ScriptRepo
end

return {
	loadScript = loadScript,
	loadClientObjects = loadClientObjects,
	unloadClientObjects = unloadClientObjects,
}
