--!strict
-- Written by fanofpixels

-- Hip offset to make sure teleports dont teleport you inside of the destination
local hip = CFrame.new(0, 3, 0)

local Teleport = {}

-- Teleports the player's character
function Teleport:TeleportPlayerToPart(player: Player, destination: BasePart)
	local character = player.Character
	if not character then
		return
	end

	character:PivotTo(destination.CFrame * hip)
end

-- Teleports the player's character, and if it isn't loaded, waits until it is
function Teleport:TeleportPlayerToPartWithWait(player: Player, destination: BasePart)
	local character = player.Character
	if not character then
		repeat
			task.wait(0.05)
			character = player.Character
			if player.Character then
				player.Character:PivotTo(destination.CFrame * hip)
			end
		until character
		return
	end

	character:PivotTo(destination.CFrame * hip)
end

return Teleport
