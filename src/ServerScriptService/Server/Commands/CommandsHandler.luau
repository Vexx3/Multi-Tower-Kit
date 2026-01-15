-- Initializes the Conch command system with roles, permissions, and command discovery.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Data = Shared.Data
local Packages = ReplicatedStorage.Packages

local Config = require(Data.Config)
local conch = require(Packages.conch)

local Commands = script.Parent

local function onPlayerAdded(player: Player)
	local user = conch.get_user(player)
	local roles = Config.userRoles[player.UserId]

	if roles then
		conch.give_roles(user, table.unpack(roles))
	end
end

local CommandsHandler = {}

function CommandsHandler.init()
	require(Shared.ConchTypes)

	conch.initiate_default_lifecycle()

	-- Register roles and their permissions
	for roleName: string, permissions: { string } in Config.roles do
		conch.set_role_permissions(roleName, table.unpack(permissions))
	end

	-- Discover and register all command modules
	for _, cmdModule: ModuleScript? in Commands:GetDescendants() do
		if cmdModule and cmdModule:IsA("ModuleScript") then
			local cmd = require(cmdModule) :: () -> ()
			if type(cmd) == "function" then
				cmd()
			end
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
end

return CommandsHandler
