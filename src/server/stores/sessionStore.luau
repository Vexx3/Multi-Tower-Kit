--[[
	Server-side player session state using Reflex producer.
	Provides access to per-player runtime info (tower, timer, mode, etc.).

	Uses Reflex createProducer for structured, immutable state management
	with named actions. Each action is a pure function that receives the
	current state and returns the next state.
]]

local Reflex = require("../../../Packages/reflex")
local Types = require("../../shared/types")

type PlayerInfo = Types.PlayerInfo
type SessionState = { [string]: PlayerInfo }

local INITIAL_STATE: SessionState = {}

local producer = Reflex.createProducer(INITIAL_STATE, {
	add = function(state: SessionState, playerName: string, info: PlayerInfo): SessionState
		local newState = table.clone(state)
		newState[playerName] = info
		return newState
	end,

	remove = function(state: SessionState, playerName: string): SessionState
		local newState = table.clone(state)
		newState[playerName] = nil
		return newState
	end,

	update = function(state: SessionState, playerName: string, updates: { [string]: any }): SessionState
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
	end,

	setTower = function(state: SessionState, playerName: string, towerName: string, resetTimer: boolean): SessionState
		local session = state[playerName]
		if not session then
			return state
		end

		local newSession = table.clone(session)
		newSession.currentTower = towerName
		newSession.currentCheckpoint = 1
		newSession.isLoadingTower = true

		if resetTimer then
			newSession.towerTimer = 0
			newSession.boostItemUsed = false
			newSession.boostItemNames = {}
		end

		local newState = table.clone(state)
		newState[playerName] = newSession
		return newState
	end,

	resetRun = function(state: SessionState, playerName: string): SessionState
		local session = state[playerName]
		if not session then
			return state
		end

		local newSession = table.clone(session)
		newSession.towerTimer = 0
		newSession.currentTower = ""
		newSession.currentCheckpoint = 0
		newSession.currentTowerRush = ""
		newSession.currentTowerRushIndex = 0
		newSession.currentTowerRushSplitTime = 0
		newSession.boostItemNames = {}
		newSession.boostItemUsed = false
		newSession.debugItemUsed = false

		local newState = table.clone(state)
		newState[playerName] = newSession
		return newState
	end,

	setMode = function(state: SessionState, playerName: string, mode: Types.PlayerMode): SessionState
		local session = state[playerName]
		if not session then
			return state
		end

		local newSession = table.clone(session)
		newSession.mode = mode

		local newState = table.clone(state)
		newState[playerName] = newSession
		return newState
	end,

	advanceCheckpoint = function(state: SessionState, playerName: string): SessionState
		local session = state[playerName]
		if not session then
			return state
		end

		local newSession = table.clone(session)
		newSession.currentCheckpoint = session.currentCheckpoint + 1

		local newState = table.clone(state)
		newState[playerName] = newSession
		return newState
	end,

	setTouchBusy = function(state: SessionState, playerName: string, busy: boolean): SessionState
		local session = state[playerName]
		if not session then
			return state
		end

		local newSession = table.clone(session)
		newSession.touchEventBusy = busy

		local newState = table.clone(state)
		newState[playerName] = newSession
		return newState
	end,

	finishLoading = function(state: SessionState, playerName: string): SessionState
		local session = state[playerName]
		if not session then
			return state
		end

		local newSession = table.clone(session)
		newSession.isLoadingTower = false

		local newState = table.clone(state)
		newState[playerName] = newSession
		return newState
	end,

	incrementTimers = function(state: SessionState, deltaTime: number): SessionState
		local newState: SessionState = {}
		for name, session in state do
			local newSession = table.clone(session)
			newSession.gameTimer += deltaTime
			if newSession.currentTower ~= "" then
				newSession.towerTimer += deltaTime
			end
			newState[name] = newSession
		end
		return newState
	end,
})

-- Convenience getters that wrap producer.getState()
local function get(playerName: string): PlayerInfo?
	return producer.getState()[playerName]
end

local function getAll(): SessionState
	return producer.getState()
end

return {
	-- Read
	get = get,
	getAll = getAll,
	-- Actions (dispatched through the producer)
	add = function(playerName: string, info: PlayerInfo)
		producer.add(playerName, info)
	end,
	remove = function(playerName: string)
		producer.remove(playerName)
	end,
	update = function(playerName: string, updates: { [string]: any })
		producer.update(playerName, updates)
	end,
	setTower = function(playerName: string, towerName: string, resetTimer: boolean)
		producer.setTower(playerName, towerName, resetTimer)
	end,
	resetRun = function(playerName: string)
		producer.resetRun(playerName)
	end,
	setMode = function(playerName: string, mode: Types.PlayerMode)
		producer.setMode(playerName, mode)
	end,
	advanceCheckpoint = function(playerName: string)
		producer.advanceCheckpoint(playerName)
	end,
	setTouchBusy = function(playerName: string, busy: boolean)
		producer.setTouchBusy(playerName, busy)
	end,
	finishLoading = function(playerName: string)
		producer.finishLoading(playerName)
	end,
	incrementTimers = function(deltaTime: number)
		producer.incrementTimers(deltaTime)
	end,
	-- Expose the producer for advanced use (subscribe, observe, etc.)
	producer = producer,
}
