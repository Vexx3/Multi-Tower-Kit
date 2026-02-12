--[[
	TowerState - Client tower state using Charm atom.
	
	Charm usage:
	- atom() to read state
	- atom(newState) to replace state  
	- atom(fn) to update (fn receives current, returns new)
	- Charm.subscribe(atom, callback) to listen
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

-- Export both atom and helpers as a module
return {
	atom = atom,
	DEFAULT = DEFAULT,
}
