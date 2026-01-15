-- Handles chat tag prefixes based on user IDs, gamepasses, and group roles.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared

local ChatTagsData = require(Shared.Data.ChatTags)

type PlayerTag = {
	Text: string,
	Color: string,
}

local playerTags: { [number]: PlayerTag } = {}

local ChatTagsClient = {}

-- Determines and caches the appropriate chat tag for a player.
local function updatePlayerTag(player: Player): ()
	local name = ChatTagsData.USER_TAGS[player.UserId]

	if not name then
		for id, tagName in ChatTagsData.GAMEPASS_TAGS do
			local _, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
			if owns then
				name = tagName
				break
			end
		end
	end

	if not name then
		for _, group in ChatTagsData.GROUP_TAGS do
			if not group.GroupId or not group.Roles then
				continue
			end

			local _, rank = pcall(player.GetRankInGroupAsync, player, group.GroupId)
			if rank and group.Roles[rank] then
				name = group.Roles[rank]
				break
			end
		end
	end

	local tag = name and ChatTagsData.TAGS[name]
	if tag then
		playerTags[player.UserId] = { Text = tag.Text, Color = `#{tag.Color:ToHex()}` }
	end
end

-- Handles player added events.
local function onPlayerAdded(player: Player): ()
	task.spawn(updatePlayerTag, player)
end

-- Initializes the chat tags system.
function ChatTagsClient.init(): ()
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)

	TextChatService.OnIncomingMessage = function(message)
		local props = Instance.new("TextChatMessageProperties")
		local player = message.TextSource and Players:GetPlayerByUserId(message.TextSource.UserId)
		local tag = player and playerTags[player.UserId]

		if tag then
			props.PrefixText = `<font color="{tag.Color}">{tag.Text}</font> {message.PrefixText}`
		end

		return props
	end
end

return ChatTagsClient
