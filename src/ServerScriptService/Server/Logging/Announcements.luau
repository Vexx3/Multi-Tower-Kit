--!strict
-- Written by fanofpixels

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")

local GameData = ReplicatedStorage.GameData
local Shared = ReplicatedStorage.Shared

local ZapServer = require("../../../ZapServer")

-- Get types
local Types = require(Shared.Types)

type List<T> = Types.List<T>
type Dictionary<T> = Types.Dictionary<T>
type PlayerInfo = Types.PlayerInfo
type TowerRush = Types.TowerRush
type TowerInfo = Types.TowerInfo
type EndingInfo = Types.EndingInfo
type Difficulty = Types.DifficultyInfo

type WinMessageInfo = {
	MessageID: string,

	PlayerName: string,
	EndingName: string,
	DifficultyName: string,

	Time: number,
	BoostsUsed: Dictionary<string>,

	Global: boolean,
}

type ClientWinMessageInfo = {
	PlayerName: string,
	EndingName: string,
	Time: number,
	BoostsUsed: Dictionary<string>,

	Color: Color3,
	FancyFont: boolean,

	Global: boolean,
}

type Message = {
	Data: any,
	Sent: number,
}

local Util = require(Shared.Util)

local Config = require(GameData.Config)
local KickMessages: List<string> = require(GameData.KickMessages)
local Webhook = require(".././Logging/Webhook")

local latestGlobalMessageID = ""

local Announcements = {}

function Announcements:WinAnnouncement(player: PlayerInfo, endingName: string, difficultyName: string)
	local endingDifficulty = Util:GetDifficulty(difficultyName)
	
	local playerName = if Config.USE_DISPLAY_NAME then player.Player.DisplayName else player.Player.Name

	local info: WinMessageInfo = {
		-- Unique message ID
		MessageID = HttpService:GenerateGUID(false),

		PlayerName = playerName,
		EndingName = endingName,
		DifficultyName = difficultyName,

		Time = player.TowerTimer,
		BoostsUsed = player.BoostItemNames,

		Global = endingDifficulty.GlobalAnnouncement,
	}

	-- If this difficulty should be globally announced, message the universe
	if endingDifficulty.GlobalAnnouncement then
		-- Set the latest global message ID, we do this so we can check later
		-- If we receive a message and it's the same one as this one, don't broadcast it
		-- This is to prevent a server from broadcasting the same win message twice
		latestGlobalMessageID = info.MessageID

		MessagingService:PublishAsync("GlobalWin", info)
	end
	
	BroadcastWinAnnouncement(info)
	task.spawn(Webhook.SendMessage, Webhook, player, endingName, difficultyName)
end

function BroadcastWinAnnouncement(info: WinMessageInfo)
	local endingDifficulty = Util:GetDifficulty(info.DifficultyName)

	-- Construct an information table the client can recieve
	local clientMsgInfo: ClientWinMessageInfo = {
		PlayerName = info.PlayerName,
		EndingName = info.EndingName,
		Time = info.Time,
		BoostsUsed = info.BoostsUsed,

		Color = endingDifficulty.Color,
		FancyFont = endingDifficulty.FancyFont,

		Global = endingDifficulty.GlobalAnnouncement,
	}
	
	ZapServer.GameWinAnnouncement.FireAll(clientMsgInfo)
end

function Announcements:GameAnnouncement(message: string, color: Color3, fancyText: boolean?)
	ZapServer.GameAnnouncement.FireAll(message, color, fancyText)
end

function Announcements:AntiCheatKick(player: Player, reason: string)
	local message = KickMessages[math.random(1, #KickMessages)]
	message = message:gsub("{Player}", if Config.USE_DISPLAY_NAME then player.DisplayName else player.Name)

	Announcements:GameAnnouncement(message, Color3.new(1, 0, 0))
	player:Kick(reason)
end

function GlobalWinMessage(message: Message)
	local info: WinMessageInfo = message.Data

	-- Prevent double message
	if info.MessageID == latestGlobalMessageID then
		return
	end
	BroadcastWinAnnouncement(info)
end

function Announcements:Init()
	MessagingService:SubscribeAsync("GlobalWin", GlobalWinMessage)
end

return Announcements
