--[[
	Spectate system — watch other players in the server.
	Toggled via the SpectateButton in ButtonsHolder.
	SpectateFrame lives directly under MainMenu ScreenGui.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Janitor = require("../../../../Packages/janitor")
local TowerRushes = require("../../../shared/constants/towerRushes")
local Util = require("../../../shared/utils/util")

local localPlayer = Players.LocalPlayer :: Player
local camera = workspace.CurrentCamera

local spectateJanitor = Janitor.new()
local characterJanitor = Janitor.new()

local watchablePlayers: { Player } = {}
local watchIndex = 1
local isSpectating = false
local lastSyncedTimer = 0
local lastSyncTime = 0

-- UI references (populated in setup)
local spectateFrame: Frame
local displayNameLabel: TextLabel
local usernameLabel: TextLabel
local currentTowerLabel: TextLabel
local towerTimerLabel: TextLabel
local trProgressLabel: TextLabel
local boostUsedLabel: TextLabel
local healthFill: Frame
local nextButton: TextButton
local previousButton: TextButton

local function bindHumanoid(humanoid: Humanoid)
	local function updateHealth()
		local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		healthFill.Size = UDim2.fromScale(ratio, 1)
	end

	updateHealth()

	spectateJanitor:Add(humanoid:GetPropertyChangedSignal("Health"):Connect(updateHealth))
	spectateJanitor:Add(humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth))
	spectateJanitor:Add(humanoid.Died:Connect(function()
		healthFill.Size = UDim2.fromScale(1, 1)
	end))
end

local function updatePlayerFrame(targetPlayer: Player)
	spectateJanitor:Cleanup()

	displayNameLabel.Text = targetPlayer.DisplayName
	usernameLabel.Text = `@{targetPlayer.Name}`

	local function onCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		bindHumanoid(humanoid)
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
	end

	if targetPlayer.Character then
		onCharacter(targetPlayer.Character)
	end

	spectateJanitor:Add(targetPlayer.CharacterAdded:Connect(onCharacter))

	local function updateTower()
		local tower = targetPlayer:GetAttribute("CurrentTower") :: string?
		if not tower or tower == "" then
			currentTowerLabel.Visible = false
			towerTimerLabel.Visible = false
			return
		end
		currentTowerLabel.Text = tower
		local textColor, strokeColor = Util.getTowerColors(tower)
		currentTowerLabel.TextColor3 = textColor
		currentTowerLabel.TextStrokeColor3 = strokeColor
		currentTowerLabel.Visible = true
		towerTimerLabel.Visible = true
	end

	local function syncTimer()
		local timer = targetPlayer:GetAttribute("TowerTimer") :: number?
		if timer and timer > 0 then
			lastSyncedTimer = timer
			lastSyncTime = os.clock()
		else
			lastSyncedTimer = 0
			lastSyncTime = 0
		end
	end

	local function updateBoost()
		local boostNames = targetPlayer:GetAttribute("BoostItemNames") :: string?
		boostUsedLabel.Visible = boostNames ~= nil and boostNames ~= ""
	end

	local function updateTowerRush()
		local rushId = targetPlayer:GetAttribute("CurrentTowerRush") :: string?
		if not rushId or rushId == "" then
			trProgressLabel.Visible = false
			return
		end
		local rush = TowerRushes[rushId]
		if not rush then
			trProgressLabel.Visible = false
			return
		end
		local index = targetPlayer:GetAttribute("CurrentTowerRushIndex") :: number? or 0
		local realmInfo = Util.getRealmTowerInfo(rushId)
		local diffName = ""
		if realmInfo then
			diffName = Util.getDifficultyByRating(realmInfo.rating)
		end
		local textColor, strokeColor = Util.getDifficultyColors(diffName)
		trProgressLabel.Text = `{rushId} - {index}/{#rush.towers}`
		trProgressLabel.TextColor3 = textColor
		trProgressLabel.TextStrokeColor3 = strokeColor
		trProgressLabel.Visible = true
	end

	updateTower()
	syncTimer()
	updateBoost()
	updateTowerRush()

	spectateJanitor:Add(RunService.Heartbeat:Connect(function()
		if lastSyncedTimer > 0 and lastSyncTime > 0 then
			local elapsed = os.clock() - lastSyncTime
			towerTimerLabel.Text = Util.formatTimer(lastSyncedTimer + elapsed)
		else
			towerTimerLabel.Text = "00:00.00"
		end
	end))

	spectateJanitor:Add(targetPlayer:GetAttributeChangedSignal("CurrentTower"):Connect(updateTower))
	spectateJanitor:Add(targetPlayer:GetAttributeChangedSignal("TowerTimer"):Connect(syncTimer))
	spectateJanitor:Add(targetPlayer:GetAttributeChangedSignal("BoostItemNames"):Connect(updateBoost))
	spectateJanitor:Add(targetPlayer:GetAttributeChangedSignal("CurrentTowerRush"):Connect(updateTowerRush))
	spectateJanitor:Add(targetPlayer:GetAttributeChangedSignal("CurrentTowerRushIndex"):Connect(updateTowerRush))
end

local function watchPlayer(index: number)
	characterJanitor:Cleanup()

	table.clear(watchablePlayers)
	for _, player in Players:GetPlayers() do
		--if player ~= localPlayer then
		table.insert(watchablePlayers, player)
		--end
	end

	if #watchablePlayers == 0 then
		return
	end

	if index > #watchablePlayers then
		watchIndex = 1
	elseif index < 1 then
		watchIndex = #watchablePlayers
	else
		watchIndex = index
	end

	local target = watchablePlayers[watchIndex]
	if not target then
		return
	end

	if target.Character then
		local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = humanoid
		end
	end

	characterJanitor:Add(target.CharacterAdded:Connect(function(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
	end))

	updatePlayerFrame(target)
end

local function resetWatch()
	characterJanitor:Cleanup()
	spectateJanitor:Cleanup()

	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
	end

	currentTowerLabel.Visible = false
	towerTimerLabel.Visible = false
	trProgressLabel.Visible = false
	boostUsedLabel.Visible = false
	healthFill.Size = UDim2.fromScale(1, 1)
end

local spectate = {}

function spectate.toggle()
	isSpectating = not isSpectating
	spectateFrame.Visible = isSpectating

	if isSpectating then
		watchPlayer(watchIndex)
	else
		resetWatch()
	end
end

function spectate.isActive(): boolean
	return isSpectating
end

function spectate.setup(mainMenuGui: ScreenGui)
	spectateFrame = mainMenuGui:WaitForChild("SpectateFrame") :: Frame

	local playerFrame = spectateFrame:WaitForChild("PlayerFrame") :: Frame
	displayNameLabel = playerFrame:WaitForChild("DisplayName") :: TextLabel
	usernameLabel = playerFrame:WaitForChild("Username") :: TextLabel
	currentTowerLabel = playerFrame:WaitForChild("CurrentTower") :: TextLabel
	towerTimerLabel = playerFrame:WaitForChild("TowerTimer") :: TextLabel
	trProgressLabel = playerFrame:WaitForChild("TRProgress") :: TextLabel
	boostUsedLabel = playerFrame:WaitForChild("BoostUsed") :: TextLabel
	local healthBar = playerFrame:WaitForChild("HealthBar") :: Frame
	healthFill = healthBar:WaitForChild("Fill") :: Frame
	nextButton = spectateFrame:WaitForChild("Next") :: TextButton
	previousButton = spectateFrame:WaitForChild("Previous") :: TextButton

	spectateFrame.Visible = false
	currentTowerLabel.Visible = false
	towerTimerLabel.Visible = false
	trProgressLabel.Visible = false
	boostUsedLabel.Visible = false

	nextButton.Activated:Connect(function()
		if isSpectating then
			watchPlayer(watchIndex + 1)
		end
	end)

	previousButton.Activated:Connect(function()
		if isSpectating then
			watchPlayer(watchIndex - 1)
		end
	end)

	Players.PlayerRemoving:Connect(function(removedPlayer: Player)
		for i, player in watchablePlayers do
			if player == removedPlayer then
				table.remove(watchablePlayers, i)
				break
			end
		end

		if isSpectating and #watchablePlayers > 0 then
			watchPlayer(watchIndex)
		elseif isSpectating then
			spectate.toggle()
		end
	end)
end

return spectate
