local repo = script.Repository.Value
local context = script.Context.Value

if not context then
	return
end

-- The ModuleScript of the client object to be spawned, whether it be a ClientObjectScript or a RunRepoScript
local body: ModuleScript

if context:IsA("StringValue") then
	-- The context is a StringValue! it must be a RunRepoScript

	-- Find the script referenced in the script repository
	local repoScript = if repo then repo:FindFirstChild((context :: StringValue).Value) else nil

	if repoScript and repoScript:IsA("ModuleScript") then
		body = repoScript:Clone()
		body.Name = `RepoScriptInstantiation_{body.Name}`
		body.Parent = context.Parent
	end
elseif context:IsA("ModuleScript") then
	-- The body must be a ClientObjectScript!
	body = context
elseif context:IsA("ObjectValue") and context:HasTag("OBJ_POINTER") then
	-- The body must be a v6 pointer to a module!
	body = (context :: ObjectValue).Value :: ModuleScript
end

-- After the above code has happened, Body will be set to a ModuleScript to be spawned
if body then
	task.spawn(require(body) :: any)
end
