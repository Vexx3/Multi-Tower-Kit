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

	Color: Color3,
	FancyFont: boolean,

	Global: boolean,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage.Shared

local BlinkClient = require(ReplicatedStorage.Network.BlinkClient)
local Config = require("../Config")
local Util = require(Shared.Util)

local Announcements = {}

--[=[
	Formats and displays a tower win message from server data.

	@within ClientAnnouncements
]=]
function Announcements:DisplayWinMessage(info: ClientWinMessageInfo)
	-- Convert boost dictionary to list
	local boostList = Util:FormatBoosts(info.BoostsUsed)

	-- Construct the win message
	local message = Config.WinMessage
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

	Announcements:DisplayMessage(finalMessage, info.Color, info.FancyFont)
end

--[=[
	Shows a styled chat announcement with color, font, and size overrides.

	@within ClientAnnouncements
]=]
function Announcements:DisplayMessage(Message: string, Color: Color3, FancyText: boolean?)
	-- Format instances of "{Time:???}"
	Message = Util:FormatTimeSyntax(Message)

	-- Get folder of text channels
	local Channels = TextChatService:FindFirstChild("TextChannels")
	if not Channels then
		error("Message could not be displayed, could not find TextChannels folder")
		return
	end

	-- Get the appropriate text channel
	local TextChannel = Channels:FindFirstChild(Config.ChatChannel)
	if not TextChannel or not TextChannel:IsA("TextChannel") then
		error(
			"Could not find appropriate TextChannel, likely because either ChatChannel wasn't configured properly, or TextChatService.CreateDefaultTextChannels is disabled"
		)
		return
	end

	-- Construct information to use with the font XML tag
	local colorString = `rgb({math.floor(Color.R * 255)}, {math.floor(Color.G * 255)}, {math.floor(Color.B * 255)})`
	local faceString = if FancyText then Config.ChatFancyFontFace else Config.ChatFontFace
	local sizeString = if FancyText then tostring(Config.ChatFancyFontSize) else tostring(Config.ChatFontSize)

	-- Apply the strings to the tag
	local finalMessage = Config.ChatFont
	finalMessage = finalMessage:gsub("{FontColor}", colorString)
	finalMessage = finalMessage:gsub("{FontFace}", faceString)
	finalMessage = finalMessage:gsub("{FontSize}", sizeString)
	finalMessage = finalMessage:gsub("{Message}", Message)

	-- Finally, actually display the message
	TextChannel:DisplaySystemMessage(finalMessage, "MTKv4System")
end

function Announcements:CreateChatChannel() end

function Announcements:Init()
	BlinkClient.GameAnnouncement.On(function(...)
		Announcements:DisplayMessage(...)
	end)

	BlinkClient.GameWinAnnouncement.On(function(...: ClientWinMessageInfo)
		Announcements:DisplayWinMessage(...)
	end)
end

return Announcements
