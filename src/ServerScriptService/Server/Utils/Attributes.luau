local Attributes = {}

function Attributes:GetNumber(instance: Instance, name: string): number?
	local Val = instance:FindFirstChild(name)
	if Val and Val:IsA("NumberValue") then
		return Val.Value
	end
	return instance:GetAttribute(name) :: number?
end

function Attributes:GetInt(instance: Instance, name: string): number?
	local Val = instance:FindFirstChild(name)
	if Val and Val:IsA("IntValue") then
		return Val.Value
	end
	return instance:GetAttribute(name) :: number?
end

function Attributes:GetString(instance: Instance, name: string): string?
	local Val = instance:FindFirstChild(name)
	if Val and Val:IsA("StringValue") then
		return Val.Value
	end
	return instance:GetAttribute(name) :: string?
end

function Attributes:GetBoolean(instance: Instance, name: string): boolean?
	local Val = instance:FindFirstChild(name)
	if Val and Val:IsA("BoolValue") then
		return Val.Value
	end
	return instance:GetAttribute(name) :: boolean?
end

return Attributes
