--[[
	Main configuration for Multi Tower Kit.
]]

local Types = require("../Types")

local Config: Types.GlobalConfig = {
	-- TIMER
	timerSyncInterval = 2, -- Seconds between server-client timer sync
	restartCooldown = 1, -- Seconds between restarts

	-- ANTI-CHEAT
	checkpointInterval = 0.25, -- Seconds between checkpoint validation

	-- TOWER RUSH
	restartResetsTowerRush = true, -- true = restart from first tower, false = current tower

	-- WINPAD
	winpadInterval = 0.25,
	winpadsChangeColor = true,
	winpadsChangeMaterial = true,

	-- ANNOUNCEMENTS
	useDisplayName = false, -- Use display names instead of usernames

	-- DATA STORE (WARNING: Changing keys resets all player data!)
	dataStoreKey = "Productionagainnnnnnnnnnnn",
	dataStoreKeyStudio = "Test102461777",

	-- WEBHOOKS (Requires HTTP Requests enabled + secret named "SC_WEBHOOK" or "NORMAL_WEBHOOK" or "ALL_JUMPS_WEBHOOK")
	webhooksEnabled = false,
	webhookNormalMessage = "**{PlayerName}** has beaten **{EndingName} [{DifficultyEmoji}]** in `{Time}`",
	webhookAjMessage = "**{PlayerName}** has all-jumped **{EndingName} [{DifficultyEmoji}]** in `{Time}`",
	webhookBoostsUsed = "\nUsed: {BoostList}",

	-- ADMIN
	adminHotkey = Enum.KeyCode.F4,

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

	-- UserId -> roles ("super-user" = all permissions)
	userRoles = {
		[949649253] = { "super-user" },
		[3471772640] = { "super-user" },
	},

	-- DEBUG WARNINGS
	checkpointsMissingWarning = true,
	noMinimumTimeWarning = true,
	r15Warning = true,
}

return Config
