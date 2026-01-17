--[=[
	Handles the loading screen overlay displayed during data loading.
	Shows a message and optional attention label with fade transitions.

	@class LoadingScreen
	@client
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared

local GUIHandler = require(Shared.GUIHandler)

local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui")

local screenGui = PlayerGui:WaitForChild("TowerGUI") :: ScreenGui

local loadingScreenGroup = screenGui:FindFirstChild("LoadingScreen", true) :: CanvasGroup?
local loadingLabelElement = loadingScreenGroup and loadingScreenGroup:FindFirstChild("LoadingLabel") :: TextLabel?
local attentionLabelElement = loadingScreenGroup and loadingScreenGroup:FindFirstChild("Attention") :: TextLabel?

local LoadingScreen = {}

--[=[
	Shows the loading screen with the specified message.

	@param message string -- The message to display on the loading screen
	@param showAttention boolean? -- Whether to show the attention label
]=]
function LoadingScreen.show(message: string, showAttention: boolean?): ()
	if loadingLabelElement then
		loadingLabelElement.Text = message
	end
	if attentionLabelElement then
		attentionLabelElement.Visible = showAttention or false
	end
	if loadingScreenGroup then
		loadingScreenGroup.Visible = true
		GUIHandler.toggleUI(loadingScreenGroup, true, 1)
	end
end

--[=[
	Hides the loading screen with a fade transition.
]=]
function LoadingScreen.hide(): ()
	if loadingScreenGroup then
		GUIHandler.toggleUI(loadingScreenGroup, false, 1, function()
			if attentionLabelElement then
				attentionLabelElement.Visible = false
			end
		end)
	end
end

return LoadingScreen
