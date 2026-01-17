--[[
	Ticket rewards for tower completions.
]]

export type TowerTicketOverride = {
	multiplier: number?, -- Multiply base reward (1.5 = 150%)
	allowRebeats: boolean?, -- Ignore cooldown, earn every time
	disabled: boolean?, -- Tower gives no tickets
}

export type TicketConfig = {
	enabled: boolean,
	cooldownDuration: number,
	baseRewards: { [string]: number },
	towerOverrides: { [string]: TowerTicketOverride },
}

local TicketConfig: TicketConfig = {
	enabled = true,
	cooldownDuration = 604800, -- 1 week in seconds (86400 = 1 day)

	-- Tickets awarded per difficulty (0 = disabled)
	baseRewards = {
		Easy = 5,
		Medium = 5,
		Hard = 10,
		Difficult = 10,
		Challenging = 20,
		Intense = 50,
		Remorseless = 150,
		Insane = 250,
		Extreme = 550,
		Terrifying = 1125,
		Catastrophic = 2250,
		Horrific = 0,
		Unreal = 0,
		Nil = 0,
	},

	-- Per-tower overrides: ["Acronym"] = { multiplier, allowRebeats, disabled }
	towerOverrides = {
		-- ["ToH"] = { disabled = true },
		-- ["ToVP"] = { multiplier = 2.0 },
		-- ["ToE"] = { multiplier = 1.5, allowRebeats = true },
	},
}

return TicketConfig
