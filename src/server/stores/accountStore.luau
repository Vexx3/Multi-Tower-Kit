--[[
	Charm signal-based cache for player account data.
	Bridged from Lyra via changedCallbacks in accounts/store.luau.
]]

local Charm = require("../../../Packages/charm")
local Types = require("../../shared/types")
local objects = require("../../shared/utils/objects")

type PlayerData = Types.PlayerData

type Accounts = {
	[string]: PlayerData,
}

local getAccounts, setAccounts = Charm.signal({} :: Accounts)

local function getAccount(username: string): PlayerData?
	return getAccounts()[username]
end

local function setAccount(username: string, account: PlayerData)
	setAccounts(objects.set(getAccounts(), username, account))
end

local function removeAccount(username: string)
	setAccounts(objects.delete(getAccounts(), username))
end

return {
	getAccounts = getAccounts,
	getAccount = getAccount,
	setAccount = setAccount,
	removeAccount = removeAccount,
}
