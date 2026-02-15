--[[
	Settings controller for the MainMenu.
	Provides an API to read and update individual settings values,
	syncing changes to the server via Blink.
]]

local BlinkClient = require("../../../shared/Network/BlinkClient")

local cachedSettings: { [string]: unknown } = {}

local settingsController = {}

--- Initializes settings from incoming player data.
function settingsController.applySettings(settings: { [string]: unknown }?)
	if not settings then
		return
	end

	for key, value in settings do
		cachedSettings[key] = value
	end
end

--- Gets the current value of a setting.
function settingsController.get(key: string): unknown
	return cachedSettings[key]
end

--- Gets the keybinds table.
function settingsController.getKeybinds(): { [string]: string }
	return (cachedSettings.keybinds or {}) :: { [string]: string }
end

--- Updates a single setting value and syncs to the server.
function settingsController.set(key: string, value: unknown)
	cachedSettings[key] = value
	BlinkClient.UpdateSettings.Fire(cachedSettings)
end

--- Updates a single keybind and syncs to the server.
function settingsController.setKeybind(action: string, key: string)
	local keybinds = settingsController.getKeybinds()
	keybinds[action] = key
	cachedSettings.keybinds = keybinds
	BlinkClient.UpdateSettings.Fire(cachedSettings)
end

--- Returns a shallow copy of all current settings.
function settingsController.getAll(): { [string]: unknown }
	return table.clone(cachedSettings)
end

return settingsController
