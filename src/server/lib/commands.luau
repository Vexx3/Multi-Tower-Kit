--[[
	Initializes the Conch command system with roles and permissions.
]]

local Players = game:GetService("Players")

local Config = require("../../shared/constants/config")
local conch = require("../../../Packages/conch")

local Commands = script.Parent.Parent.commands

local function onPlayerAdded(player: Player)
	local user = conch.get_user(player)
	local roles = Config.userRoles[player.UserId]

	if roles then
		conch.give_roles(user, table.unpack(roles))
	end
end

require("../../shared/conchTypes")

conch.initiate_default_lifecycle()

for roleName, permissions in Config.roles do
	conch.set_role_permissions(roleName, table.unpack(permissions))
end

for _, cmdModule in Commands:GetDescendants() do
	if cmdModule:IsA("ModuleScript") then
		local cmd = require(cmdModule) :: () -> ()
		if type(cmd) == "function" then
			cmd()
		end
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)

return nil
