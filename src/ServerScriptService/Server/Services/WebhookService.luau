--[[
	Sends Discord webhook notifications for tower clears.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.TowerGame.Shared
local Data = Shared.Data
local Framework = ReplicatedStorage.Framework

local Config = require(Data.Config)
local Log = require(Framework.Log)
local Types = require(Shared.Types)
local Util = require(Shared.Util)

local function formatWebhookMessage(
	message: string,
	playerName: string,
	endingName: string,
	difficultyEmoji: string,
	formattedTime: string,
	boostList: string
): string
	local formatted = message
		:gsub("{PlayerName}", playerName)
		:gsub("{EndingName}", endingName)
		:gsub("{DifficultyEmoji}", difficultyEmoji or "")
		:gsub("{Time}", formattedTime)

	if boostList ~= "" then
		local boostsMessage = Config.webhookBoostsUsed:gsub("{BoostList}", boostList)
		formatted = `{formatted}{boostsMessage}`
	end

	return formatted
end

local WebhookService = {}

--- Posts a webhook message for a tower completion if webhooks are enabled.
--- @param player PlayerInfo -- The player who completed the tower
--- @param endingName string -- The name of the ending/tower completed
--- @param difficultyName string -- The difficulty tier of the completion
--- @param finalTime number? -- Optional override for the completion time
function WebhookService.sendMessage(
	player: Types.PlayerInfo,
	endingName: string,
	difficultyName: string,
	finalTime: number?
)
	if not Config.webhooksEnabled then
		return
	end

	local boostList = Util.formatBoosts(player.boostItemNames)
	local difficultyInfo = Util.getDifficulty(difficultyName)
	local formattedTime = Util.formatTimer(finalTime or player.towerTimer)
	local playerName = if Config.useDisplayName then player.player.DisplayName else player.player.Name

	local isAllJumps = player.mode == "AllJumps"
	local messageTemplate = if isAllJumps then Config.webhookAjMessage else Config.webhookNormalMessage
	local message = formatWebhookMessage(
		messageTemplate,
		playerName,
		endingName,
		difficultyInfo.difficultyEmoji or "",
		formattedTime,
		boostList
	)

	local isSoulCrushing = difficultyInfo.rating >= 8

	local webhookLink
	if isAllJumps then
		webhookLink = HttpService:GetSecret("ALL_JUMPS_WEBHOOK")
	elseif isSoulCrushing then
		webhookLink = HttpService:GetSecret("SC_WEBHOOK")
	else
		webhookLink = HttpService:GetSecret("NORMAL_WEBHOOK")
	end

	local data = { content = message }
	local encodedData = HttpService:JSONEncode(data)

	local success, response = pcall(HttpService.PostAsync, HttpService, webhookLink, encodedData)
	if not success then
		Log({ `Failed to send webhook message: {response}` })
	end
end

return WebhookService
