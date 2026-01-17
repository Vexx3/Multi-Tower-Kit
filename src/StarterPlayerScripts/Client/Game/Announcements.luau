--[[
	Displays server and global win announcements on the client.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Framework = ReplicatedStorage.Framework

local BlinkClient = require(TowerGame.Network.BlinkClient)
local Config = require("../Config")
local Log = require(Framework.Log)
local Util = require(Shared.Util)

type ClientWinMessageInfo = {
	playerName: string,
	endingName: string,
	time: number,
	boostsUsed: { [string]: string },
	allJumps: boolean,
	color: Color3,
	fancyFont: boolean,
	global: boolean,
}

local Announcements = {}

--- Shows a styled chat announcement with color, font, and size overrides.
--- @param message string -- The message to display
--- @param color Color3 -- The text color
--- @param isFancyText boolean? -- Whether to use fancy font styling
function Announcements.displayMessage(message: string, color: Color3, isFancyText: boolean?): ()
	message = Util.formatTimeSyntax(message)

	local channels = TextChatService:FindFirstChild("TextChannels")
	if not channels then
		Log({
			type = "error",
			[1] = "Message could not be displayed, could not find TextChannels folder",
		})
		return
	end

	local textChannel = channels:FindFirstChild(Config.chatChannel)
	if not textChannel or not textChannel:IsA("TextChannel") then
		Log({
			type = "error",
			[1] = "Could not find appropriate TextChannel. Check ChatChannel config or TextChatService.CreateDefaultTextChannels",
		})
		return
	end

	local colorString = `rgb({math.floor(color.R * 255)}, {math.floor(color.G * 255)}, {math.floor(color.B * 255)})`
	local faceString = if isFancyText then Config.chatFancyFontFace else Config.chatFontFace
	local sizeString = if isFancyText then tostring(Config.chatFancyFontSize) else tostring(Config.chatFontSize)

	local finalMessage = ("<font color='{FontColor}' size='{FontSize}' face='{FontFace}'>{Message}</font>")
		:gsub("{FontColor}", colorString)
		:gsub("{FontFace}", faceString)
		:gsub("{FontSize}", sizeString)
		:gsub("{Message}", message)

	textChannel:DisplaySystemMessage(finalMessage, "MTKv4System")
end

--- Formats and displays a tower win message from server data.
--- @param info ClientWinMessageInfo -- The win message information
function Announcements.displayWinMessage(info: ClientWinMessageInfo): ()
	local boostList = Util.formatBoosts(info.boostsUsed)

	local messageTemplate = if info.allJumps then Config.winMessageAj else Config.winMessage
	local message = messageTemplate
		:gsub("{PlayerName}", info.playerName)
		:gsub("{EndingName}", info.endingName)
		:gsub("{Time}", "{Time:" .. tostring(info.time) .. "}")

	if boostList ~= "" then
		local boostsMessage = Config.winMessageBoostsUsed:gsub("{BoostList}", boostList)
		message = `{message}{boostsMessage}`
	end

	local serverPrefix = if info.global then "[GLOBAL]:" else "[SERVER]:"
	local finalMessage = `{serverPrefix} {message}`

	Announcements.displayMessage(finalMessage, info.color, info.fancyFont)
end

--- Initializes the announcements system and sets up event listeners.
function Announcements.init(): ()
	BlinkClient.GameAnnouncement.On(function(message: string, color: Color3, isFancyText: boolean?): ()
		Announcements.displayMessage(message, color, isFancyText)
	end)

	BlinkClient.GameWinAnnouncement.On(function(info: ClientWinMessageInfo): ()
		Announcements.displayWinMessage(info)
	end)
end

return Announcements
