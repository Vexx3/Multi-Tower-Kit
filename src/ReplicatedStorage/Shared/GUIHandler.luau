-- Licensed under the MIT License
-- Copyright (c) 2025 Zylx

local TweenService = game:GetService("TweenService")

local GUIHandler = {}

-- Cache for storing original sizes
local originalSizes: { [GuiObject]: UDim2 } = {}

-- ToggleUI fades a CanvasGroup in/out using GroupTransparency
-- show: true to show (0), false to hide (1), nil to auto-toggle based on current state
-- duration: optional tween duration (default 0.5)
-- callback: optional function called when tween completes
function GUIHandler:ToggleUI(
	canvasGroup: CanvasGroup,
	show: boolean?,
	duration: number?,
	callback: ((opening: boolean) -> ())?
)
	local tweenDuration = duration or 0.5
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

-- ShrinkAnimation toggles UI visibility using a scale animation (shrink to hide, grow to show)
-- guiObject: the UI element to animate (Button, Frame, ImageLabel, etc.)
-- show: true to show, false to hide, nil to auto-toggle based on current visibility
-- duration: optional animation duration (default 0.3)
-- callback: optional function called when animation completes
function GUIHandler:ShrinkAnimation(
	guiObject: GuiObject,
	show: boolean?,
	duration: number?,
	callback: ((opening: boolean) -> ())?
)
	local tweenDuration = duration or 0.3
	local isVisible = guiObject.Visible and guiObject.Size.X.Scale > 0.01
	local shouldShow = if show ~= nil then show else not isVisible

	-- Store original size if not already cached
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
		TweenInfo.new(tweenDuration, Enum.EasingStyle.Back, if shouldShow then Enum.EasingDirection.Out else Enum.EasingDirection.In),
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
