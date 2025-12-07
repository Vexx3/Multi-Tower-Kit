function CheckColor3(color)
	return typeof(color) == "Color3"
end

function GetAllButtons(color)
	local isColor3 = CheckColor3(color)
	local ButtonTable = {}
	for _, v in workspace:GetDescendants() do
		if v.Name == "Button" and v:FindFirstChild("ClientObject") and v:FindFirstChild("Pressed") then
			local Insert = false
			if color and isColor3 then
				for _, b in v:GetDescendants() do
					if b:IsA("BasePart") and b.Color == color then
						Insert = true
					end
				end
			else
				Insert = true
			end
			if Insert then
				table.insert(ButtonTable, v)
			end
		end
	end
	return ButtonTable
end

local ButtonMT = {}
function ButtonMT:__newindex() end
function ButtonMT:__index(color)
	if color == "All" then
		return GetAllButtons()
	end
	return GetAllButtons(color)
end

function ButtonMT:__call(mode, value, color)
	if mode == "Get" then
		return GetAllButtons()
	elseif mode == "SetAll" then
		for _, v in GetAllButtons(color) do
			v.Pressed.Value = value
		end
	end
	return nil
end

_G.Buttons = setmetatable({}, ButtonMT)
