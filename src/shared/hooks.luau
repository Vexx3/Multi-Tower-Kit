--[[
	Hooks — Simple event system for extending Multi-Tower Kit.

	This module lets you react to game events (tower loaded, player won, etc.)
	WITHOUT modifying any core files. Just require this module and register
	your callbacks.

	## Quick Start

	```luau
	local Hooks = require("path/to/shared/hooks")

	-- Run custom code whenever a player loads into a tower
	Hooks.on("TowerLoaded", function(player: Player, towerName: string)
		print(player.Name, "entered", towerName)
	end)

	-- Run custom code whenever a player wins a tower
	Hooks.on("TowerWon", function(player: Player, towerName: string, time: number, isAllJumps: boolean)
		print(player.Name, "beat", towerName, "in", time, "seconds!")
	end)
	```

	## Available Events

	| Event Name          | Arguments                                                    | When It Fires                         |
	|---------------------|--------------------------------------------------------------|---------------------------------------|
	| `TowerLoaded`       | `player: Player, towerName: string`                          | A player enters/restarts a tower      |
	| `TowerWon`          | `player: Player, towerName: string, time: number, isAllJumps: boolean` | A player beats a tower     |
	| `TowerRushCompleted`| `player: Player, rushName: string, time: number`             | A player completes a tower rush       |
	| `CustomZoneTouched` | `player: Player, zoneName: string, part: BasePart`           | A player touches a custom zone        |

	## Tips

	- You can register multiple callbacks for the same event.
	- Callbacks run in the order they were registered.
	- Errors in one callback won't break other callbacks.
	- Use Roblox's built-in `Players.PlayerAdded` / `Players.PlayerRemoving` for join/leave events.
]]

local Log = require("../../Framework/Log")

type Callback = (...any) -> ()

local listeners: { [string]: { Callback }? } = {}

local Hooks = {}

--- Register a callback for a game event.
function Hooks.on(eventName: string, callback: Callback)
	if not listeners[eventName] then
		listeners[eventName] = {}
	end
	table.insert(listeners[eventName], callback)
end

--- Remove a previously registered callback.
function Hooks.off(eventName: string, callback: Callback)
	local list = listeners[eventName]
	if not list then
		return
	end

	for i = #list, 1, -1 do
		if list[i] == callback then
			table.remove(list, i)
			break
		end
	end
end

--- Fire an event, calling all registered callbacks.
--- Used internally by the kit — you normally don't call this yourself.
function Hooks.fire(eventName: string, ...: any)
	local list = listeners[eventName]
	if not list then
		return
	end

	for _, callback in list do
		local ok, err = pcall(callback, ...)
		if not ok then
			Log({
				type = "warn",
				[1] = `Hook "{eventName}" callback error: {err}`,
			})
		end
	end
end

--- Remove all callbacks for a specific event, or all events if nil.
function Hooks.clear(eventName: string?)
	if eventName then
		listeners[eventName] = nil
	else
		table.clear(listeners)
	end
end

return Hooks
