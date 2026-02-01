--[[
	SessionManager - Server-side player session state using Reflex.
	Uses producer.subscribe() for reacting to state changes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage.TowerGame.Shared

local Reflex = require(Packages.reflex)
local Types = require(Shared.Types)

type PlayerInfo = Types.PlayerInfo
type SessionState = { sessions: { [string]: PlayerInfo } }

local initialState: SessionState = { sessions = {} }

local producer = Reflex.createProducer(initialState, {
	addSession = function(state: SessionState, playerName: string, info: PlayerInfo): SessionState
		local newSessions = table.clone(state.sessions)
		newSessions[playerName] = info
		return { sessions = newSessions }
	end,

	removeSession = function(state: SessionState, playerName: string): SessionState
		local newSessions = table.clone(state.sessions)
		newSessions[playerName] = nil
		return { sessions = newSessions }
	end,

	updateSession = function(state: SessionState, playerName: string, updates: { [string]: any }): SessionState
		local session = state.sessions[playerName]
		if not session then
			return state
		end

		local newSession = table.clone(session)
		for key, value in updates do
			(newSession :: any)[key] = value
		end

		local newSessions = table.clone(state.sessions)
		newSessions[playerName] = newSession
		return { sessions = newSessions }
	end,

	incrementTimers = function(state: SessionState, deltaTime: number): SessionState
		local newSessions: { [string]: PlayerInfo } = {}
		for name, session in state.sessions do
			local newSession = table.clone(session)
			newSession.gameTimer += deltaTime
			if newSession.currentTower ~= "" then
				newSession.towerTimer += deltaTime
			end
			newSessions[name] = newSession
		end
		return { sessions = newSessions }
	end,
})

local SessionManager = {}

function SessionManager.get(playerName: string): PlayerInfo?
	return producer.getState().sessions[playerName]
end

function SessionManager.getAll(): { [string]: PlayerInfo }
	return producer.getState().sessions
end

function SessionManager.add(playerName: string, info: PlayerInfo)
	producer.addSession(playerName, info)
end

function SessionManager.remove(playerName: string)
	producer.removeSession(playerName)
end

function SessionManager.update(playerName: string, updates: { [string]: any })
	producer.updateSession(playerName, updates)
end

function SessionManager.setTower(playerName: string, towerName: string, resetTimer: boolean)
	local session = SessionManager.get(playerName)
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

	producer.updateSession(playerName, updates)
end

function SessionManager.resetRun(playerName: string)
	producer.updateSession(playerName, {
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

function SessionManager.setMode(playerName: string, mode: Types.PlayerMode)
	producer.updateSession(playerName, { mode = mode })
end

function SessionManager.advanceCheckpoint(playerName: string)
	local session = SessionManager.get(playerName)
	if session then
		producer.updateSession(playerName, { currentCheckpoint = session.currentCheckpoint + 1 })
	end
end

function SessionManager.setTouchBusy(playerName: string, busy: boolean)
	producer.updateSession(playerName, { touchEventBusy = busy })
end

function SessionManager.finishLoading(playerName: string)
	producer.updateSession(playerName, { isLoadingTower = false })
end

function SessionManager.incrementTimers(deltaTime: number)
	producer.incrementTimers(deltaTime)
end

return SessionManager
