-- Main server entry point for Multi-Tower Kit.
-- This file is now a slim entry point that boots the MTK framework by discovery.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared

local Log = require(ReplicatedStorage.Framework.Log)
local ModuleLoader = require(Shared.ModuleLoader)

local TowerService = require("@self/Services/TowerService")

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
