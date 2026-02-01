--[[
	AnnouncementService - Handles all game announcements and notifications.
	Includes in-game broadcasts, cross-server messaging, and Discord webhooks.
	Merged from AnnouncementService + WebhookService.
]]

local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.TowerGame.Shared
local Data = Shared.Data
local Framework = ReplicatedStorage.Framework

local BlinkServer = require("../Network/BlinkServer")
local Config = require(Data.Config)
local KickMessages = require(Data.KickMessages)
local Log = require(Framework.Log)
local Types = require(Shared.Types)
local Util = require(Shared.Util)

type Dictionary<T> = Types.Dictionary<T>
type PlayerInfo = Types.PlayerInfo

type WinMessageInfo = {
	messageId: string,
	playerName: string,
	endingName: string,
	difficultyName: string,
	time: number,
	boostsUsed: Dictionary<string>,
	allJumps: boolean,
	global: boolean,
}

type ClientWinMessageInfo = {
	playerName: string,
	endingName: string,
	time: number,
	boostsUsed: Dictionary<string>,
	allJumps: boolean,
	color: Color3,
	fancyFont: boolean,
	global: boolean,
}

type Message = {
	Data: unknown,
	Sent: number,
}

local latestGlobalMessageId = ""

local function broadcastWinAnnouncement(info: WinMessageInfo)
	local difficultyInfo = Util.getDifficulty(info.difficultyName)

	local clientMsgInfo: ClientWinMessageInfo = {
		playerName = info.playerName,
		endingName = info.endingName,
		time = info.time,
		boostsUsed = info.boostsUsed,
		allJumps = info.allJumps,
		color = difficultyInfo.color,
		fancyFont = difficultyInfo.fancyFont,
		global = info.global,
	}

	BlinkServer.GameWinAnnouncement.FireAll(clientMsgInfo)
end

local function onGlobalWinMessage(message: Message)
	local info: WinMessageInfo = message.Data :: WinMessageInfo
	if info.messageId == latestGlobalMessageId then
		return
	end
	broadcastWinAnnouncement(info)
end

-- Webhook message formatting
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

-- Send webhook to Discord
local function sendWebhook(player: PlayerInfo, endingName: string, difficultyName: string, finalTime: number)
	if not Config.webhooksEnabled then
		return
	end

	local boostList = Util.formatBoosts(player.boostItemNames)
	local difficultyInfo = Util.getDifficulty(difficultyName)
	local formattedTime = Util.formatTimer(finalTime)
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

local AnnouncementService = {}

--- Sends a game-wide announcement to all players.
--- @param message string -- The message text to display
--- @param color Color3 -- The color of the announcement text
--- @param isFancyText boolean? -- Whether to use fancy text styling
function AnnouncementService.gameAnnouncement(message: string, color: Color3, isFancyText: boolean?)
	BlinkServer.GameAnnouncement.FireAll(message, color, isFancyText)
end

--- Kicks a player for anti-cheat violation with a themed message broadcast to the server.
--- @param player Player -- The player to kick
--- @param reason string -- The kick reason shown to the player
function AnnouncementService.antiCheatKick(player: Player, reason: string)
	local kickMessage = KickMessages[math.random(1, #KickMessages)]
	kickMessage = kickMessage:gsub("{Player}", if Config.useDisplayName then player.DisplayName else player.Name)

	AnnouncementService.gameAnnouncement(kickMessage, Color3.new(1, 0, 0))
	player:Kick(reason)
end

--- Broadcasts a tower win locally and optionally globally, then posts to the webhook channel.
--- @param player PlayerInfo -- The player info of the winner
--- @param endingName string -- The name of the ending/tower completed
--- @param difficultyName string -- The difficulty tier of the completion
--- @param timeOverride number? -- Optional time to use instead of player's tower timer
function AnnouncementService.winAnnouncement(
	player: PlayerInfo,
	endingName: string,
	difficultyName: string,
	timeOverride: number?
)
	local difficultyInfo = Util.getDifficulty(difficultyName)
	local finalTime = timeOverride or player.towerTimer
	local playerName = if Config.useDisplayName then player.player.DisplayName else player.player.Name

	local isAJ = player.mode == "AllJumps"
	local isGlobal = if isAJ then difficultyInfo.globalAjAnnouncement == true else difficultyInfo.globalAnnouncement

	local info: WinMessageInfo = {
		messageId = HttpService:GenerateGUID(false),
		playerName = playerName,
		endingName = endingName,
		difficultyName = difficultyName,
		time = finalTime,
		boostsUsed = player.boostItemNames,
		allJumps = isAJ,
		global = isGlobal,
	}

	if isGlobal then
		latestGlobalMessageId = info.messageId
		MessagingService:PublishAsync("GlobalWin", info)
	end

	broadcastWinAnnouncement(info)
	task.spawn(sendWebhook, player, endingName, difficultyName, finalTime)
end

--- Initializes the announcement service and subscribes to cross-server messages.
function AnnouncementService.Start()
	MessagingService:SubscribeAsync("GlobalWin", onGlobalWinMessage)
end

return AnnouncementService
