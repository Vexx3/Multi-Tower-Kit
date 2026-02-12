--[[
	Utility functions for reading attributes with fallback to Value objects.
]]

local function asNumber(value: unknown): number?
	if typeof(value) == "number" then
		return value
	end
	return nil
end

local function asString(value: unknown): string?
	if typeof(value) == "string" then
		return value
	end
	return nil
end

local function asBoolean(value: unknown): boolean?
	if typeof(value) == "boolean" then
		return value
	end
	return nil
end

local Attributes = {}

--- Gets a number attribute or NumberValue from an instance.
--- @param instance Instance -- The instance to read from
--- @param name string -- The attribute/child name
--- @return number? -- The value, or nil if not found
function Attributes.getNumber(instance: Instance, name: string): number?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("NumberValue") then
		return child.Value
	end
	return asNumber(instance:GetAttribute(name))
end

--- Gets an integer attribute or IntValue from an instance.
--- @param instance Instance -- The instance to read from
--- @param name string -- The attribute/child name
--- @return number? -- The value, or nil if not found
function Attributes.getInt(instance: Instance, name: string): number?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("IntValue") then
		return child.Value
	end
	return asNumber(instance:GetAttribute(name))
end

--- Gets a string attribute or StringValue from an instance.
--- @param instance Instance -- The instance to read from
--- @param name string -- The attribute/child name
--- @return string? -- The value, or nil if not found
function Attributes.getString(instance: Instance, name: string): string?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("StringValue") then
		return child.Value
	end
	return asString(instance:GetAttribute(name))
end

--- Gets a boolean attribute or BoolValue from an instance.
--- @param instance Instance -- The instance to read from
--- @param name string -- The attribute/child name
--- @return boolean? -- The value, or nil if not found
function Attributes.getBoolean(instance: Instance, name: string): boolean?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("BoolValue") then
		return child.Value
	end
	return asBoolean(instance:GetAttribute(name))
end

return Attributes
