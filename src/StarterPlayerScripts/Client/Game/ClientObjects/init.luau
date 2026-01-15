-- Loads, wires, and unloads client objects for towers, including everpresent
-- objects and custom repository support.

type COScriptContext = ModuleScript | StringValue

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientObjects: Instance?
local objectScope: unknown

local EverpresentClientObjectThreads = script.Parent.EverpresentClientObjectThreads
local ClientObjectThreads: Folder = script.Parent.ClientObjectThreads
local ClientObjectThread = script.ClientObjectThread
local ScriptRepo = script.Parent.ScriptRepo

local Framework = ReplicatedStorage.Framework
local Log = require(Framework.Log)
local Kit = Framework.Kit
local Utility = require(Kit.Utility)

local customRepository = ReplicatedStorage:FindFirstChild("ExternalRepositories")

local ClientObjectManager = require(Kit.Managers.ClientObjectManager)

-- Spawns a client object thread for a script or repo entry.
local function loadClientObjectScript(context: COScriptContext, orphaned: boolean): ()
	-- Clone the thread template and set it up
	local thread = ClientObjectThread:Clone()
	thread.Name = Utility.Functions.generateUID()

	local threadContext = thread:WaitForChild("Context")
	threadContext.Value = context -- The thread script will automatically figure out if this is a RunRepoScript or a ClientObjectScript

	thread.Parent = if orphaned then EverpresentClientObjectThreads else ClientObjectThreads
	thread.Enabled = true
end

-- Cleans up all loaded client objects and running threads.
local function unloadClientObjects(): ()
	-- v6
	if objectScope then
		(objectScope :: any):cleanup(false, true)
		objectScope = nil
	end

	-- ClientObjects may not exist as it is nilable and this function is called when there likely isn't any COs loaded at all
	-- So we check if its not nil for good measure
	if clientObjects then
		clientObjects:Destroy()
		clientObjects = nil
	end

	-- Kill all threads
	ClientObjectThreads:ClearAllChildren()
end

-- Loads a folder of client objects into workspace or the everpresent scope,
-- attaches client scripts, applies collision overrides, and sets up kit v6
-- client parts when present.
local function loadClientObjects(coFolder: Instance, orphaned: boolean, acronym: string): ()
	-- If "orphaned" do not do anything to the ClientObjects variable
	-- Usually used for loading everpresent COs without touching tower COs
	if not orphaned then
		-- If there are already client objects present, delete them
		unloadClientObjects()
	end

	local isKitV6 = coFolder:GetAttribute("KitVersion")

	for _, v in coFolder:GetDescendants() do
		local parent = v.Parent
		local name = v.Name

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
		elseif
			(name == "ClientObjectScript" and (v:IsA("ModuleScript") or Utility.Instance.isPointer(v)))
			or (name == "RunRepoScript" and (v:IsA("StringValue") or Utility.Instance.isPointer(v)))
		then
			loadClientObjectScript(v :: any, orphaned)
		elseif name == "SetCollisionGroup" and v:IsA("StringValue") and parent and parent:IsA("BasePart") then
			parent.CollisionGroup = v.Value
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
			)

			clientObjects = clientObjectsFolder
			return
		end
	end
end

(ClientObjectThread:WaitForChild("Repository") :: ObjectValue).Value = ScriptRepo

return {
	loadClientObjectScript = loadClientObjectScript,
	loadClientObjects = loadClientObjects,
	unloadClientObjects = unloadClientObjects,
}
