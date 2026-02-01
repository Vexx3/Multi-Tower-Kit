--[[
	TimerService - Handles game timers, syncs, and checkpoint detection.
	Uses Session for state management with clean helper functions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Data = Shared.Data

local BlinkServer = require("../Network/BlinkServer")
local Config = require(Data.Config)
local PlayerService = require("./PlayerService")
local PlayerState = require("../Player/PlayerState")
local Session = require("../Producers/SessionManager")
local TowerService = require("./TowerService")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

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

	local tower = TowerService.getTower(session.currentTower)
	if not tower then
		return
	end

	local checkpoint = tower.checkpoints[session.currentCheckpoint]
	if not checkpoint then
		return
	end

	local point = character:GetPivot().Position
	if Util.isPointInPart(point, checkpoint) then
		Session.advanceCheckpoint(playerName)
	end
end

local function onStepped(_time: number, deltaTime: number)
	Session.incrementTimers(deltaTime)

	local shouldCheckCheckpoints = crossedInterval(_time, deltaTime, Config.checkpointInterval)

	for playerName, session in PlayerService.getAllSessions() do
		syncTimerIfNeeded(session, deltaTime)
		PlayerState.updatePlayerInfoStats(session)

		if shouldCheckCheckpoints then
			checkCheckpointProgress(playerName, session)
		end
	end
end

local TimerService = {}

function TimerService.Start()
	RunService.Stepped:Connect(onStepped)
end

return TimerService
