--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameData = ReplicatedStorage.GameData
local Shared = ReplicatedStorage.Shared
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
		local boostsMessage = Config.WEBHOOK_BOOSTS_USED
			:gsub("{BoostList}", boostList)
		formatted = `{formatted}{boostsMessage}`
	end
	
	return formatted
end

function Webhook:SendMessage(player: Types.PlayerInfo, endingName: string, difficultyName: string)
	if not Config.WEBHOOKS_ENABLED then
		return
	end
	
	local boostList = Util:FormatBoosts(player.BoostItemNames)
	local endingDifficulty = Util:GetDifficulty(difficultyName)
	local formattedTime = Util:FormatTimer(player.TowerTimer)
	
	local playerName = if Config.USE_DISPLAY_NAME then player.Player.DisplayName else player.Player.Name
	
	local message = formatWebhookMessage(
		Config.WEBHOOK_NORMAL_MESSAGE,
		playerName,
		endingName,
		endingDifficulty.DifficultyEmoji or "",
		formattedTime,
		boostList
	)
	
	local isSC = endingDifficulty.GlobalAnnouncement
		
	local webhookLink = 
		if isSC then 
			HttpService:GetSecret("SC_WEBHOOK") 
		else 
			HttpService:GetSecret("NORMAL_WEBHOOK")
	
	local data = {
		["content"] = message
	}
	
	data = HttpService:JSONEncode(data)
	
	local success, response = pcall(function()
		return HttpService:PostAsync(webhookLink, data)
	end)
	
	if not success then
		Util:Warn(`Failed to send webhook message: {response}`)
	end
end

return Webhook
