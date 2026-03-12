--[[
	Server entry point for Multi-Tower Kit.
	Reparents server code to prevent client access, then initializes modules.
	Side-effect scripts (winpads, touchZones, timer, commands) are standalone
	.server.luau Scripts that auto-run — no require needed here.
]]

-- Reparent server files to a non-replicated instance
local destination = Instance.new("Camera")
local source: Instance = script:FindFirstAncestor("server")

destination.Name = source.Name
destination.Parent = source.Parent

for _, child in source:GetChildren() do
	child.Parent = destination
end

source.Parent = nil

local ServerStorage = game:GetService("ServerStorage")

local Config = require("../shared/constants/config")
local ConfigValidator = require("../shared/configValidator")

-- Modules with public API (other modules require these)
local allJumps = require("./gameplay/allJumps")
local announcements = require("./gameplay/announcements")
local players = require("@self/players")
local tools = require("./gameplay/tools")
local towers = require("./gameplay/towers")

do
	ConfigValidator.validateWithWarnings(Config)

	-- Ensure EverpresentCOs are moved to ServerStorage before player lifecycle
	local towersFolder = workspace:WaitForChild("Towers")
	local ecos = towersFolder:WaitForChild("EverpresentCOs")
	ecos.Parent = ServerStorage

	-- Initialize modules that have API + lifecycle setup
	towers.init()
	tools.init()
	allJumps.init()
	announcements.init()

	-- Player lifecycle must start after everything above is ready
	players.init()
end
