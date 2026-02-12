--[[
	ConfigValidator — Runtime validation for Config using `t` library.
	Validates all config values at startup to catch misconfigurations early.

	When you add a new field to `config.luau`, you MUST also add it to the
	`configSchema` below. If you don't, the game will show an error like:
	  "Config validation failed: unexpected field 'yourNewField'"

	To add a field, just add a line inside `configSchema` like:
	  yourNewField = t.string,      -- for strings
	  yourNewField = t.boolean,     -- for true/false
	  yourNewField = t.number,      -- for numbers
	  yourNewField = positiveNumber, -- for numbers >= 0
]]

local Log = require("../../Framework/Log")
local t = require("../../Packages/t")

-- Schema definitions using t library
local positiveNumber = t.intersection(t.number, t.numberMin(0))

local rolePermissionsCheck = t.array(t.string)
local rolesCheck = t.map(t.string, rolePermissionsCheck)
local userRolesCheck = t.map(t.number, t.array(t.string))

local configSchema = t.strictInterface({
	-- Timer
	timerSyncInterval = positiveNumber,
	restartCooldown = positiveNumber,

	-- Anti-cheat
	checkpointInterval = positiveNumber,

	-- Tower Rush
	restartResetsTowerRush = t.boolean,

	-- Winpad
	winpadInterval = positiveNumber,
	winpadsChangeColor = t.boolean,
	winpadsChangeMaterial = t.boolean,

	-- Announcements
	useDisplayName = t.boolean,

	-- Data Store
	dataStoreKey = t.string,
	dataStoreKeyStudio = t.string,

	-- Webhooks
	webhooksEnabled = t.boolean,
	webhookNormalMessage = t.string,
	webhookAjMessage = t.string,
	webhookBoostsUsed = t.string,

	-- Admin
	adminHotkey = t.EnumItem,
	roles = rolesCheck,
	userRoles = userRolesCheck,

	-- Debug warnings
	checkpointsMissingWarning = t.boolean,
	noMinimumTimeWarning = t.boolean,
	r15Warning = t.boolean,
})

local ConfigValidator = {}

--- Validates the given config table against the schema.
--- @param config any -- The config table to validate
--- @return boolean -- True if valid, false otherwise
--- @return string? -- Error message if invalid
function ConfigValidator.validate(config: any): (boolean, string?)
	return configSchema(config)
end

--- Validates config and logs warnings for any issues.
--- Does not throw - call at startup to surface misconfigurations.
--- @param config any -- The config table to validate
--- @return boolean -- True if valid
function ConfigValidator.validateWithWarnings(config: any): boolean
	local success, errorMessage = configSchema(config)

	if not success then
		-- Provide a beginner-friendly error message
		local hint = ""
		if string.find(errorMessage or "", "unexpected field") then
			hint = "\n  HINT: You added a new field to config.luau but didn't add it to configValidator.luau."
				.. "\n  Open configValidator.luau and add your field to the configSchema table."
		elseif string.find(errorMessage or "", "missing") then
			hint =
				"\n  HINT: A required field is missing from config.luau. Check that you haven't accidentally deleted it."
		end

		Log({ type = "error", [1] = `Config validation failed: {errorMessage}{hint}` })
		return false
	end

	-- Additional semantic checks
	if config.timerSyncInterval < 0.5 then
		Log({ type = "warn", [1] = "timerSyncInterval < 0.5 may cause network spam" })
	end

	if config.checkpointInterval < 0.1 then
		Log({ type = "warn", [1] = "checkpointInterval < 0.1 may impact performance" })
	end

	if #config.dataStoreKey == 0 then
		Log({ type = "warn", [1] = "dataStoreKey is empty - data will not persist" })
	end

	return true
end

--- Validates config and throws if invalid. Use at startup.
--- @param config any -- The config table to validate
function ConfigValidator.assertValid(config: any)
	local success, errorMessage = configSchema(config)
	if not success then
		error(`Invalid Config: {errorMessage}`)
	end
end

return ConfigValidator
