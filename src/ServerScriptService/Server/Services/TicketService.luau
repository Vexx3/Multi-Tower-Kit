--[=[
	Handles ticket rewards for tower completions.

	Awards tickets based on difficulty with configurable multipliers,
	cooldowns, and per-tower overrides.

	@class TicketService
	@server
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Data = Shared.Data

local PlayerData = require(script.Parent.Parent.Player.PlayerData)
local TicketConfig = require(Data.TicketConfig)
local Types = require(Shared.Types)

type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo
type PlayerDataType = Types.PlayerData

local TicketService = {}

--[=[
	Calculates the ticket reward for completing a tower.
	Returns 0 if the tower is disabled or difficulty has no base reward.

	@param tower TowerInfo -- The tower that was completed
	@return number -- Ticket amount to award
]=]
function TicketService.calculateReward(tower: TowerInfo): number
	if not TicketConfig.enabled then
		return 0
	end

	local acronym = tower.folder.Name
	local override = TicketConfig.towerOverrides[acronym]

	-- Check if tower is disabled from giving tickets
	if override and override.disabled then
		return 0
	end

	-- Get base reward for difficulty
	local baseReward = TicketConfig.baseRewards[tower.difficulty] or 0
	if baseReward == 0 then
		return 0
	end

	-- Apply multiplier if specified
	local multiplier = if override and override.multiplier then override.multiplier else 1.0

	return math.floor(baseReward * multiplier)
end

--[=[
	Checks if a player can earn tickets from a tower (not on cooldown).

	@param player Player -- The player to check
	@param towerAcronym string -- The tower acronym
	@return boolean -- True if player can earn tickets
	@return number? -- Seconds remaining on cooldown (if on cooldown)
]=]
function TicketService.canEarnTickets(player: Player, towerAcronym: string): (boolean, number?)
	if not TicketConfig.enabled then
		return false, nil
	end

	local override = TicketConfig.towerOverrides[towerAcronym]

	-- Check if tower allows rebeats (ignores cooldown)
	if override and override.allowRebeats then
		return true, nil
	end

	local data = PlayerData.getData(player)
	if not data then
		return false, nil
	end

	local cooldowns = data.ticketCooldowns
	if not cooldowns then
		return true, nil
	end

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

--[=[
	Awards tickets to a player for completing a tower.
	Handles cooldown checks and updates.

	@param player Player -- The player to award tickets to
	@param tower TowerInfo -- The tower that was completed
	@return number -- Amount of tickets awarded (0 if on cooldown or disabled)
]=]
function TicketService.awardTickets(player: Player, tower: TowerInfo): number
	if not TicketConfig.enabled then
		return 0
	end

	local acronym = tower.folder.Name
	local canEarn = TicketService.canEarnTickets(player, acronym)

	if not canEarn then
		return 0
	end

	local reward = TicketService.calculateReward(tower)
	if reward == 0 then
		return 0
	end

	-- Update player data
	PlayerData.updateAsync(player, function(data: PlayerDataType): boolean
		data.tickets = (data.tickets :: number) + reward

		-- Set cooldown (unless tower allows rebeats)
		local override = TicketConfig.towerOverrides[acronym]
		if not (override and override.allowRebeats) then
			if not data.ticketCooldowns then
				data.ticketCooldowns = {}
			end
			data.ticketCooldowns[acronym] = os.time() + TicketConfig.cooldownDuration
		end

		return true
	end)

	return reward
end

--[=[
	Gets the current ticket balance for a player.

	@param player Player -- The player to check
	@return number -- Current ticket count
]=]
function TicketService.getTickets(player: Player): number
	local data = PlayerData.getData(player)
	return if data then data.tickets :: number else 0
end

--[=[
	Manually adds or removes tickets from a player (for admin/shop use).

	@param player Player -- The player to modify
	@param amount number -- Amount to add (negative to remove)
	@return number -- New ticket balance
]=]
function TicketService.modifyTickets(player: Player, amount: number): number
	local newBalance = 0

	PlayerData.updateAsync(player, function(data: PlayerDataType): boolean
		data.tickets = math.max(0, (data.tickets :: number) + amount)
		newBalance = data.tickets :: number
		return true
	end)

	return newBalance
end

--[=[
	Clears a specific tower's cooldown for a player.

	@param player Player -- The player to modify
	@param towerAcronym string -- The tower to clear cooldown for
]=]
function TicketService.clearCooldown(player: Player, towerAcronym: string): ()
	PlayerData.updateAsync(player, function(data: PlayerDataType): boolean
		if data.ticketCooldowns then
			data.ticketCooldowns[towerAcronym] = nil
		end
		return true
	end)
end

--[=[
	Clears all tower cooldowns for a player.

	@param player Player -- The player to modify
]=]
function TicketService.clearAllCooldowns(player: Player): ()
	PlayerData.updateAsync(player, function(data: PlayerDataType): boolean
		data.ticketCooldowns = {}
		return true
	end)
end

--- Initializes the ticket service.
function TicketService.Start()
	-- No initialization needed currently
end

return TicketService
