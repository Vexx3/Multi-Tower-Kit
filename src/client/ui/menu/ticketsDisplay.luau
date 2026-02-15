--[[
	Tickets display for the MainMenu.
	Updates the TicketsLabel with the player's current ticket count
	and opens the ShopMenu when the TicketsButton is clicked.
]]

local Players = game:GetService("Players")

local UIManager = require("./uiManager")

local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui")
local MainMenuGui = PlayerGui:WaitForChild("MainMenu") :: ScreenGui

local MainFrame = MainMenuGui:FindFirstChild("Main") :: Frame
local TicketsButton = MainFrame:FindFirstChild("TicketsButton") :: TextButton
local TicketsLabel = TicketsButton:FindFirstChild("TicketsLabel") :: TextLabel

local ButtonsContainer = MainFrame:FindFirstChild("ButtonsContainer") :: Frame
local MenusContainer = MainFrame:FindFirstChild("MenusContainer") :: Frame
local ShopButton = ButtonsContainer:FindFirstChild("ShopButton") :: TextButton
local ShopMenu = MenusContainer:FindFirstChild("ShopMenu") :: Frame

local ticketsDisplay = {}

function ticketsDisplay.updateTickets(amount: number)
	TicketsLabel.Text = `Tickets: {amount}`
end

--- Sets up the TicketsButton to open the shop when clicked.
function ticketsDisplay.setup()
	TicketsButton.MouseButton1Click:Connect(function()
		if ShopMenu and ShopButton then
			UIManager.OpenFrame(ShopMenu, ShopButton, false)
		end
	end)

	TicketsButton.MouseEnter:Connect(UIManager.PlayHover)
end

return ticketsDisplay
