--[=[
	Simple module loader for initializing modules.
	Loads all ModuleScripts with an Init function and calls them.

	@class ModuleLoader
]=]

local ModuleLoader = {}

export type InitModule = {
	init: () -> (),
}

--[=[
	Loads all ModuleScripts that are descendants of the given parent.
	Returns a list of modules that have an init function.

	@param parent Instance -- The parent to search for ModuleScripts
	@param ignore {Instance}? -- Optional list of instances to ignore
	@return {InitModule}
]=]
function ModuleLoader.loadModules(parent: Instance, ignore: { Instance }?): { InitModule }
	local modules: { InitModule } = {}
	local ignoreSet: { [Instance]: boolean } = {}

	if ignore then
		for _, instance in ignore do
			ignoreSet[instance] = true
		end
	end

	for _, descendant in parent:GetDescendants() do
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
			table.insert(modules, result)
		end
	end

	return modules
end

--[=[
	Initializes all modules by calling their init function.

	@param modules {InitModule} -- List of modules to initialize
]=]
function ModuleLoader.initAll(modules: { InitModule }): ()
	for _, module in modules do
		task.spawn(function()
			local success, err = pcall(module.init, module)
			if not success then
				warn(`[ModuleLoader] Init failed: {err}`)
			end
		end)
	end
end

--[=[
	Loads and initializes all modules in one call.

	@param parent Instance -- The parent to search for ModuleScripts
	@param ignore {Instance}? -- Optional list of instances to ignore
]=]
function ModuleLoader.loadAndInit(parent: Instance, ignore: { Instance }?): ()
	local modules = ModuleLoader.loadModules(parent, ignore)
	ModuleLoader.initAll(modules)
end

return ModuleLoader
