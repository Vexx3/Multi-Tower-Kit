--[[
	Tower Visibility — Controls which parts of the game world are visible
	based on the player's `towerLoadingBehavior` setting.

	Modes:
	  "Load All"       — Everything stays visible (default, no changes).
	  "Unload Towers"  — Tower obby folders are moved out of workspace
	                     unless the player is currently playing that tower.
	  "Unload All"     — Same as Unload Towers, PLUS moves the lobby parts
	                     folder out of workspace while the player is inside a tower.

	## How it works

	- Tower folders live under `workspace.Towers`.  Hidden towers are
	  reparented to a local storage folder (invisible, not in workspace).
	  Shown towers are reparented back to `workspace.Towers`.
	- Lobby parts are an **optional** folder in workspace called "LobbyParts".
	  If it doesn't exist, Unload All behaves identically to Unload Towers.
	- The module listens for tower load / unload events and for setting changes.
]]

local TOWERS = workspace:WaitForChild("Towers") :: Folder
local LOBBY_PARTS = workspace:FindFirstChild("LobbyParts") :: Folder?

type TowerLoadingBehavior = "Load All" | "Unload Towers" | "Unload All"

-- Local storage folder for hidden containers (not parented to workspace,
-- so nothing inside it renders or collides).
local storage = Instance.new("Folder")
storage.Name = "__TowerVisibilityStorage"

-- Track which containers we moved so we can put them back. Maps the
-- container instance to its original parent.
local hiddenContainers: { [Instance]: Instance } = {}

-- Cache tower name → Obby folder so we can find them even after reparenting.
local obbyCache: { [string]: Instance } = {}

local currentBehavior: TowerLoadingBehavior = "Load All"
local currentTower = ""

local function cacheObbyFolders()
	for _, towerFolder in TOWERS:GetChildren() do
		local obbyFolder = towerFolder:FindFirstChild("Obby")
		if obbyFolder then
			obbyCache[towerFolder.Name] = obbyFolder
		end
	end
end

--- Moves a container into the local storage folder.
local function hideContainer(container: Instance)
	if hiddenContainers[container] then
		return -- already hidden
	end
	hiddenContainers[container] = container.Parent :: Instance
	container.Parent = storage
end

--- Restores a container to its original parent.
local function showContainer(container: Instance)
	local originalParent = hiddenContainers[container]
	if not originalParent then
		return -- not hidden
	end
	container.Parent = originalParent
	hiddenContainers[container] = nil
end

--- Restores ALL hidden containers.
local function showAll()
	for container, originalParent in hiddenContainers do
		if container then
			container.Parent = originalParent
		end
	end
	table.clear(hiddenContainers)
end

--- Applies the current visibility rules based on behavior and active tower.
local function applyVisibility()
	if currentBehavior == "Load All" then
		showAll()
		return
	end

	-- "Unload Towers" or "Unload All": hide the Obby folder inside each tower except the active one
	for towerName, obbyFolder in obbyCache do
		if towerName == currentTower then
			showContainer(obbyFolder)
		else
			hideContainer(obbyFolder)
		end
	end

	-- "Unload All": also hide lobby parts when inside a tower
	if LOBBY_PARTS then
		if currentBehavior == "Unload All" and currentTower ~= "" then
			hideContainer(LOBBY_PARTS)
		else
			showContainer(LOBBY_PARTS)
		end
	end
end

local towerVisibility = {}

--- Called when the player's towerLoadingBehavior setting changes.
function towerVisibility.setBehavior(behavior: TowerLoadingBehavior)
	currentBehavior = behavior
	applyVisibility()
end

--- Initializes the module and applies the current visibility rules.
function towerVisibility.init()
	cacheObbyFolders()
	applyVisibility()
end

--- Called when a tower is loaded. Updates visibility accordingly.
function towerVisibility.onTowerLoaded(towerAcronym: string)
	currentTower = towerAcronym
	applyVisibility()
end

--- Called when a tower is unloaded. Restores visibility.
function towerVisibility.onTowerUnloaded()
	currentTower = ""
	applyVisibility()
end

return towerVisibility
