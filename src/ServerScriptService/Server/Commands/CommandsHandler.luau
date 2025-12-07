--!strict
-- @zylx 2025-11-20
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameData = ReplicatedStorage.GameData
local Packages = ReplicatedStorage.Packages
local Shared = ReplicatedStorage.Shared

local Config = require(GameData.Config)
local conch = require(Packages.conch_standalone)

local Commands = script.Parent.Parent.Commands

local function onPlayerAdded(player: Player)
	local user = conch.get_user(player)
	local roles = Config.USER_ROLES[player.UserId]
	if roles then
		conch.give_roles(user, table.unpack(roles))
	end
end

local CommandsHandler = {}

function CommandsHandler:Init()
	require(Shared.ConchTypes)

	conch.initiate_default_lifecycle()

	for roleName, permissions in Config.ROLES do
		conch.set_role_permissions(roleName, table.unpack(permissions))
	end

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
