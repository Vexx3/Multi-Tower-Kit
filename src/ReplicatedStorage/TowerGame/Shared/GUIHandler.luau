-- Provides reusable animations and state transitions for UI components.

local TweenService = game:GetService("TweenService")

local DEFAULT_TOGGLE_DURATION = 0.5
local DEFAULT_SHRINK_DURATION = 0.3

local originalSizes: { [GuiObject]: UDim2 } = {}

local GUIHandler = {}

function GUIHandler.toggleUI(
	canvasGroup: CanvasGroup,
	show: boolean?,
	duration: number?,
	callback: ((opening: boolean) -> ())?
): ()
	local tweenDuration = duration or DEFAULT_TOGGLE_DURATION
	local isVisible = canvasGroup.GroupTransparency < 1
	local shouldShow = if show ~= nil then show else not isVisible
	local targetTransparency = if shouldShow then 0 else 1

	if shouldShow then
		canvasGroup.Visible = true
	end

	local tween = TweenService:Create(
		canvasGroup,
		TweenInfo.new(tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ GroupTransparency = targetTransparency }
	)

	tween:Play()
	tween.Completed:Once(function()
		if not shouldShow then
			canvasGroup.Visible = false
		end

		if callback then
			callback(shouldShow)
		end
	end)
end

function GUIHandler.shrinkAnimation(
	guiObject: GuiObject,
	show: boolean?,
	duration: number?,
	callback: ((opening: boolean) -> ())?
): ()
	local tweenDuration = duration or DEFAULT_SHRINK_DURATION
	local isVisible = guiObject.Visible and guiObject.Size.X.Scale > 0.01
	local shouldShow = if show ~= nil then show else not isVisible

	if not originalSizes[guiObject] then
		originalSizes[guiObject] = guiObject.Size
	end

	local originalSize = originalSizes[guiObject]
	local hiddenSize = UDim2.new(0, 0, 0, 0)
	local targetSize = if shouldShow then originalSize else hiddenSize

	if shouldShow then
		guiObject.Size = hiddenSize
		guiObject.Visible = true
	end

	local tween = TweenService:Create(
		guiObject,
		TweenInfo.new(
			tweenDuration,
			Enum.EasingStyle.Back,
			if shouldShow then Enum.EasingDirection.Out else Enum.EasingDirection.In
		),
		{ Size = targetSize }
	)

	tween:Play()
	tween.Completed:Once(function()
		if not shouldShow then
			guiObject.Visible = false
		end

		if callback then
			callback(shouldShow)
		end
	end)
end

return GUIHandler
