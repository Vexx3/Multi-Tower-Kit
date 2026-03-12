--[[
	Server-side player session state using Charm.
	Provides access to per-player runtime info (tower, timer, mode, etc.).
]]

local Charm = require("../../../Packages/charm")
local Types = require("../../shared/types")
local objects = require("../../shared/utils/objects")

type PlayerInfo = Types.PlayerInfo
type SessionState = { [string]: PlayerInfo }

local getSessions, setSessions = Charm.signal({} :: SessionState)

local function get(playerName: string): PlayerInfo?
	return getSessions()[playerName]
end

local function getAll(): SessionState
	return getSessions()
end

local function add(playerName: string, info: PlayerInfo)
	setSessions(objects.set(getSessions(), playerName, info))
end

local function remove(playerName: string)
	setSessions(objects.delete(getSessions(), playerName))
end

local function update(playerName: string, updates: { [string]: any })
	setSessions(objects.update(getSessions(), playerName, function(session)
		return objects.join(session, updates)
	end))
end

local function setTower(playerName: string, towerName: string, resetTimer: boolean)
	setSessions(objects.update(getSessions(), playerName, function(session)
		local newSession = objects.join(session, {
			currentTower = towerName,
			currentCheckpoint = 1,
			isLoadingTower = true,
		})

		if resetTimer then
			newSession = objects.join(newSession, {
				towerTimer = 0,
				boostItemUsed = false,
				boostItemNames = {},
			})
		end

		return newSession
	end))
end

local function resetRun(playerName: string)
	setSessions(objects.update(getSessions(), playerName, function(session)
		return objects.join(session, {
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
	end))
end

local function setMode(playerName: string, mode: Types.PlayerMode)
	setSessions(objects.update(getSessions(), playerName, function(session)
		return objects.set(session, "mode", mode)
	end))
end

local function advanceCheckpoint(playerName: string)
	setSessions(objects.update(getSessions(), playerName, function(session)
		return objects.set(session, "currentCheckpoint", session.currentCheckpoint + 1)
	end))
end

local function setTouchBusy(playerName: string, busy: boolean)
	setSessions(objects.update(getSessions(), playerName, function(session)
		return objects.set(session, "touchEventBusy", busy)
	end))
end

local function finishLoading(playerName: string)
	setSessions(objects.update(getSessions(), playerName, function(session)
		return objects.set(session, "isLoadingTower", false)
	end))
end

local function incrementTimers(deltaTime: number)
	setSessions(objects.map(getSessions(), function(session)
		local newSession = objects.set(session, "gameTimer", session.gameTimer + deltaTime)
		if newSession.currentTower ~= "" then
			newSession = objects.set(newSession, "towerTimer", newSession.towerTimer + deltaTime)
		end
		return newSession
	end))
end

return {
	getSessions = getSessions,
	setSessions = setSessions,
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
