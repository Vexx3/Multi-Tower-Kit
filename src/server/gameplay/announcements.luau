--[[
	Game announcements, cross-server messaging, and Discord webhooks.
]]

local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")

local BlinkServer = require("../Network/BlinkServer")
local Config = require("../../shared/constants/config")
local KickMessages = require("../../shared/constants/kickMessages")
local Log = require("../../../Framework/Log")
local Types = require("../../shared/types")
local Util = require("../../shared/utils/util")

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

local announcements = {}

--- Sends a game-wide announcement to all players.
function announcements.gameAnnouncement(message: string, color: Color3, isFancyText: boolean?)
	BlinkServer.GameAnnouncement.FireAll(message, color, isFancyText)
end

--- Kicks a player for anti-cheat violation with a themed message broadcast to the server.
function announcements.antiCheatKick(player: Player, reason: string)
	local kickMessage = KickMessages[math.random(1, #KickMessages)]
	kickMessage = kickMessage:gsub("{Player}", if Config.useDisplayName then player.DisplayName else player.Name)

	announcements.gameAnnouncement(kickMessage, Color3.new(1, 0, 0))
	player:Kick(reason)
end

--- Broadcasts a tower win locally and optionally globally, then posts to the webhook channel.
function announcements.winAnnouncement(
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

--- Subscribes to cross-server win messages.
function announcements.init()
	MessagingService:SubscribeAsync("GlobalWin", onGlobalWinMessage)
end

return announcements
