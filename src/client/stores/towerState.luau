--[[
	TowerState - Client tower state using Charm signal.
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

local getTowerState, setTowerState = Charm.signal(table.clone(DEFAULT))

return {
	getTowerState = getTowerState,
	setTowerState = setTowerState,
	DEFAULT = DEFAULT,
}
