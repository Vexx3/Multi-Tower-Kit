--[[
	DisplayController - Handles client-side visual feedback.
	Manages announcements, tower sign colors, and chat messages.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Modules = ReplicatedStorage.Modules
local Framework = ReplicatedStorage.Framework

local BlinkClient = require(TowerGame.Network.BlinkClient)
local Config = require("../Config")
local Dash = require(Modules.Dash)
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

type TowerSignData = {
	folder: Instance,
	name: string,
	portalSign: Instance?,
	chartLine: Instance?,
	completionState: "none" | "normal" | "alljumps",
}

local TOWERS = workspace:WaitForChild("Towers")
local COMPLETED_COLOR = Color3.fromRGB(44, 101, 29)
local AJ_COMPLETED_COLOR = Color3.fromRGB(245, 205, 48)

local towerSigns: { [string]: TowerSignData } = {}

local function applySignColor(objectValue: Instance?, color: Color3)
	if not objectValue or not objectValue:IsA("ObjectValue") then
		return
	end
	local part = objectValue.Value
	if part and part:IsA("BasePart") then
		part.Color = color
	end
end

local function createTowerSign(towerFolder: Instance): TowerSignData
	return {
		folder = towerFolder,
		name = towerFolder.Name,
		portalSign = towerFolder:FindFirstChild("PortalSign", true),
		chartLine = towerFolder:FindFirstChild("ChartLine", true),
		completionState = "none",
	}
end

local function markSignCompleted(sign: TowerSignData, isAllJumps: boolean)
	if isAllJumps then
		sign.completionState = "alljumps"
		applySignColor(sign.portalSign, AJ_COMPLETED_COLOR)
		applySignColor(sign.chartLine, AJ_COMPLETED_COLOR)
	elseif sign.completionState ~= "alljumps" then
		sign.completionState = "normal"
		applySignColor(sign.portalSign, COMPLETED_COLOR)
		applySignColor(sign.chartLine, COMPLETED_COLOR)
	end
end

local DisplayController = {}

function DisplayController.displayMessage(message: string, color: Color3, isFancyText: boolean?)
	message = Util.formatTimeSyntax(message)

	local channels = TextChatService:FindFirstChild("TextChannels")
	if not channels then
		Log({ type = "error", [1] = "Message could not be displayed, could not find TextChannels folder" })
		return
	end

	local textChannel = channels:FindFirstChild(Config.chatChannel)
	if not textChannel or not textChannel:IsA("TextChannel") then
		Log({ type = "error", [1] = "Could not find appropriate TextChannel" })
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

function DisplayController.displayWinMessage(info: ClientWinMessageInfo)
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
	DisplayController.displayMessage(`{serverPrefix} {message}`, info.color, info.fancyFont)
end

function DisplayController.markTowerCompleted(towerName: string, isAllJumps: boolean)
	local sign = towerSigns[towerName]
	if sign then
		markSignCompleted(sign, isAllJumps)
	end
end

function DisplayController.updateCompletedTowers(
	data: { completedTowers: { string }?, completedAjTowers: { string }? }?
)
	if not data then
		return
	end

	if data.completedTowers then
		Dash.forEach(data.completedTowers, function(towerName)
			DisplayController.markTowerCompleted(towerName, false)
		end)
	end

	if data.completedAjTowers then
		Dash.forEach(data.completedAjTowers, function(towerName)
			DisplayController.markTowerCompleted(towerName, true)
		end)
	end
end

function DisplayController.init()
	for _, towerFolder in TOWERS:GetChildren() do
		towerSigns[towerFolder.Name] = createTowerSign(towerFolder)
	end

	BlinkClient.GameAnnouncement.On(function(message: string, color: Color3, isFancyText: boolean?)
		DisplayController.displayMessage(message, color, isFancyText)
	end)

	BlinkClient.GameWinAnnouncement.On(function(info: ClientWinMessageInfo)
		DisplayController.displayWinMessage(info)
	end)
end

return DisplayController
