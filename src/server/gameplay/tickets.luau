--[[
	Ticket rewards for tower completions.
	Awards tickets based on difficulty with configurable multipliers,
	cooldowns, and per-tower overrides.
]]

local TicketConfig = require("../../shared/constants/ticketConfig")
local Types = require("../../shared/types")
local accounts = require("../accounts")

type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo
type PlayerDataType = accounts.PlayerData

local tickets = {}

--- Calculates the ticket reward for completing a tower.
function tickets.calculateReward(tower: TowerInfo): number
	if not TicketConfig.enabled then
		return 0
	end

	local acronym = tower.folder.Name
	local override = TicketConfig.towerOverrides[acronym]

	if override and override.disabled then
		return 0
	end

	local baseReward = TicketConfig.baseRewards[tower.difficulty] or 0
	if baseReward == 0 then
		return 0
	end

	local multiplier = if override and override.multiplier then override.multiplier else 1.0

	return math.floor(baseReward * multiplier)
end

--- Checks if a player can earn tickets from a tower (not on cooldown).
function tickets.canEarnTickets(player: Player, towerAcronym: string): (boolean, number?)
	if not TicketConfig.enabled then
		return false, nil
	end

	local override = TicketConfig.towerOverrides[towerAcronym]

	if override and override.allowRebeats then
		return true, nil
	end

	local data = accounts.getData(player)
	if not data then
		return false, nil
	end

	local cooldowns = data.ticketCooldowns

	local cooldownExpiry = cooldowns[towerAcronym]
	if not cooldownExpiry then
		return true, nil
	end

	local now = os.time()
	if now >= cooldownExpiry then
		return true, nil
	end

	return false, cooldownExpiry - now
end

--- Awards tickets to a player for completing a tower.
function tickets.awardTickets(player: Player, tower: TowerInfo): number
	if not TicketConfig.enabled then
		return 0
	end

	local acronym = tower.folder.Name
	local canEarn = tickets.canEarnTickets(player, acronym)

	if not canEarn then
		return 0
	end

	local reward = tickets.calculateReward(tower)
	if reward == 0 then
		return 0
	end

	accounts.updateAsync(player, function(data: PlayerDataType): boolean
		data.tickets = (data.tickets :: number) + reward

		local override = TicketConfig.towerOverrides[acronym]
		if not (override and override.allowRebeats) then
			data.ticketCooldowns[acronym] = os.time() + TicketConfig.cooldownDuration
		end

		return true
	end)

	return reward
end

--- Gets the current ticket balance for a player.
function tickets.getTickets(player: Player): number
	local data = accounts.getData(player)
	return if data then data.tickets :: number else 0
end

--- Manually adds or removes tickets from a player.
function tickets.modifyTickets(player: Player, amount: number): number
	local newBalance = 0

	accounts.updateAsync(player, function(data: PlayerDataType): boolean
		data.tickets = math.max(0, (data.tickets :: number) + amount)
		newBalance = data.tickets :: number
		return true
	end)

	return newBalance
end

--- Clears a specific tower's cooldown for a player.
function tickets.clearCooldown(player: Player, towerAcronym: string): ()
	accounts.updateAsync(player, function(data: PlayerDataType): boolean
		data.ticketCooldowns[towerAcronym] = nil
		return true
	end)
end

--- Clears all tower cooldowns for a player.
function tickets.clearAllCooldowns(player: Player): ()
	accounts.updateAsync(player, function(data: PlayerDataType): boolean
		data.ticketCooldowns = {}
		return true
	end)
end

return tickets
