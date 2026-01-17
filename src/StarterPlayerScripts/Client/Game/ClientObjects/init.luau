--[[
	Loads, wires, and unloads client objects for towers.
]]

type COScriptContext = ModuleScript | StringValue
type ClientObjectScope = {
	cleanup: (self: ClientObjectScope, boolean, boolean) -> (),
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = ReplicatedStorage.Framework
local Kit = Framework.Kit

local ClientObjectManager = require(Kit.Managers.ClientObjectManager)
local Log = require(Framework.Log)
local Utility = require(Kit.Utility)

local EverpresentClientObjectThreads = script.Parent.EverpresentClientObjectThreads
local ClientObjectThreads = script.Parent.ClientObjectThreads
local ClientObjectThread = script.ClientObjectThread
local ScriptRepo = script.Parent.ScriptRepo

local customRepository = ReplicatedStorage:FindFirstChild("ExternalRepositories")

local clientObjects: Instance?
local objectScope: ClientObjectScope?

-- Spawns a client object thread for a script or repo entry.
local function loadClientObjectScript(context: COScriptContext, orphaned: boolean): ()
	local thread = ClientObjectThread:Clone()
	thread.Name = Utility.Functions.generateUID()

	local threadContext = thread:WaitForChild("Context")
	threadContext.Value = context

	thread.Parent = if orphaned then EverpresentClientObjectThreads else ClientObjectThreads
	thread.Enabled = true
end

-- Cleans up all loaded client objects and running threads.
local function unloadClientObjects(): ()
	if objectScope then
		objectScope:cleanup(false, true)
		objectScope = nil
	end

	if clientObjects then
		clientObjects:Destroy()
		clientObjects = nil
	end

	ClientObjectThreads:ClearAllChildren()
end

-- Loads a folder of client objects into workspace or the everpresent scope.
local function loadClientObjects(coFolder: Instance, orphaned: boolean, acronym: string): ()
	if not orphaned then
		unloadClientObjects()
	end

	local isKitV6 = coFolder:GetAttribute("KitVersion")

	for _, v in coFolder:GetDescendants() do
		local parent = v.Parent
		local name = v.Name

		-- Handle duplicate client object values
		if name == "ClientObject" and parent then
			local seen = false
			for _, child in parent:GetChildren() do
				if child.Name == "ClientObject" then
					if seen then
						Log({
							type = "warn",
							[1] = `Found a double client object value in: {parent.Name}`,
						})
						child:Destroy()
					else
						seen = true
					end
				end
			end
		-- Handle client object scripts
		elseif
			(name == "ClientObjectScript" and (v:IsA("ModuleScript") or Utility.Instance.isPointer(v)))
			or (name == "RunRepoScript" and (v:IsA("StringValue") or Utility.Instance.isPointer(v)))
		then
			loadClientObjectScript(v :: COScriptContext, orphaned)
		-- Handle collision groups
		elseif name == "SetCollisionGroup" and v:IsA("StringValue") and parent and parent:IsA("BasePart") then
			parent.CollisionGroup = v.Value
		-- Handle invisible parts
		elseif v:IsA("BasePart") and (name == "LightingChanger" or v:FindFirstChild("Invisible")) then
			v.Transparency = 1
		end
	end

	if orphaned then
		local everpresentCOFolder = workspace:FindFirstChild("EverpresentCOs") :: Folder
		if not everpresentCOFolder then
			everpresentCOFolder = Instance.new("Folder")
			everpresentCOFolder.Name = "EverpresentCOs"
			everpresentCOFolder.Parent = workspace
		end
		ClientObjectManager:LoadClientObjects(
			coFolder,
			everpresentCOFolder,
			acronym,
			customRepository:FindFirstChild(acronym)
		)
	else
		coFolder.Parent = workspace
		clientObjects = coFolder

		if isKitV6 then
			local clientObjectsFolder = workspace:FindFirstChild("ClientParts") :: Instance
			if not clientObjectsFolder then
				clientObjectsFolder = Instance.new("Folder")
				clientObjectsFolder.Name = "ClientParts"
				clientObjectsFolder.Parent = workspace
			end

			objectScope = ClientObjectManager:LoadClientObjects(
				coFolder,
				clientObjectsFolder,
				acronym,
				customRepository:FindFirstChild(acronym)
			) :: ClientObjectScope

			clientObjects = clientObjectsFolder
			return
		end
	end
end

-- Set up repository reference
(ClientObjectThread:WaitForChild("Repository") :: ObjectValue).Value = ScriptRepo

return {
	loadClientObjectScript = loadClientObjectScript,
	loadClientObjects = loadClientObjects,
	unloadClientObjects = unloadClientObjects,
}
