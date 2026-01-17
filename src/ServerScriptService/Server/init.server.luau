--[[
	Main server entry point for Multi-Tower Kit.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Packages = ReplicatedStorage.Packages
local Framework = ReplicatedStorage.Framework

local Loader = require(Packages.Loader)
local Log = require(Framework.Log)
local TowerService = require("@self/Services/TowerService")

do
	local startTime = os.clock()
	Log({ "Initializing MTK Server Framework..." })

	-- Ensure EverpresentCOs are moved to ServerStorage before loading services
	local towers = workspace:WaitForChild("Towers")
	local ecos = towers:WaitForChild("EverpresentCOs")
	ecos.Parent = ServerStorage

	-- Initialize core services that others depend on first
	TowerService.Start()

	-- Discover and initialize all service modules with Start method
	local services = Loader.LoadDescendants(script.Services, Loader.MatchesName("Service$"))
	local playerModules = Loader.LoadDescendants(script.Player)
	Loader.SpawnAll(services, "Start")
	Loader.SpawnAll(playerModules, "Start")

	local elapsed = os.clock() - startTime
	Log({ `Server Framework started successfully in {string.format("%.2f", elapsed * 1000)}ms` })
end
