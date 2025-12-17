-- Licensed under the MIT License
-- Copyright (c) 2025 Zylx

--[=[
	Legacy button compatibility layer for older tower scripts.
	Provides a global _G.Buttons interface for querying and controlling buttons.

	@class LegacyButtons
	@client
]=]

export type ButtonInstance = Model & {
	ClientObject: Instance,
	Pressed: BoolValue,
}

type ButtonMetatable = {
	__newindex: (self: ButtonTable, key: any, value: any) -> (),
	__index: (self: ButtonTable, color: Color3 | string) -> { ButtonInstance },
	__call: (self: ButtonTable, mode: string, value: boolean?, color: Color3?) -> { ButtonInstance }?,
}

type ButtonTable = typeof(setmetatable({} :: {}, {} :: ButtonMetatable))

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

local ButtonMT: ButtonMetatable = {} :: ButtonMetatable

function ButtonMT:__newindex(_key: any, _value: any): ()
	-- Prevent modifications to the table
end

function ButtonMT:__index(color: Color3 | string): { ButtonInstance }
	if color == "All" then
		return getAllButtons()
	end
	return getAllButtons(color :: Color3)
end

function ButtonMT:__call(mode: string, value: boolean?, color: Color3?): { ButtonInstance }?
	if mode == "Get" then
		return getAllButtons()
	elseif mode == "SetAll" then
		for _, button in getAllButtons(color) do
			button.Pressed.Value = value or false
		end
	end
	return nil
end

local LegacyButtons = {}

function LegacyButtons.Init(): ()
	_G.Buttons = setmetatable({}, ButtonMT)
end

return LegacyButtons
