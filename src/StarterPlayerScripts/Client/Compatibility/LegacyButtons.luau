-- Legacy button compatibility layer for older tower scripts.
-- Provides a global _G.Buttons interface for querying and controlling buttons.

export type ButtonInstance = Model & {
	ClientObject: Instance,
	Pressed: BoolValue,
}

type ButtonMetatable = {
	__newindex: (self: ButtonTable, key: unknown, value: unknown) -> (),
	__index: (self: ButtonTable, color: Color3 | string) -> { ButtonInstance },
	__call: (self: ButtonTable, mode: string, value: boolean?, color: Color3?) -> { ButtonInstance }?,
}

type ButtonTable = typeof(setmetatable({} :: {}, {} :: ButtonMetatable))

local LegacyButtons = {}

local function checkColor3(color: unknown): boolean
	return typeof(color) == "Color3"
end

local function getAllButtons(color: Color3?): { ButtonInstance }
	local isColor3 = checkColor3(color)
	local buttonTable: { ButtonInstance } = {}

	for _, v in workspace:GetDescendants() do
		if v.Name == "Button" and v:FindFirstChild("ClientObject") and v:FindFirstChild("Pressed") then
			local shouldInsert = false

			if color and isColor3 then
				for _, b in v:GetDescendants() do
					if b:IsA("BasePart") and b.Color == color then
						shouldInsert = true
						break
					end
				end
			else
				shouldInsert = true
			end

			if shouldInsert then
				table.insert(buttonTable, v :: ButtonInstance)
			end
		end
	end

	return buttonTable
end

local buttonMt: ButtonMetatable = {} :: ButtonMetatable

function buttonMt:__newindex(_key: unknown, _value: unknown): ()
	-- Prevent modifications to the table
end

function buttonMt:__index(color: Color3 | string): { ButtonInstance }
	if color == "All" then
		return getAllButtons()
	end
	return getAllButtons(color :: Color3)
end

function buttonMt:__call(mode: string, value: boolean?, color: Color3?): { ButtonInstance }?
	if mode == "Get" then
		return getAllButtons()
	elseif mode == "SetAll" then
		for _, button in getAllButtons(color) do
			button.Pressed.Value = value or false
		end
	end
	return nil
end

-- Initializes the legacy buttons interface.
function LegacyButtons.init(): ()
	_G.Buttons = setmetatable({}, buttonMt)
end

return LegacyButtons
