--[=[
	Handles in-server announcements, cross-server global win messages, and
	anti-cheat kick broadcasts.

	@class Announcements
]=]

local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameData = ReplicatedStorage.TowerGame.GameData
local Shared = ReplicatedStorage.TowerGame.Shared

local BlinkServer = require(script.Parent.Parent.Network.BlinkServer)
local Config = require(GameData.Config)
local KickMessages = require(GameData.KickMessages)
local Types = require(Shared.Types)
local Util = require(Shared.Util)
local Webhook = require("./Webhook")

type Dictionary<T> = Types.Dictionary<T>
type PlayerInfo = Types.PlayerInfo

type WinMessageInfo = {
	MessageID: string,
	PlayerName: string,
	EndingName: string,
	DifficultyName: string,
	Time: number,
	BoostsUsed: Dictionary<string>,
	AllJumps: boolean,
	Global: boolean,
}

type ClientWinMessageInfo = {
	PlayerName: string,
	EndingName: string,
	Time: number,
	BoostsUsed: Dictionary<string>,
	AllJumps: boolean,
	Color: Color3,
	FancyFont: boolean,
	Global: boolean,
}

type Message = {
	Data: any,
	Sent: number,
}

local _latestGlobalMessageID = ""

local Announcements = {}

local function _broadcastWinAnnouncement(info: WinMessageInfo)
	local difficultyInfo = Util.getDifficulty(info.DifficultyName)

	local clientMsgInfo: ClientWinMessageInfo = {
		PlayerName = info.PlayerName,
		EndingName = info.EndingName,
		Time = info.Time,
		BoostsUsed = info.BoostsUsed,
		AllJumps = info.AllJumps,
		Color = difficultyInfo.Color,
		FancyFont = difficultyInfo.FancyFont,
		Global = info.Global,
	}

	BlinkServer.GameWinAnnouncement.FireAll(clientMsgInfo)
end

local function _onGlobalWinMessage(message: Message)
	local info: WinMessageInfo = message.Data
	if info.MessageID == _latestGlobalMessageID then
		return
	end
	_broadcastWinAnnouncement(info)
end

--[=[
	Broadcasts a tower win locally and optionally globally, then posts to the
	webhook channel.

	@within Announcements
]=]
function Announcements.winAnnouncement(
	player: PlayerInfo,
	endingName: string,
	difficultyName: string,
	timeOverride: number?
)
	local difficultyInfo = Util.getDifficulty(difficultyName)
	local finalTime = timeOverride or player.TowerTimer

	local playerName = if Config.USE_DISPLAY_NAME then player.Player.DisplayName else player.Player.Name

	local isGlobal = if player.AllJumpsMode
		then difficultyInfo.GlobalAJAnnouncement == true
		else difficultyInfo.GlobalAnnouncement

	local info: WinMessageInfo = {
		MessageID = HttpService:GenerateGUID(false),
		PlayerName = playerName,
		EndingName = endingName,
		DifficultyName = difficultyName,
		Time = finalTime,
		BoostsUsed = player.BoostItemNames,
		AllJumps = player.AllJumpsMode,
		Global = isGlobal,
	}

	if isGlobal then
		_latestGlobalMessageID = info.MessageID
		MessagingService:PublishAsync("GlobalWin", info)
	end

	_broadcastWinAnnouncement(info)
	task.spawn(Webhook.sendMessage, player, endingName, difficultyName, finalTime)
end

--[=[
	Sends a generic server announcement to all players.

	@within Announcements
]=]
function Announcements.gameAnnouncement(message: string, color: Color3, isFancyText: boolean?)
	BlinkServer.GameAnnouncement.FireAll(message, color, isFancyText)
end

--[=[
	Kicks a player for anti-cheat with a themed message broadcast to the server.

	@within Announcements
]=]
function Announcements.antiCheatKick(player: Player, reason: string)
	local kickMessage = KickMessages[math.random(1, #KickMessages)]
	kickMessage = kickMessage:gsub("{Player}", if Config.USE_DISPLAY_NAME then player.DisplayName else player.Name)

	Announcements.gameAnnouncement(kickMessage, Color3.new(1, 0, 0))
	player:Kick(reason)
end

function Announcements.init()
	MessagingService:SubscribeAsync("GlobalWin", _onGlobalWinMessage)
end

return Announcements
