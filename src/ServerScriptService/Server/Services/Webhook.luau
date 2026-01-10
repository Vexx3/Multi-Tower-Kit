--[=[
	Sends Discord webhook notifications for tower clears, including boosts and
	formatted time.

	@class Webhook
]=]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameData = ReplicatedStorage.TowerGame.GameData
local Shared = ReplicatedStorage.TowerGame.Shared
local Config = require(GameData.Config)
local Types = require(Shared.Types)
local Util = require(Shared.Util)

local Webhook = {}

-- formats the message to the config and replaces them
local function formatWebhookMessage(
	message: string,
	playerName: string,
	endingName: string,
	difficultyEmoji: string,
	formattedTime: string,
	boostList: string
)
	local formatted = message
		:gsub("{PlayerName}", playerName)
		:gsub("{EndingName}", endingName)
		:gsub("{DifficultyEmoji}", difficultyEmoji or "")
		:gsub("{Time}", formattedTime)

	if boostList ~= "" then
		local boostsMessage = Config.WEBHOOK_BOOSTS_USED:gsub("{BoostList}", boostList)
		formatted = `{formatted}{boostsMessage}`
	end

	return formatted
end

--[=[
	Posts a webhook message for a tower completion if webhooks are enabled.

	@within Webhook
]=]
function Webhook.sendMessage(player: Types.PlayerInfo, endingName: string, difficultyName: string, finalTime: number?)
	if not Config.WEBHOOKS_ENABLED then
		return
	end

	local boostList = Util.formatBoosts(player.BoostItemNames)
	local difficultyInfo = Util.getDifficulty(difficultyName)
	local formattedTime = Util.formatTimer(finalTime or player.TowerTimer)

	local playerName = if Config.USE_DISPLAY_NAME then player.Player.DisplayName else player.Player.Name

	local messageTemplate = if player.AllJumpsMode then Config.WEBHOOK_AJ_MESSAGE else Config.WEBHOOK_NORMAL_MESSAGE
	local message = formatWebhookMessage(
		messageTemplate,
		playerName,
		endingName,
		difficultyInfo.DifficultyEmoji or "",
		formattedTime,
		boostList
	)

	local isSoulCrushing = difficultyInfo.Rating >= 8
	local isAllJumps = player.AllJumpsMode

	local webhookLink
	if isAllJumps then
		webhookLink = HttpService:GetSecret("ALL_JUMPS_WEBHOOK")
	elseif isSoulCrushing then
		webhookLink = HttpService:GetSecret("SC_WEBHOOK")
	else
		webhookLink = HttpService:GetSecret("NORMAL_WEBHOOK")
	end

	local data = {
		["content"] = message,
	}

	local encodedData = HttpService:JSONEncode(data)

	local success, response = pcall(function()
		return HttpService:PostAsync(webhookLink, encodedData)
	end)

	if not success then
		Util.warn(`Failed to send webhook message: {response}`)
	end
end

return Webhook
