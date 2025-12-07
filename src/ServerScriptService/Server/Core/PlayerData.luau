-- @zylx 2025-11-20
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameData = ReplicatedStorage.GameData
local Packages = ReplicatedStorage.Packages

local Config = require(GameData.Config)
local ProfileStore = require(Packages.ProfileStore)

local DATA_STORE_KEY = Config.DATA_STORE_KEY

if RunService:IsStudio() then
	DATA_STORE_KEY = Config.DATA_STORE_KEY_STUDIO
end

local PlayerStore = ProfileStore.New(DATA_STORE_KEY, Config.DEFAULT_PLAYER_DATA)
local Profiles: { [Player]: typeof(PlayerStore:StartSessionAsync()) } = {}

local function LoadProfile(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	
	if profile == nil then
		return player:Kick("Profile load fail. Please rejoin.")
	end
	
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	
	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick("Profile session ended. Please rejoin.")
	end)
	
	local isInGame = player.Parent == Players
	if isInGame then
		Profiles[player] = profile
	else
		profile:EndSession()
	end

	return nil
end

local function RemoveProfile(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end

local PlayerData = {}

function PlayerData:GetData(player: Player): Config.PlayerData?
	local profile = Profiles[player]
	if not profile then
		return nil
	end
	
	return profile.Data
end

function PlayerData:Init()
	for _, player in Players:GetPlayers() do
		task.spawn(LoadProfile, player)
	end

	Players.PlayerAdded:Connect(LoadProfile)
	Players.PlayerRemoving:Connect(RemoveProfile)
end

return PlayerData
