local UIManager = {}

type LayerData = {
	frame: Frame?,
	button: GuiButton?,
	color: Color3?
}

local activeData: { [string]: LayerData } = {
	Main = {frame = nil, button = nil, color = nil},
	Sub = {frame = nil, button = nil, color = nil}
}

local ACTIVE_COLOR = Color3.fromRGB(166, 227, 161)
local CLICK_SOUND = script.UIClick
local HOVER_SOUND = script.UIHover

function UIManager.PlayClick()
	CLICK_SOUND:Play()
end

function UIManager.PlayHover()
	HOVER_SOUND:Play()
end

function UIManager.OpenFrame(targetFrame: Frame, targetButton: GuiButton, isSubMenu: boolean)
	UIManager.PlayClick()

	-- Determine which layer we are working on
	local layerName = if isSubMenu then "Sub" else "Main"
	local layer: LayerData = activeData[layerName]

	if layer.button and layer.color then
		local prevStroke: UIStroke? = layer.button:FindFirstChildOfClass("UIStroke")
		if prevStroke then 
			prevStroke.Color = layer.color
		end
	end

	if layer.frame and layer.frame ~= targetFrame then
		layer.frame.Visible = false
	end

	local currentStroke = targetButton:FindFirstChildOfClass("UIStroke")
	if currentStroke then
		layer.color = currentStroke.Color
		currentStroke.Color = ACTIVE_COLOR
	end

	targetFrame.Visible = true

	layer.frame = targetFrame
	layer.button = targetButton
end

return UIManager