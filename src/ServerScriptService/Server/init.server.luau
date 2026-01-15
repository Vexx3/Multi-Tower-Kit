-- Main server entry point for Multi-Tower Kit.
-- Boots the MTK server framework by discovering and initializing all services.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Framework = ReplicatedStorage.Framework

local Log = require(Framework.Log)
local ModuleLoader = require(Shared.ModuleLoader)
local TowerService = require(script.Services.TowerService)

local function init()
	Log({ "Initializing MTK Server Framework..." })

	-- Ensure EverpresentCOs are moved to ServerStorage before loading services
	local towers = workspace:WaitForChild("Towers")
	local ecos = towers:WaitForChild("EverpresentCOs")
	ecos.Parent = ServerStorage

	-- Initialize core services that others depend on first
	TowerService.init()

	-- Discover and initialize all modules in the Server directory
	ModuleLoader.loadAndInit(script, { script.Network, script.Services.TowerService })

	Log({ "Server Framework started successfully." })
end

init()
