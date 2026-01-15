local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local ChatTags = require(ReplicatedStorage.TowerGame.Shared.Data.ChatTags)

local playerTags: { [number]: { Text: string, Color: string } } = {}

local function updatePlayerTag(player: Player)
	local name = ChatTags.USER_TAGS[player.UserId]

	if not name then
		for id, tagName in ChatTags.GAMEPASS_TAGS do
			local _, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
			if owns then
				name = tagName
				break
			end
		end
	end

	if not name then
		for _, group in ChatTags.GROUP_TAGS do
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

	local tag = name and ChatTags.TAGS[name]
	if tag then
		playerTags[player.UserId] = { Text = tag.Text, Color = `#{tag.Color:ToHex()}` }
	end
end

local function init()
	local function onAdded(player)
		task.spawn(updatePlayerTag, player)
	end

	for _, p in Players:GetPlayers() do
		onAdded(p)
	end

	Players.PlayerAdded:Connect(onAdded)

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

return {
	init = init,
}
