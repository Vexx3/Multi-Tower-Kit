--[[
	Default player data template used for new players.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.TowerGame.Shared.Types)

type TowerStat = Types.TowerStat
export type Settings = Types.Settings
export type PlayerData = Types.PlayerData

local PlayerDataTemplate: PlayerData = {
	towers = 0,
	allJumps = 0,
	completedTowers = {},
	completedAjTowers = {},
	towerStats = {},
	completedTowerRushes = {},
	towerRushStats = {},
	-- Ticket system
	tickets = 0,
	ticketCooldowns = {},
	settings = {
		-- Gameplay
		quickResetDelay = 1, -- seconds
		resetOnDeath = false,
		highFPSPhysicsFix = false,
		utility = "Off", -- "Off", "Emote", "Alignment"
		-- Visuals
		lowDetailMode = "Off", -- "Off", "On", "Ultra"
		fpsDisplay = false,
		hideTimer = false,
		invisiblePlayers = "Off", -- "Off", "Not Friended", "Everyone Else", "Near"
		keyDisplayLimit = 5, -- number of keys to show
		hideBubbleChat = false,
		-- Audio
		musicVolume = 0.5, -- 0 to 1
		-- Keybinds
		keybinds = {
			quickRestart = "R",
			cornerFlip = "F",
			createCheckpoint = "C",
			teleportCheckpoint = "V",
			removeCheckpoint = "X",
			playAnimation = "G",
		},
		-- Misc
		extendedCompletions = false,
	},
}

return PlayerDataTemplate
