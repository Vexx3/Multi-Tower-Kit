-- Handles in-server announcements, cross-server global win messages,
-- and anti-cheat kick broadcasts.

local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.TowerGame.Shared
local Data = Shared.Data

local BlinkServer = require("../Network/BlinkServer")
local Config = require(Data.Config)
local KickMessages = require(Data.KickMessages)
local Types = require(Shared.Types)
local Util = require(Shared.Util)
local WebhookService = require("./WebhookService")

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

local AnnouncementService = {}

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

function AnnouncementService.gameAnnouncement(message: string, color: Color3, isFancyText: boolean?)
	BlinkServer.GameAnnouncement.FireAll(message, color, isFancyText)
end

-- Kicks a player for anti-cheat with a themed message broadcast to the server.
function AnnouncementService.antiCheatKick(player: Player, reason: string)
	local kickMessage = KickMessages[math.random(1, #KickMessages)]
	kickMessage = kickMessage:gsub("{Player}", if Config.useDisplayName then player.DisplayName else player.Name)

	AnnouncementService.gameAnnouncement(kickMessage, Color3.new(1, 0, 0))
	player:Kick(reason)
end

-- Broadcasts a tower win locally and optionally globally, then posts to the
-- webhook channel.
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
	task.spawn(WebhookService.sendMessage, player, endingName, difficultyName, finalTime)
end

function AnnouncementService.init()
	MessagingService:SubscribeAsync("GlobalWin", onGlobalWinMessage)
end

return AnnouncementService
