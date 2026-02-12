--[[
	Main configuration for Multi Tower Kit.

	This is the PRIMARY file you'll edit to customize your game's behavior.
	Each setting is grouped by category and documented below.

	TIP: If you add a NEW field here, you must also add it to the schema in
	     `src/shared/configValidator.luau` — otherwise the game will error on startup.
	     (See the configValidator file for instructions.)
]]

local Types = require("../types")

local Config: Types.GlobalConfig = {

	--============================================================--
	--                       TIMER                                --
	--============================================================--

	-- How often (in seconds) the server syncs its timer to clients.
	-- Lower = more accurate on the client, but uses more network traffic.
	-- Recommended: 1–5
	timerSyncInterval = 2,

	-- Minimum seconds between player restarts (prevents restart spam).
	restartCooldown = 1,

	--============================================================--
	--                     ANTI-CHEAT                             --
	--============================================================--

	-- How often (in seconds) the server checks player checkpoints.
	-- Lower = stricter anti-cheat, but slightly higher CPU usage.
	-- Recommended: 0.1–1
	checkpointInterval = 0.25,

	--============================================================--
	--                    TOWER RUSH                               --
	--============================================================--

	-- What happens when a player restarts during a tower rush?
	--   true  = restart from the FIRST tower in the rush
	--   false = restart from the CURRENT tower only
	restartResetsTowerRush = true,

	--============================================================--
	--                      WINPAD                                --
	--============================================================--

	-- How often (in seconds) winpads change color/material (visual flair).
	winpadInterval = 0.25,

	-- Set to false to keep winpads a single color.
	winpadsChangeColor = true,

	-- Set to false to keep winpads a single material.
	winpadsChangeMaterial = true,

	--============================================================--
	--                  ANNOUNCEMENTS                             --
	--============================================================--

	-- Show display names ("CoolPlayer") instead of usernames ("Player123")?
	useDisplayName = false,

	--============================================================--
	--                    DATA STORE                              --
	--============================================================--

	-- WARNING: Changing these keys will RESET ALL PLAYER DATA.
	-- Use different keys for production vs. Studio testing.
	dataStoreKey = "Productionagainnnnnnnnnnnn",
	dataStoreKeyStudio = "Test102461777",

	--============================================================--
	--                    WEBHOOKS                                --
	--============================================================--

	-- Send win announcements to Discord via webhooks.
	-- Requires:
	--   1. HTTP Requests enabled in Game Settings
	--   2. Secrets named "SC_WEBHOOK", "NORMAL_WEBHOOK", or "ALL_JUMPS_WEBHOOK"
	webhooksEnabled = false,

	-- Message templates — available placeholders:
	--   {PlayerName}     — the player's name
	--   {EndingName}     — the tower/ending name
	--   {DifficultyEmoji} — Discord emoji for the difficulty
	--   {Time}           — formatted completion time
	--   {BoostList}      — list of boosts used
	webhookNormalMessage = "**{PlayerName}** has beaten **{EndingName} [{DifficultyEmoji}]** in `{Time}`",
	webhookAjMessage = "**{PlayerName}** has all-jumped **{EndingName} [{DifficultyEmoji}]** in `{Time}`",
	webhookBoostsUsed = "\nUsed: {BoostList}",

	--============================================================--
	--                 ADMIN / PERMISSIONS                        --
	--============================================================--

	-- Hotkey to open the admin command panel (client-side).
	adminHotkey = Enum.KeyCode.F4,

	-- Define roles and what permissions each role has.
	-- You can create any role name you want.
	-- Available permissions: "kick-player", "ban-player", "teleport-player",
	--   "manage-tower", "give-badge", "give-item", "fake-win", "shutdown-server"
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

	-- Assign roles to specific users by their UserId.
	-- "super-user" grants ALL permissions (useful for game owners).
	-- Find your UserId at: https://www.roblox.com/users/YOUR_ID/profile
	userRoles = {
		[949649253] = { "super-user" },
		[3471772640] = { "super-user" },
	},

	--============================================================--
	--                  DEBUG WARNINGS                            --
	--============================================================--

	-- Show a warning if a tower has no checkpoints set up.
	checkpointsMissingWarning = true,

	-- Show a warning if a tower has no MinimumTime (vulnerable to cheating).
	noMinimumTimeWarning = true,

	-- Show a warning if R15 avatars are detected (this kit is R6-focused).
	r15Warning = true,
}

return Config
