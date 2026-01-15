-- Manages the discovery and initialization of ModuleScripts across the project.

export type InitModule = {
	init: (InitModule) -> (),
}

-- Scans the parent instance for ModuleScripts that expose an init function.
local function loadModules(parent: Instance, ignore: { Instance }?): { InitModule }
	local modules: { InitModule } = {}
	local ignoreSet: { [Instance]: boolean } = {}

	if ignore then
		for _, instance in ipairs(ignore) do
			ignoreSet[instance] = true
		end
	end

	for _, descendant in ipairs(parent:GetDescendants()) do
		if not descendant:IsA("ModuleScript") then
			continue
		end

		-- Check if this descendant or any of its ancestors is in the ignore list
		local shouldIgnore = false
		local current: Instance? = descendant
		while current and current ~= parent do
			if ignoreSet[current] then
				shouldIgnore = true
				break
			end
			current = current.Parent
		end

		if shouldIgnore then
			continue
		end

		local success, result = pcall(require, descendant)
		if not success then
			continue
		end

		if type(result) == "table" and type(result.init) == "function" then
			table.insert(modules, result :: InitModule)
		end
	end

	return modules
end

-- Executes the init function on a list of provided modules in separate threads.
local function initAll(modules: { InitModule }): ()
	for _, module in ipairs(modules) do
		task.spawn(function()
			local success, err = pcall(module.init, module)
			if not success then
				warn(`[ModuleLoader] Init failed: {err}`)
			end
		end)
	end
end

-- Combines the loading and initialization steps into a single call.
local function loadAndInit(parent: Instance, ignore: { Instance }?): ()
	local modules = loadModules(parent, ignore)
	initAll(modules)
end

local ModuleLoader = {}

ModuleLoader.loadModules = loadModules
ModuleLoader.initAll = initAll
ModuleLoader.loadAndInit = loadAndInit

return ModuleLoader
