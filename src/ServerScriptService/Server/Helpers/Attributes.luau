-- Licensed under the MIT License
-- Original Copyright (c) 2023 fanofpixels
-- Modifications Copyright (c) 2025 Zylx

local Attributes = {}

function Attributes:GetNumber(instance: Instance, name: string): number?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("NumberValue") then
		return child.Value
	end
	return instance:GetAttribute(name) :: number?
end

function Attributes:GetInt(instance: Instance, name: string): number?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("IntValue") then
		return child.Value
	end
	return instance:GetAttribute(name) :: number?
end

function Attributes:GetString(instance: Instance, name: string): string?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("StringValue") then
		return child.Value
	end
	return instance:GetAttribute(name) :: string?
end

function Attributes:GetBoolean(instance: Instance, name: string): boolean?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("BoolValue") then
		return child.Value
	end
	return instance:GetAttribute(name) :: boolean?
end

return Attributes
