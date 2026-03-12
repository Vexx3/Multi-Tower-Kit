--[[
	Game timers, sync, and checkpoint detection.
]]

local RunService = game:GetService("RunService")

local BlinkServer = require("../Network/BlinkServer")
local Config = require("../../shared/constants/config")
local Types = require("../../shared/types")
local Util = require("../../shared/utils/util")
local playerState = require("../lib/playerState")
local players = require("../lib/players")
local sessionStore = require("../stores/sessionStore")
local towers = require("./towers")

--- Helper: Check if interval boundary was crossed
local function crossedInterval(time: number, deltaTime: number, interval: number): boolean
	local prev = math.floor((time - deltaTime) / interval) * interval
	local curr = math.floor(time / interval) * interval
	return curr > prev
end

--- Syncs timer with client if sync interval crossed
local function syncTimerIfNeeded(session: Types.PlayerInfo, deltaTime: number)
	if session.currentTower == "" then
		return
	end

	local oldTimer = session.towerTimer - deltaTime
	if crossedInterval(session.towerTimer, session.towerTimer - oldTimer, Config.timerSyncInterval) then
		BlinkServer.UpdateTowerTimer.Fire(session.player, session.towerTimer)
	end
end

--- Checks and advances checkpoint if player is touching it
local function checkCheckpointProgress(playerName: string, session: Types.PlayerInfo)
	local character = session.player.Character
	if session.currentTower == "" or not character then
		return
	end

	local tower = towers.getTower(session.currentTower)
	if not tower then
		return
	end

	local checkpoint = tower.checkpoints[session.currentCheckpoint]
	if not checkpoint then
		return
	end

	local point = character:GetPivot().Position
	if Util.isPointInPart(point, checkpoint) then
		sessionStore.advanceCheckpoint(playerName)
	end
end

local function onStepped(_time: number, deltaTime: number)
	debug.profilebegin("MTK_ServerStep")

	sessionStore.incrementTimers(deltaTime)

	local shouldCheckCheckpoints = crossedInterval(_time, deltaTime, Config.checkpointInterval)
	local shouldUpdateStats = crossedInterval(_time, deltaTime, Config.timerSyncInterval)

	for playerName, session in players.getAllSessions() do
		syncTimerIfNeeded(session, deltaTime)

		if shouldUpdateStats then
			debug.profilebegin("MTK_UpdatePlayerStats")
			playerState.updatePlayerInfoStats(session)
			debug.profileend()
		end

		if shouldCheckCheckpoints then
			debug.profilebegin("MTK_CheckCheckpoints")
			checkCheckpointProgress(playerName, session)
			debug.profileend()
		end
	end

	debug.profileend()
end

RunService.Stepped:Connect(onStepped)
