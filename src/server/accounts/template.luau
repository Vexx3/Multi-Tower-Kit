--[[
	Default player data template — the starting data every new player gets.

	## WHEN TO EDIT THIS FILE

	Edit this file when you want to:
	- Change default player settings (e.g., default music volume)
	- Add a new saved field to player data (e.g., a currency, a cosmetic toggle)

	## IMPORTANT: Adding New Fields

	If you add a new field here:
	1. Also add it to the `PlayerData` type in `src/shared/types.luau`
	2. Also add a migration in `src/server/accounts/store.luau` so existing
	   players get the new field without losing their data.

	## WARNING

	Removing or renaming fields will break existing player data.
	Always ADD new fields rather than changing existing ones.
]]

local Types = require("../../shared/types")

type TowerStat = Types.TowerStat
export type Settings = Types.Settings
export type PlayerData = Types.PlayerData

local PlayerDataTemplate: PlayerData = {
	--== Progression Stats ==--
	towers = 0, -- total normal tower completions
	allJumps = 0, -- total all-jumps completions
	completedTowers = {}, -- list of tower acronyms beaten (normal)
	completedAjTowers = {}, -- list of tower acronyms beaten (all-jumps)
	towerStats = {}, -- per-tower detailed stats (attempts, wins, times)
	completedTowerRushes = {}, -- list of completed rush acronyms
	towerRushStats = {}, -- per-rush detailed stats

	--== Ticket Currency ==--
	tickets = 0, -- current ticket balance
	ticketCooldowns = {}, -- tower -> timestamp of when cooldown expires

	--== Player Settings (saved per-player) ==--
	settings = {
		-- Gameplay
		quickResetDelay = 1, -- seconds to hold R before restarting
		resetOnDeath = false, -- auto-restart tower on death?
		highFPSPhysicsFix = false, -- fix physics at high framerates
		utility = "Off", -- "Off" | "Emote" | "Alignment"

		-- Visuals
		towerLoadingBehavior = "Load All", -- "Load All" | "Unload Towers" | "Unload All"
		fpsDisplay = false, -- show FPS counter?
		hideTimer = false, -- hide the tower timer?
		invisiblePlayers = "Off", -- "Off" | "Not Friended" | "Everyone Else" | "Near"
		keyDisplayLimit = 5, -- max key indicators on screen
		hideBubbleChat = false, -- hide bubble chat above players?

		-- Audio
		musicVolume = 0.5, -- 0 (mute) to 1 (full volume)

		-- Keybinds (single key names)
		keybinds = {
			quickRestart = "R",
			cornerFlip = "F",
			createCheckpoint = "C",
			teleportCheckpoint = "V",
			removeCheckpoint = "X",
			playAnimation = "G",
		},

		-- Misc
		extendedCompletions = false, -- show extra completion stats?
	},
}

return PlayerDataTemplate
