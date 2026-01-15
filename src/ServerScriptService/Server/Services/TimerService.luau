-- Handles game timers, syncs, and checkpoint detection.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Data = Shared.Data

local BlinkServer = require("../Network/BlinkServer")
local Config = require(Data.Config)
local PlayerService = require("./PlayerService")
local PlayerState = require("../Player/PlayerState")
local TowerService = require("./TowerService")
local Types = require(Shared.Types)
local Util = require(Shared.Util)

local TimerService = {}

local function onStepped(_time: number, deltaTime: number)
	for _, v in PlayerService.getAllSessions() do
		-- Increment game timer and tower timer
		v.gameTimer += deltaTime
		if v.currentTower ~= "" then
			local tower = TowerService.getTower(v.currentTower)
			if not tower then
				continue
			end

			local oldTowerTimer = v.towerTimer
			v.towerTimer += deltaTime

			-- Sync timer with client periodically
			local i = Config.timerSyncInterval
			local a = math.floor(oldTowerTimer / i) * i
			local b = math.floor(v.towerTimer / i) * i
			if b > a then
				BlinkServer.UpdateTowerTimer.Fire(v.player, v.towerTimer)
			end
		end

		-- Update player attributes
		PlayerState.updatePlayerInfoStats(v)

		-- Checkpoint detection
		local prevInterval = math.floor((_time - deltaTime) / Config.checkpointInterval) * Config.checkpointInterval
		local currentInterval = math.floor(_time / Config.checkpointInterval) * Config.checkpointInterval
		if prevInterval < currentInterval then
			local character = v.player.Character
			if v.currentTower ~= "" and character then
				local tower: Types.TowerInfo? = TowerService.getTower(v.currentTower)
				if not tower then
					continue
				end

				local checkpoint: BasePart? = tower.checkpoints[v.currentCheckpoint]
				if checkpoint then
					local point = character:GetPivot().Position
					local touching = Util.isPointInPart(point, checkpoint)
					if touching then
						v.currentCheckpoint += 1
					end
				end
			end
		end
	end
end

function TimerService.init()
	RunService.Stepped:Connect(onStepped)
end

return TimerService
