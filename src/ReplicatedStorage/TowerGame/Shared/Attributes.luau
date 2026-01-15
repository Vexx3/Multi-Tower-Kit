-- Utility functions for reading attributes with fallback to Value objects.
-- Supports both modern attributes and legacy ValueBase children.

local Attributes = {}

function Attributes.getNumber(instance: Instance, name: string): number?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("NumberValue") then
		return child.Value
	end
	local attr: number? = instance:GetAttribute(name) :: any
	return attr
end

function Attributes.getInt(instance: Instance, name: string): number?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("IntValue") then
		return child.Value
	end
	local attr: number? = instance:GetAttribute(name) :: any
	return attr
end

function Attributes.getString(instance: Instance, name: string): string?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("StringValue") then
		return child.Value
	end
	local attr: string? = instance:GetAttribute(name) :: any
	return attr
end

function Attributes.getBoolean(instance: Instance, name: string): boolean?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("BoolValue") then
		return child.Value
	end
	local attr: boolean? = instance:GetAttribute(name) :: any
	return attr
end

return Attributes
