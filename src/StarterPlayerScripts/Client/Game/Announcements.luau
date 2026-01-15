-- Displays server and global win announcements on the client, formatting chat output.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local BlinkClient = require("@game/ReplicatedStorage/TowerGame/Network/BlinkClient")
local Config = require("../Config")
local Log = require(ReplicatedStorage.Framework.Log)
local Util = require("@game/ReplicatedStorage/TowerGame/Shared/Util")

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

-- Shows a styled chat announcement with color, font, and size overrides.
function Announcements.displayMessage(message: string, color: Color3, isFancyText: boolean?): ()
	-- Format instances of "{Time:???}"
	message = Util.formatTimeSyntax(message)

	-- Get folder of text channels
	local channels = TextChatService:FindFirstChild("TextChannels")
	if not channels then
		Log({
			type = "error",
			[1] = "Message could not be displayed, could not find TextChannels folder",
		})
		return
	end

	-- Get the appropriate text channel
	local textChannel = channels:FindFirstChild(Config.chatChannel)
	if not textChannel or not textChannel:IsA("TextChannel") then
		Log({
			type = "error",
			[1] = "Could not find appropriate TextChannel, likely because either ChatChannel wasn't configured properly, or TextChatService.CreateDefaultTextChannels is disabled",
		})
		return
	end

	-- Construct information to use with the font XML tag
	local colorString = `rgb({math.floor(color.R * 255)}, {math.floor(color.G * 255)}, {math.floor(color.B * 255)})`
	local faceString = if isFancyText then Config.chatFancyFontFace else Config.chatFontFace
	local sizeString = if isFancyText then tostring(Config.chatFancyFontSize) else tostring(Config.chatFontSize)

	-- Apply the strings to the tag
	local finalMessage = ("<font color='{FontColor}' size='{FontSize}' face='{FontFace}'>{Message}</font>")
		:gsub("{FontColor}", colorString)
		:gsub("{FontFace}", faceString)
		:gsub("{FontSize}", sizeString)
		:gsub("{Message}", message)

	-- Finally, actually display the message
	textChannel:DisplaySystemMessage(finalMessage, "MTKv4System")
end

-- Formats and displays a tower win message from server data.
function Announcements.displayWinMessage(info: ClientWinMessageInfo): ()
	-- Convert boost dictionary to list
	local boostList = Util.formatBoosts(info.boostsUsed)

	-- Construct the win message
	local messageTemplate = if info.allJumps then Config.winMessageAj else Config.winMessage
	local message = messageTemplate
		:gsub("{PlayerName}", info.playerName)
		:gsub("{EndingName}", info.endingName)
		:gsub("{Time}", "{Time:" .. tostring(info.time) .. "}")

	-- If boosts were used, construct the list and replace {BoostsUsed} with the list
	-- Otherwise, simply omit it
	if boostList ~= "" then
		local boostsMessage = Config.winMessageBoostsUsed:gsub("{BoostList}", boostList)
		message = `{message}{boostsMessage}`
	end

	local serverPrefix = if info.global then "[GLOBAL]:" else "[SERVER]:"
	local finalMessage = `{serverPrefix} {message}`

	Announcements.displayMessage(finalMessage, info.color, info.fancyFont)
end

function Announcements.init(): ()
	BlinkClient.GameAnnouncement.On(function(...): ()
		Announcements.displayMessage(...)
	end)

	BlinkClient.GameWinAnnouncement.On(function(info: ClientWinMessageInfo): ()
		Announcements.displayWinMessage(info)
	end)
end

return Announcements
