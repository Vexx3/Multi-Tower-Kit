-- Global configuration for the Multi Tower Kit.
-- Contains all server and shared configuration values.

local Types = require("../Types")

local Config: Types.GlobalConfig = {
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

	-- Interval (in seconds) at which winpads should change color.
	winpadInterval = 0.25,

	-- Enables or disables the winpad color-cycling effect.
	winpadsChangeColor = true,

	-- Enables or disables winpad material changes.
	winpadsChangeMaterial = true,

	-- If enabled, player display names are used instead of usernames
	-- in announcements and webhook messages.
	useDisplayName = false,

	-- Warns if a tower contains no checkpoints.
	checkpointsMissingWarning = true,

	-- Warns if a tower does not define a minimum completion time.
	noMinimumTimeWarning = true,

	-- Warns if players spawn with R15 rigs, which may be incompatible
	-- with certain tower elements.
	r15Warning = true,

	-- Keys used for player data storage. The studio key is used when
	-- testing in Roblox Studio.
	-- WARNING: Do not change these keys after release or players will lose data!
	dataStoreKey = "Productionagainnnnnnnnnnnn",
	dataStoreKeyStudio = "Test1024617",

	-- Enables/disables outgoing webhook notifications.
	-- Create a webhook in your game settings under "Secrets".
	-- Enable HTTP requests for the game.
	-- Secret name must be "SC_WEBHOOK" or "NORMAL_WEBHOOK".
	webhooksEnabled = false,

	-- Template for the standard win announcement webhook.
	webhookNormalMessage = "**{PlayerName}** has beaten **{EndingName} [{DifficultyEmoji}]** in `{Time}`",

	-- Template for the all-jumps win announcement webhook.
	webhookAjMessage = "**{PlayerName}** has all-jumped **{EndingName} [{DifficultyEmoji}]** in `{Time}`",

	-- Template for the message boosts used.
	webhookBoostsUsed = "\nUsed: {BoostList}",

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
		player = {},
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
