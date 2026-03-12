local Players = game:GetService("Players")

local BlinkClient = require("../../shared/Network/BlinkClient")
local Notification = require("@self/notification")
local TicketConfig = require("../../shared/constants/ticketConfig")
local UIManager = require("@self/uiManager")
local Util = require("../../shared/utils/util")
local completions = require("@self/completions")
local settingsController = require("@self/settingsController")
local spectate = require("@self/spectate")
local ticketsDisplay = require("@self/ticketsDisplay")

local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui")
local MainMenuGui = PlayerGui:WaitForChild("MainMenu") :: ScreenGui

local ButtonsHolder = MainMenuGui:FindFirstChild("ButtonsHolder") :: Frame
local MenuButton = ButtonsHolder:FindFirstChild("MenuButton") :: GuiButton
local SpectateButton = ButtonsHolder:FindFirstChild("SpectateButton") :: GuiButton?
local MainMenu = MainMenuGui:FindFirstChild("Main") :: Frame
local CloseButton = MainMenu:FindFirstChild("CloseButton") :: GuiButton
local ButtonsContainer = MainMenu:FindFirstChild("ButtonsContainer") :: Frame
local MenusContainer = MainMenu:FindFirstChild("MenusContainer") :: Frame
local CompletionsMenu = MenusContainer:FindFirstChild("CompletionsMenu") :: Frame

local AllJumpsModal = MenusContainer:FindFirstChild("AllJumpModal", true) :: Frame
local AllJumpButton = AllJumpsModal:FindFirstChild("ConfirmButton") :: GuiButton
local ExitModal = MenusContainer:FindFirstChild("ExitModal", true) :: Frame
local ExitButton = ExitModal:FindFirstChild("ConfirmButton") :: GuiButton
local RestartModal = MenusContainer:FindFirstChild("RestartModal", true) :: Frame
local RestartButton = RestartModal:FindFirstChild("ConfirmButton") :: GuiButton
local PracticeModal = MenusContainer:FindFirstChild("PracticeModal", true) :: Frame
local PracticeButton = PracticeModal:FindFirstChild("ConfirmButton") :: GuiButton

local RestartMenuButton = ButtonsContainer:FindFirstChild("RestartButton") :: GuiButton?
local ExitMenuButton = ButtonsContainer:FindFirstChild("ExitButton") :: GuiButton?

local completionsCache: completions.PlayerDataCache? = nil
local hasOpenedOnce = false
local previousTickets: number? = nil
local currentTowerAcronym = ""

local MenuController = {}

local function updateTowerButtonsVisibility(isInTower: boolean)
	if RestartMenuButton then
		RestartMenuButton.Visible = isInTower
	end
	if ExitMenuButton then
		ExitMenuButton.Visible = isInTower
	end
	if RestartModal then
		RestartModal.Visible = isInTower
	end
	if ExitModal then
		ExitModal.Visible = isInTower
	end
end

local function updateModalText(modal: any, isActive: boolean, modeName: string)
	local label = modal.ConfirmationLabel

	if isActive then
		label.Text = `Leave {modeName} Mode?`
	else
		label.Text = `Enter {modeName} Mode?`
	end
end

local function setupConfirmButton(button: GuiButton, actionType: "Exit" | "Restart" | "AllJumps" | "Practice")
	button.MouseButton1Click:Connect(function()
		UIManager.PlayClick()

		if actionType == "Exit" then
			BlinkClient.ExitTowerRequest.Fire()
		elseif actionType == "Restart" then
			BlinkClient.RestartRequested.Fire()
		elseif actionType == "AllJumps" then
			BlinkClient.SetAllJumpsMode.Fire(not Player:GetAttribute("AllJumpsMode"))
		elseif actionType == "Practice" then
			BlinkClient.SetPracticeMode.Fire(not Player:GetAttribute("PracticeMode"))
		end

		MainMenu.Visible = false
	end)
end

local function reconcileTable(target: { [any]: any }, source: { [any]: any })
	for key, value in source do
		if type(value) == "table" and type(target[key]) == "table" then
			reconcileTable(target[key], value)
		else
			target[key] = value
		end
	end
end

local function applyCompletionsData(incoming: any)
	if not completionsCache then
		completionsCache = incoming
	else
		reconcileTable(completionsCache, incoming)
	end

	if completionsCache then
		completions.update(completionsCache)
	end
end

local function setupButtonConnections()
	local teleportMenu = MenusContainer:FindFirstChild("TeleportMenu", true) :: Frame

	for _, desc in MainMenu:GetDescendants() do
		if not desc:IsA("GuiButton") then
			continue
		end

		-- Only wire buttons in ButtonsContainer or inside the TeleportMenu.
		-- Skip buttons nested inside other menus (e.g. CompletionsMenu's SettingsButton).
		if not desc:IsDescendantOf(ButtonsContainer) and not desc:IsDescendantOf(teleportMenu) then
			continue
		end

		local prefix = string.gsub(desc.Name, "Button", "")
		local targetMenu = MenusContainer:FindFirstChild(prefix .. "Menu", true) :: Frame

		if targetMenu then
			local isSubButton = desc:IsDescendantOf(teleportMenu)
			desc.MouseButton1Click:Connect(function()
				UIManager.OpenFrame(targetMenu, desc, isSubButton)
			end)
		else
			desc.MouseButton1Click:Connect(UIManager.PlayClick)
		end

		desc.MouseEnter:Connect(UIManager.PlayHover)
	end
end

local function setupMenuToggle()
	local shopButton = ButtonsContainer:FindFirstChild("ShopButton") :: GuiButton
	local shopMenu = MenusContainer:FindFirstChild("ShopMenu") :: Frame

	MenuButton.MouseButton1Click:Connect(function()
		MainMenu.Visible = not MainMenu.Visible

		if MainMenu.Visible and not hasOpenedOnce then
			if shopButton and shopMenu then
				UIManager.OpenFrame(shopMenu, shopButton, false)
			end
			hasOpenedOnce = true
		end
	end)

	CloseButton.MouseButton1Click:Connect(function()
		MainMenu.Visible = false
	end)
end

local function setupModals()
	setupConfirmButton(RestartButton, "Restart")
	setupConfirmButton(ExitButton, "Exit")
	setupConfirmButton(AllJumpButton, "AllJumps")
	setupConfirmButton(PracticeButton, "Practice")

	local function syncAttributes()
		updateModalText(AllJumpsModal, Player:GetAttribute("AllJumpsMode") == true, "All Jumps")
		updateModalText(PracticeModal, Player:GetAttribute("PracticeMode") == true, "Practice")
	end

	Player:GetAttributeChangedSignal("AllJumpsMode"):Connect(syncAttributes)
	Player:GetAttributeChangedSignal("PracticeMode"):Connect(syncAttributes)
	syncAttributes()
end

--- Formats a duration in seconds into a human-readable string.
local function formatCooldownText(seconds: number): string
	local days = math.floor(seconds / 86400)
	if days >= 7 then
		local weeks = math.floor(days / 7)
		return if weeks == 1 then "a week" else `{weeks} weeks`
	end
	if days >= 1 then
		return if days == 1 then "a day" else `{days} days`
	end
	local hours = math.floor(seconds / 3600)
	if hours >= 1 then
		return if hours == 1 then "an hour" else `{hours} hours`
	end
	return "some time"
end

--- Call this whenever new player data arrives (completions, tower stats, etc.).
function MenuController.applyPlayerData(incoming: any)
	applyCompletionsData(incoming)

	-- Sync settings
	local settings = incoming and incoming.settings
	if settings then
		settingsController.applySettings(settings)
	end

	-- Update ticket display and show notification on ticket gain
	local tickets = incoming and incoming.tickets
	if tickets ~= nil then
		ticketsDisplay.updateTickets(tickets)

		if previousTickets ~= nil and tickets > previousTickets then
			local earned = tickets - previousTickets

			-- Build rich-text message with difficulty-colored tower acronym
			local towerAcronym = currentTowerAcronym
			local towerColor = Util.getTowerColors(towerAcronym)
			local colorHex = towerColor:ToHex()

			local cooldownText = formatCooldownText(TicketConfig.cooldownDuration)
			local message =
				`You received {earned} ticket{if earned == 1 then "" else "s"} for beating <font color="#{colorHex}">{towerAcronym}</font>! Tickets can be re-obtained from this tower after {cooldownText}.`

			Notification.show(message)
		end
		previousTickets = tickets
	end
end

function MenuController.Start()
	setupButtonConnections()
	setupMenuToggle()
	setupModals()
	ticketsDisplay.setup()
	spectate.setup(MainMenuGui)

	if SpectateButton then
		SpectateButton.MouseButton1Click:Connect(function()
			UIManager.PlayClick()
			spectate.toggle()
		end)
	end

	completions.setup(CompletionsMenu)

	-- Tower-dependent button visibility
	updateTowerButtonsVisibility(false)
	BlinkClient.LoadTower.On(function(acronym: string)
		currentTowerAcronym = acronym
		updateTowerButtonsVisibility(true)
	end)
	BlinkClient.UnloadTower.On(function()
		currentTowerAcronym = ""
		updateTowerButtonsVisibility(false)
	end)
end

--- Exposes the settings controller for external use.
MenuController.settings = settingsController

return MenuController
