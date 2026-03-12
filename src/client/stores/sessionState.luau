--[[
	Client-side session state synced from server via Charm-Sync.
]]

local Charm = require("../../../Packages/charm")

local getSession, setSession = Charm.signal(nil)

return {
	getSession = getSession,
	setSession = setSession,
}
