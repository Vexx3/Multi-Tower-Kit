-- Licensed under the MIT License
-- Copyright (c) 2025 Zylx

local TweenService = game:GetService("TweenService")

local GUIHandler = {}

-- ToggleUI automatically shows/hides and slides
-- x: target X position for showing
function GUIHandler:ToggleUI(frame: Frame, targetX: number, callback: (opening: boolean) -> ())
	if frame.Visible then
		-- hide
		local tween = TweenService:Create(
			frame,
			TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
			{ Position = UDim2.fromScale(-1, frame.Position.Y.Scale) }
		)
		tween:Play()
		tween.Completed:Once(function()
			frame.Visible = false

			if callback then
				callback(false)
			end
		end)
	else
		-- show
		frame.Visible = true
		local tween = TweenService:Create(
			frame,
			TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
			{ Position = UDim2.fromScale(targetX, frame.Position.Y.Scale) }
		)
		tween:Play()
		tween.Completed:Once(function()
			if callback then
				callback(true)
			end
		end)
	end
end

return GUIHandler
