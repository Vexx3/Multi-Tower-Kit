--[=[
	Displays server and global win announcements on the client, formatting chat
	output.

	@class ClientAnnouncements
]=]

type ClientWinMessageInfo = {
	PlayerName: string,
	EndingName: string,
	Time: number,
	BoostsUsed: { [string]: string },
	AllJumps: boolean,

	Color: Color3,
	FancyFont: boolean,

	Global: boolean,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage.TowerGame.Shared

local BlinkClient = require(ReplicatedStorage.TowerGame.Network.BlinkClient)
local Config = require("../Config")
local Util = require(Shared.Util)

local Announcements = {}

--[=[
	Formats and displays a tower win message from server data.

	@within ClientAnnouncements
]=]
function Announcements.displayWinMessage(info: ClientWinMessageInfo)
	-- Convert boost dictionary to list
	local boostList = Util.formatBoosts(info.BoostsUsed)

	-- Construct the win message
	local messageTemplate = if info.AllJumps then Config.WinMessageAJ else Config.WinMessage
	local message = messageTemplate
		:gsub("{PlayerName}", info.PlayerName)
		:gsub("{EndingName}", info.EndingName)
		:gsub("{Time}", "{Time:" .. tostring(info.Time) .. "}")

	-- If boosts were used, construct the list and replace {BoostsUsed} with the list
	-- Otherwise, simply omit it
	if boostList ~= "" then
		local boostsMessage = Config.WinMessageBoostsUsed:gsub("{BoostList}", boostList)
		message = `{message}{boostsMessage}`
	end

	local serverPrefix = if info.Global then "[GLOBAL]:" else "[SERVER]:"
	local finalMessage = `{serverPrefix} {message}`

	Announcements.displayMessage(finalMessage, info.Color, info.FancyFont)
end

--[=[
	Shows a styled chat announcement with color, font, and size overrides.

	@within ClientAnnouncements
]=]
function Announcements.displayMessage(message: string, color: Color3, isFancyText: boolean?)
	-- Format instances of "{Time:???}"
	message = Util.formatTimeSyntax(message)

	-- Get folder of text channels
	local channels = TextChatService:FindFirstChild("TextChannels")
	if not channels then
		error("Message could not be displayed, could not find TextChannels folder")
		return
	end

	-- Get the appropriate text channel
	local textChannel = channels:FindFirstChild(Config.ChatChannel)
	if not textChannel or not textChannel:IsA("TextChannel") then
		error(
			"Could not find appropriate TextChannel, likely because either ChatChannel wasn't configured properly, or TextChatService.CreateDefaultTextChannels is disabled"
		)
		return
	end

	-- Construct information to use with the font XML tag
	local colorString = `rgb({math.floor(color.R * 255)}, {math.floor(color.G * 255)}, {math.floor(color.B * 255)})`
	local faceString = if isFancyText then Config.ChatFancyFontFace else Config.ChatFontFace
	local sizeString = if isFancyText then tostring(Config.ChatFancyFontSize) else tostring(Config.ChatFontSize)

	-- Apply the strings to the tag
	local finalMessage = Config.ChatFont
	finalMessage = finalMessage:gsub("{FontColor}", colorString)
	finalMessage = finalMessage:gsub("{FontFace}", faceString)
	finalMessage = finalMessage:gsub("{FontSize}", sizeString)
	finalMessage = finalMessage:gsub("{Message}", message)

	-- Finally, actually display the message
	textChannel:DisplaySystemMessage(finalMessage, "MTKv4System")
end

function Announcements.init()
	BlinkClient.GameAnnouncement.On(function(...)
		Announcements.displayMessage(...)
	end)

	BlinkClient.GameWinAnnouncement.On(function(...: ClientWinMessageInfo)
		Announcements.displayWinMessage(...)
	end)
end

return Announcements
