--[[
	Simple player lifecycle helpers.
	Replaces the Observers package with minimal inline logic.
]]

local Players = game:GetService("Players")

local playerLifecycle = {}

--- Calls onAdded for every current and future player, and onRemoving when they leave.
function playerLifecycle.onPlayerAdded(onAdded: (player: Player) -> (), onRemoving: ((player: Player) -> ())?)
	Players.PlayerAdded:Connect(onAdded)
	if onRemoving then
		Players.PlayerRemoving:Connect(onRemoving)
	end
	for _, player in Players:GetPlayers() do
		task.spawn(onAdded, player)
	end
end

--- Calls onAdded for every current and future character of a player.
function playerLifecycle.onCharacterAdded(player: Player, onAdded: (character: Model) -> ())
	player.CharacterAdded:Connect(onAdded)

	local existingCharacter = player.Character
	if existingCharacter then
		task.spawn(onAdded, existingCharacter)
	end
end

return playerLifecycle
