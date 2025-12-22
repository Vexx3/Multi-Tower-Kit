--[=[
	Loads, wires, and unloads client objects for towers, including everpresent
	objects and custom repository support.

	@class ClientObjects
]=]

type COScriptContext = ModuleScript | StringValue

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local clientObjects: Instance?

local EverpresentClientObjectThreads = script.Parent.EverpresentClientObjectThreads
local ClientObjectThreads: Folder = script.Parent.ClientObjectThreads
local ClientObjectThread = script.ClientObjectThread
local ScriptRepo = script.Parent.ScriptRepo

local Framework = ReplicatedStorage.Framework
local Kit = Framework.Kit

local customRepository = ReplicatedStorage:FindFirstChild("ExternalRepositories")

local ClientObjectManager = require(Kit.Managers.ClientObjectManager)

local objectScope

local ClientObjects = {}

--[=[
	Spawns a client object thread for a script or repo entry.

	@within ClientObjects
	@param context ModuleScript | StringValue -- either ClientObjectScript or RunRepoScript
	@param orphaned boolean -- true for everpresent objects that persist across towers
]=]
function ClientObjects:LoadClientObjectScript(context: COScriptContext, orphaned: boolean)
	-- Clone the thread template and set it up
	local thread = ClientObjectThread:Clone()
	thread.Name = HttpService:GenerateGUID(false)

	local threadContext = thread:WaitForChild("Context")
	threadContext.Value = context -- The thread script will automatically figure out if this is a RunRepoScript or a ClientObjectScript

	thread.Parent = if orphaned then EverpresentClientObjectThreads else ClientObjectThreads
	thread.Enabled = true
end

--[=[
	Loads a folder of client objects into workspace or the everpresent scope,
	attaches client scripts, applies collision overrides, and sets up kit v6
	client parts when present.

	@within ClientObjects
	@param coFolder Instance -- root folder of client objects
	@param orphaned boolean -- true to load into everpresent scope without touching current tower objects
	@param acronym string -- tower acronym for repository lookup
]=]
function ClientObjects:LoadClientObjects(coFolder: Instance, orphaned: boolean, acronym: string)
	-- If "orphaned" do not do anything to the ClientObjects variable
	-- Usually used for loading everpresent COs without touching tower COs
	if not orphaned then
		-- If there are already client objects present, delete them
		ClientObjects:UnloadClientObjects()
	end

	local isKitV6 = coFolder:GetAttribute("KitVersion")

	local descendants = coFolder:GetDescendants()

	local checkedParents: { [Instance]: boolean } = {}

	for _, v in descendants do
		local vName = v.Name
		local vParent = v.Parent

		if vParent and vName == "ClientObject" then
			-- Only check each parent once for duplicates
			if not checkedParents[vParent] then
				checkedParents[vParent] = true
				local foundFirst = false
				for _, child in vParent:GetChildren() do
					if child.Name == "ClientObject" then
						if foundFirst then
							warn(`⚠️ Found a double client object value in: {vParent.Name} ⚠️`)
							child:Destroy()
						else
							foundFirst = true
						end
					end
				end
			end
		elseif
			(vName == "ClientObjectScript" and v:IsA("ModuleScript"))
			or (vName == "RunRepoScript" and v:IsA("StringValue"))
		then
			ClientObjects:LoadClientObjectScript(v, orphaned)
		elseif vName == "SetCollisionGroup" and v:IsA("StringValue") then
			if vParent and vParent:IsA("BasePart") then
				vParent.CollisionGroup = v.Value
			end
		elseif v:IsA("BasePart") then
			if vName == "LightingChanger" or v:FindFirstChild("Invisible") then
				v.Transparency = 1
			end
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

--[=[
    Cleans up all loaded client objects and running threads.

    @within ClientObjects
]=]
function ClientObjects:UnloadClientObjects()
	-- v6
	if objectScope then
		objectScope:cleanup(false, true)
		objectScope = nil
	end

	-- ClientObjects may not exist as it is nilable and this function is called when there likely isn't any COs loaded at all
	-- So we check if its not nil for good measure
	if clientObjects then
		clientObjects:Destroy()
	end

	-- Kill all threads
	ClientObjectThreads:ClearAllChildren()
end

do
	(ClientObjectThread:WaitForChild("Repository") :: ObjectValue).Value = ScriptRepo
end

return ClientObjects
