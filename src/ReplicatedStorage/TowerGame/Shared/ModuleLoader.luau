-- Manages the discovery and initialization of ModuleScripts across the project.
-- Finds modules with init() functions and executes them in parallel.

export type InitModule = {
	init: (InitModule) -> (),
}

local ModuleLoader = {}

local function loadModules(parent: Instance, ignore: { Instance }?): { InitModule }
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

local function initAll(modules: { InitModule }): ()
	for _, module in modules do
		task.spawn(function()
			local success, err = pcall(module.init, module)
			if not success then
				warn(`[ModuleLoader] Init failed: {err}`)
			end
		end)
	end
end

ModuleLoader.loadModules = loadModules
ModuleLoader.initAll = initAll

function ModuleLoader.loadAndInit(parent: Instance, ignore: { Instance }?): ()
	local modules = loadModules(parent, ignore)
	initAll(modules)
end

return ModuleLoader
