-- Global configuration for the Multi Tower Kit.

local Types = require("../Types")

type TowerStat = Types.TowerStat

local Config = {
	-- GAME BEHAVIOR

	-- The client and server both track tower time, but only the
	-- server value is authoritative. To prevent desynchronization,
	-- the server periodically sends a corrected timer value to the
	-- client. This setting determines how often (in seconds) the
	-- correction occurs.
	timerSyncInterval = 2,

	-- Interval (in seconds) at which the server verifies whether a
	-- player has touched the required anti-cheat checkpoints.
	checkpointInterval = 0.25,

	-- Minimum time (in seconds) required between player restarts.
	restartCooldown = 1,

	-- Determines whether holding the R key resets the player's
	-- position to the first tower in a tower rush, or preserves
	-- the player's current tower.
	restartResetsTowerRush = true,

	-- COSMETIC SETTINGS

	-- Interval (in seconds) at which winpads should change color.
	winpadInterval = 0.25,

	-- Enables or disables the winpad color-cycling effect.
	winpadsChangeColor = true,

	-- Enables or disables winpad material changes.
	winpadsChangeMaterial = true,

	-- If enabled, player display names are used instead of usernames
	-- in announcements and webhook messages.
	useDisplayName = false,

	-- WARNINGS & SAFETY CHECKS

	-- Warns if a tower contains no checkpoints.
	checkpointsMissingWarning = true,

	-- Warns if a tower does not define a minimum completion time.
	noMinimumTimeWarning = true,

	-- Warns if players spawn with R15 rigs, which may be incompatible
	-- with certain tower elements.
	r15Warning = true,

	-- DATA STORE

	-- When updating the fangame kit make sure before you update the
	-- DATA_STORE_KEY must still be the same as before, otherwise
	-- players will lose all their data!

	-- Keys used for player data storage. The studio key is used when
	-- testing in Roblox Studio.
	dataStoreKey = "Productionagainnnnnnnnnnnn",
	dataStoreKeyStudio = "Test1024617",

	-- WEBHOOKS

	-- Enables/disables outgoing webhook notifications.
	-- Create a webhook in your game settings (create.roblox.com/dashboard/creations) under "Secrets".
	-- Enable HTTP requests for the game.
	-- Secret name must be "SC_WEBHOOK" or "NORMAL_WEBHOOK".
	webhooksEnabled = false,

	-- Template for the standard win announcement webhook.
	webhookNormalMessage = "**{PlayerName}** has beaten **{EndingName} [{DifficultyEmoji}]** in `{Time}`",

	-- Template for the all-jumps win announcement webhook.
	webhookAjMessage = "**{PlayerName}** has all-jumped **{EndingName} [{DifficultyEmoji}]** in `{Time}`",

	-- Template for the message boosts used
	webhookBoostsUsed = "\nUsed: {BoostList}",

	-- ADMINISTRATION

	-- Role-based permission configuration. Each role defines a list
	-- of permissions granted to users assigned to that role.
	roles = {
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
	userRoles = {
		[949649253] = { "super-user" },
		[3471772640] = { "super-user" },
	},

	-- The keyboard hotkey used to open the admin console UI.
	adminHotkey = Enum.KeyCode.F4,
}

return Config
