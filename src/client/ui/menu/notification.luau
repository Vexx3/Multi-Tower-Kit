--[[
	Stacking notification system for the MainMenu.
	Each call to show() clones the template, plays a cooldown bar tween,
	then smoothly fades and removes the notification when done.
	Multiple notifications stack via UIListLayout.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui")
local MainMenuGui = PlayerGui:WaitForChild("MainMenu") :: ScreenGui

local NotificationHolder = MainMenuGui:FindFirstChild("NotificationHolder") :: Frame
local NotificationTemplate = NotificationHolder:FindFirstChild("Notification") :: Frame

-- Hide the template so it's never shown directly
NotificationTemplate.Visible = false

local DEFAULT_DURATION = 5
local FADE_OUT_TIME = 0.35

local Notification = {}

--- Smoothly fades out and destroys a notification frame.
local function fadeOutAndDestroy(frame: Frame)
	local fadeInfo = TweenInfo.new(FADE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeTween = TweenService:Create(frame, fadeInfo, { BackgroundTransparency = 1 })

	-- Also fade children
	for _, child in frame:GetDescendants() do
		if child:IsA("TextLabel") then
			TweenService:Create(child, fadeInfo, { TextTransparency = 1 }):Play()
		elseif child:IsA("Frame") then
			TweenService:Create(child, fadeInfo, { BackgroundTransparency = 1 }):Play()
		elseif child:IsA("UIStroke") then
			TweenService:Create(child, fadeInfo, { Transparency = 1 }):Play()
		end
	end

	fadeTween:Play()
	fadeTween.Completed:Connect(function()
		frame:Destroy()
	end)
end

--- Shows a stacking notification with the given message.
--- The cooldown bar shrinks from full width to zero over `duration` seconds,
--- then the notification fades out and is removed.
--- Supports rich text in the message string.
function Notification.show(message: string, duration: number?)
	local displayTime = duration or DEFAULT_DURATION

	local frame = NotificationTemplate:Clone()
	local infoLabel = frame:FindFirstChild("Info") :: TextLabel
	local cooldownBar = frame:FindFirstChild("CooldownBar") :: Frame

	infoLabel.Text = message

	local barHeight = cooldownBar.Size.Y
	cooldownBar.Size = UDim2.new(1, 0, barHeight.Scale, barHeight.Offset)

	frame.Parent = NotificationHolder
	frame.Visible = true

	local tweenInfo = TweenInfo.new(displayTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	local targetSize = UDim2.new(0, 0, barHeight.Scale, barHeight.Offset)
	local tween = TweenService:Create(cooldownBar, tweenInfo, { Size = targetSize })

	tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
		if playbackState == Enum.PlaybackState.Completed then
			fadeOutAndDestroy(frame)
		end
	end)
	tween:Play()
end

--- Removes all active notifications immediately.
function Notification.hideAll()
	for _, child in NotificationHolder:GetChildren() do
		if child:IsA("Frame") and child ~= NotificationTemplate then
			child:Destroy()
		end
	end
end

return Notification
