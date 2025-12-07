--!strict
-- Written by fanofpixels

local repo = script.Repository.Value :: Instance
local context = script.Context.Value :: Instance

-- The ModuleScript of the client object to be spawned, whether it be a ClientObjectScript or a RunRepoScript
local body: ModuleScript

if context:IsA("StringValue") then
	-- The context is a StringValue! it must be a RunRepoScript

	-- Find the script referenced in the script repository
	local repoScript = repo:FindFirstChild(context.Value)

	if repoScript and repoScript:IsA("ModuleScript") then
		body = repoScript:Clone()
		body.Name = `RepoScriptInstantiation_{body.Name}`
		body.Parent = context.Parent
	end
elseif context:IsA("ModuleScript") then
	-- The body must be a ClientObjectScript!
	body = context
end

-- After the above code has happened, Body will be set to a ModuleScript to be spawned
if body then
	task.spawn(require(body) :: any)
end
