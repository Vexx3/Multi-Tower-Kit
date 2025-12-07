--!strict
-- Written by fanofpixels

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

function ClientObjects:LoadClientObjectScript(context: COScriptContext, orphaned: boolean)
	-- Clone the thread template and set it up
	local thread = ClientObjectThread:Clone()
	thread.Name = HttpService:GenerateGUID(false)

	local threadContext = thread:WaitForChild("Context")
	threadContext.Value = context -- The thread script will automatically figure out if this is a RunRepoScript or a ClientObjectScript

	thread.Parent = if orphaned then EverpresentClientObjectThreads else ClientObjectThreads
	thread.Enabled = true
end

function ClientObjects:LoadClientObjects(coFolder: Instance, orphaned: boolean, acronym: string)
	-- If "orphaned" do not do anything to the ClientObjects variable
	-- Usually used for loading everpresent COs without touching tower COs
	if not orphaned then
		-- If there are already client objects present, delete them
		ClientObjects:UnloadClientObjects()
	end
	
	local isKitV6 = coFolder:GetAttribute("KitVersion")
		
	for _, instance in coFolder:GetDescendants() do
		local v = instance :: Instance

		if v.Parent and v.Name == "ClientObject" then
			local parent = v.Parent
			for _, k in parent:GetDescendants() do
				if k.Name == "ClientObject" and v ~= k then
					warn("⚠️ Found a double client object value in: " .. parent.Name .. " ⚠️")
					k:Destroy()
				end
			end
		elseif (v:IsA("ModuleScript") and v.Name == "ClientObjectScript") or (v:IsA("StringValue") and v.Name == "RunRepoScript") then
			ClientObjects:LoadClientObjectScript(v, orphaned)
		elseif v:IsA("StringValue") and v.Name == "SetCollisionGroup" then
			if v.Parent and v.Parent:IsA("BasePart") then
				v.Parent.CollisionGroup = v.Value
			end
		elseif v:IsA("BasePart") then
			if v.Name == "LightingChanger" or v:FindFirstChild("Invisible") then
				v.Transparency = 1
			end
		end
	end
	
	if orphaned then
		local everpresentCOFolder = workspace:FindFirstChild("EverpresentCOs") :: Instance
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
		end
		
		clientObjects = coFolder
	end
end

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
