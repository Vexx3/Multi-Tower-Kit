--[[
	Server-side player session state using a Charm atom.
	Provides access to per-player runtime info (tower, timer, mode, etc.).

	Why Charm instead of Reflex?
	This store is a simple key-value dictionary with no selectors,
	subscriptions, or middleware — Charm.atom is the right tool for that.
	Use Reflex (createProducer / combineProducers) when you need slices,
	selectors, server-client sync, or middleware.
]]

local Charm = require("../../../Packages/charm")
local Types = require("../../shared/types")

type PlayerInfo = Types.PlayerInfo

local sessions = Charm.atom({} :: { [string]: PlayerInfo })

local function get(playerName: string): PlayerInfo?
	return sessions()[playerName]
end

local function getAll(): { [string]: PlayerInfo }
	return sessions()
end

local function add(playerName: string, info: PlayerInfo)
	sessions(function(state: { [string]: PlayerInfo })
		local newState = table.clone(state)
		newState[playerName] = info
		return newState
	end)
end

local function remove(playerName: string)
	sessions(function(state: { [string]: PlayerInfo })
		local newState = table.clone(state)
		newState[playerName] = nil
		return newState
	end)
end

local function update(playerName: string, updates: { [string]: any })
	sessions(function(state: { [string]: PlayerInfo })
		local session = state[playerName]
		if not session then
			return state
		end

		local newSession = table.clone(session)
		for key, value in updates do
			(newSession :: any)[key] = value
		end

		local newState = table.clone(state)
		newState[playerName] = newSession
		return newState
	end)
end

local function setTower(playerName: string, towerName: string, resetTimer: boolean)
	local session = get(playerName)
	if not session then
		return
	end

	local updates: { [string]: any } = {
		currentTower = towerName,
		currentCheckpoint = 1,
		isLoadingTower = true,
	}

	if resetTimer then
		updates.towerTimer = 0
		updates.boostItemUsed = false
		updates.boostItemNames = {}
	end

	update(playerName, updates)
end

local function resetRun(playerName: string)
	update(playerName, {
		towerTimer = 0,
		currentTower = "",
		currentCheckpoint = 0,
		currentTowerRush = "",
		currentTowerRushIndex = 0,
		currentTowerRushSplitTime = 0,
		boostItemNames = {},
		boostItemUsed = false,
		debugItemUsed = false,
	})
end

local function setMode(playerName: string, mode: Types.PlayerMode)
	update(playerName, { mode = mode })
end

local function advanceCheckpoint(playerName: string)
	local session = get(playerName)
	if session then
		update(playerName, { currentCheckpoint = session.currentCheckpoint + 1 })
	end
end

local function setTouchBusy(playerName: string, busy: boolean)
	update(playerName, { touchEventBusy = busy })
end

local function finishLoading(playerName: string)
	update(playerName, { isLoadingTower = false })
end

local function incrementTimers(deltaTime: number)
	sessions(function(state: { [string]: PlayerInfo })
		local newState: { [string]: PlayerInfo } = {}
		for name, session in state do
			local newSession = table.clone(session)
			newSession.gameTimer += deltaTime
			if newSession.currentTower ~= "" then
				newSession.towerTimer += deltaTime
			end
			newState[name] = newSession
		end
		return newState
	end)
end

return {
	get = get,
	getAll = getAll,
	add = add,
	remove = remove,
	update = update,
	setTower = setTower,
	resetRun = resetRun,
	setMode = setMode,
	advanceCheckpoint = advanceCheckpoint,
	setTouchBusy = setTouchBusy,
	finishLoading = finishLoading,
	incrementTimers = incrementTimers,
}
