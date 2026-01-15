-- Multi Tower Kit: Handles studio-specific debug items and validation warnings.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")

local Framework = ReplicatedStorage.Framework
local Log = require(Framework.Log)

local STARTER_PACK_STUDIO = ServerStorage:FindFirstChild("StarterPackStudio") :: Folder

local DebugService = {}

function DebugService.init()
	if RunService:IsStudio() and STARTER_PACK_STUDIO then
		Log({ "Running in Studio, loading debug tools..." })
		for _, tool in STARTER_PACK_STUDIO:GetChildren() do
			tool:SetAttribute("DebugItem", true)
			tool.Parent = StarterPack
		end
	end

	for _, tool in StarterPack:GetChildren() do
		if not tool:IsA("Tool") then
			continue
		end

		local boostNameValue = tool:FindFirstChild("BoostName")
		if boostNameValue and boostNameValue:IsA("StringValue") then
			Log({
				type = "warn",
				[1] = `Boost item {tool.Name} uses a StringValue for BoostName, please change it to an attribute, as a StringValue can be manipulated (or even deleted by client)`,
			})
			tool:SetAttribute("BoostName", boostNameValue.Value)
		end
	end
end

return DebugService
