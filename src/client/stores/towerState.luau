--[[
	TowerState - Client tower state using Charm atom.

	Charm atom API:
	- atom()               reads current state
	- atom(newState)       replaces state
	- atom(fn)             updates via fn(current) -> new
	- Charm.subscribe(atom, listener) to listen for changes
]]

local Charm = require("../../../Packages/charm")

export type TowerStateData = {
	currentTower: string,
	towerTimer: number,
	rushIndex: number,
	rushTotal: number,
	isBoostUsed: boolean,
	restartProgress: number,
}

local DEFAULT: TowerStateData = {
	currentTower = "",
	towerTimer = 0,
	rushIndex = 0,
	rushTotal = 0,
	isBoostUsed = false,
	restartProgress = 0,
}

local atom = Charm.atom(table.clone(DEFAULT))

return {
	atom = atom,
	DEFAULT = DEFAULT,
}
