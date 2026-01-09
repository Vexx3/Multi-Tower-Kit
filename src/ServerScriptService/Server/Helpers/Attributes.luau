local Attributes = {}

function Attributes.getNumber(instance: Instance, name: string): number?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("NumberValue") then
		return child.Value
	end
	return instance:GetAttribute(name) :: number?
end

function Attributes.getInt(instance: Instance, name: string): number?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("IntValue") then
		return child.Value
	end
	return instance:GetAttribute(name) :: number?
end

function Attributes.getString(instance: Instance, name: string): string?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("StringValue") then
		return child.Value
	end
	return instance:GetAttribute(name) :: string?
end

function Attributes.getBoolean(instance: Instance, name: string): boolean?
	local child = instance:FindFirstChild(name)
	if child and child:IsA("BoolValue") then
		return child.Value
	end
	return instance:GetAttribute(name) :: boolean?
end

return Attributes
