--[=[
	Displays a real-time FPS counter using the TopbarPlus Icon widget.
	Updates every 0.5 seconds using Heartbeat delta tracking.

	@class FPSDisplay
	@client
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage.Packages

local Icon = require(Packages.topbarplus)

--[=[
	@interface FPSIconConfig
	@within FPSDisplay
	.name string -- The icon name
	.updateInterval number -- How often to refresh the display
]=]

local UPDATE_INTERVAL = 0.5

local fpsIcon = Icon.new():setLabel("0 FPS"):lock()

local frameCount = 0
local lastUpdate = 0
local connection: RBXScriptConnection? = nil

local FPSDisplay = {}

--[=[
	Starts the FPS display icon and begins tracking frame rate.
	Creates a TopbarPlus icon that shows current FPS.
]=]
function FPSDisplay.start(): ()
	if fpsIcon then
		return
	end

	frameCount = 0
	lastUpdate = 0

	connection = RunService.Heartbeat:Connect(function(deltaTime)
		frameCount += 1
		lastUpdate += deltaTime

		if lastUpdate >= UPDATE_INTERVAL then
			local fps = math.floor(frameCount / lastUpdate + 0.5)
			fpsIcon:setLabel(`FPS: {fps}"`)

			frameCount = 0
			lastUpdate = 0
		end
	end)
end

--[=[
	Stops the FPS display and removes the icon.
]=]
function FPSDisplay.stop(): ()
	if connection then
		connection:Disconnect()
		connection = nil
	end

	frameCount = 0
	lastUpdate = 0
end

--[=[
	Returns whether the FPS display is currently active.

	@return boolean -- True if display is running
]=]
function FPSDisplay.isActive(): boolean
	return connection ~= nil
end

return FPSDisplay
