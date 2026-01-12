local Types = require("../Shared/Types")

type TowerStat = Types.TowerStat

--==============================================================--
--                     Multi-Tower Kit Configuration
--==============================================================--

local Config = {

	----------------------------------------------------------------
	-- GAME BEHAVIOR
	----------------------------------------------------------------

	--[[
		The client and server both track tower time, but only the
		server value is authoritative. To prevent desynchronization,
		the server periodically sends a corrected timer value to the
		client. This setting determines how often (in seconds) the
		correction occurs.
	]]
	TIMER_SYNC_INTERVAL = 2,

	-- Interval (in seconds) at which the server verifies whether a
	-- player has touched the required anti-cheat checkpoints.
	CHECKPOINT_INTERVAL = 0.25,

	-- Minimum time (in seconds) required between player restarts.
	RESTART_COOLDOWN = 1,

	--[[
		Determines whether holding the R key resets the player's
		position to the first tower in a tower rush, or preserves
		the player's current tower.
	]]
	RESTART_RESETS_TOWER_RUSH = true,

	----------------------------------------------------------------
	-- COSMETIC SETTINGS
	----------------------------------------------------------------

	-- Interval (in seconds) at which winpads should change color.
	WINPAD_INTERVAL = 0.25,

	-- Enables or disables the winpad color-cycling effect.
	WINPADS_CHANGE_COLOR = true,

	-- Enables or disables winpad material changes.
	WINPADS_CHANGE_MATERIAL = true,

	-- If enabled, player display names are used instead of usernames
	-- in announcements and webhook messages.
	USE_DISPLAY_NAME = false,

	----------------------------------------------------------------
	-- WARNINGS & SAFETY CHECKS
	----------------------------------------------------------------

	-- Suppresses all warning messages. Not recommended for most
	-- development environments.
	QUIET = false,

	-- Warns if tower checkpoints are stored inside Workspace rather
	-- than the expected container.
	CHECKPOINTS_WORKSPACE_WARNING = true,

	-- Warns if a tower contains no checkpoints.
	CHECKPOINTS_MISSING_WARNING = true,

	-- Warns if a tower does not define a minimum completion time.
	NO_MINIMUM_TIME_WARNING = true,

	-- Warns if players spawn with R15 rigs, which may be incompatible
	-- with certain tower elements.
	R15_WARNING = true,

	----------------------------------------------------------------
	-- DATA STORE
	----------------------------------------------------------------

	-- When updating the fangame kit make sure before you update the
	-- DATA_STORE_KEY must still be the same as before, otherwise
	-- players will lose all their data!

	-- Keys used for player data storage. The studio key is used when
	-- testing in Roblox Studio.
	DATA_STORE_KEY = "Productionagainnnnnnn",
	DATA_STORE_KEY_STUDIO = "Test1024",

	-- Default player data template. Only modify this if you fully
	-- understand the implications on data structure and migration.
	DEFAULT_PLAYER_DATA = {
		Towers = 0,
		AllJumps = 0,
		CompletedTowers = {} :: { string },
		CompletedAJTowers = {} :: { string },
		TowerStats = {} :: { [string]: TowerStat },
		CompletedTowerRushes = {} :: { string },
		TowerRushStats = {} :: { [string]: TowerStat },
	},

	----------------------------------------------------------------
	-- WEBHOOKS
	----------------------------------------------------------------

	-- Enables/disables outgoing webhook notifications.
	-- Create a webhook in your game settings (create.roblox.com/dashboard/creations) under "Secrets".
	-- Enable HTTP requests for the game.
	-- Secret name must be "SC_WEBHOOK" or "NORMAL_WEBHOOK".
	WEBHOOKS_ENABLED = false,

	-- Template for the standard win announcement webhook.
	WEBHOOK_NORMAL_MESSAGE = "**{PlayerName}** has beaten **{EndingName} [{DifficultyEmoji}]** in `{Time}`",

	-- Template for the all-jumps win announcement webhook.
	WEBHOOK_AJ_MESSAGE = "**{PlayerName}** has all-jumped **{EndingName} [{DifficultyEmoji}]** in `{Time}`",

	-- Template for the message boosts used
	WEBHOOK_BOOSTS_USED = "\nUsed: {BoostList}",

	----------------------------------------------------------------
	-- ADMINISTRATION
	----------------------------------------------------------------

	-- Role-based permission configuration. Each role defines a list
	-- of permissions granted to users assigned to that role.
	ROLES = {
		admin = {
			"kick-player",
			"ban-player",
			"teleport-player",
			"manage-tower",
			"give-badge",
			"give-item",
			"fake-win",
			"shutdown-server",
		},
		player = {}, -- Default role with no special permissions.
	},

	-- Maps UserIds to roles. The "super-user" role grants universal
	-- access to all registered permissions.
	USER_ROLES = {
		[949649253] = { "super-user" },
		[3471772640] = { "super-user" },
	},

	-- The keyboard hotkey used to open the admin console UI.
	ADMIN_HOTKEY = Enum.KeyCode.F4,
}

export type PlayerData = typeof(Config.DEFAULT_PLAYER_DATA)

return Config
