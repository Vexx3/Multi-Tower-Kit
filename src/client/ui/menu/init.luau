local Players = game:GetService("Players")

local BlinkClient = require("../../shared/Network/BlinkClient")
local UIManager = require("@self/uiManager")
local completions = require("@self/completions")

local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui")
local MainMenuGui = PlayerGui:WaitForChild("MainMenu") :: ScreenGui

local ButtonsHolder = MainMenuGui:FindFirstChild("ButtonsHolder") :: Frame
local MenuButton = ButtonsHolder:FindFirstChild("MenuButton") :: GuiButton
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

function MenuController.Start()
	setupButtonConnections()
	setupMenuToggle()
	setupModals()

	completions.setup(CompletionsMenu)
	BlinkClient.PlayerDataUpdate.On(applyCompletionsData)

	-- Tower-dependent button visibility
	updateTowerButtonsVisibility(false)
	BlinkClient.LoadTower.On(function()
		updateTowerButtonsVisibility(true)
	end)
	BlinkClient.UnloadTower.On(function()
		updateTowerButtonsVisibility(false)
	end)
end

return MenuController
