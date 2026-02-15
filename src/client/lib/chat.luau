--[[
	ChatController - Handles chat customization including tags and prefixes.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local ChatTagsData = require("../../shared/constants/chatTags")
local playerLifecycle = require("../../shared/utils/playerLifecycle")

type PlayerTag = {
	Text: string,
	Color: string,
}

type ResolverData = {
	player: Player,
	tag: PlayerTag?,
}

local resolvers: { [number]: ResolverData } = {}

local function resolvePlayerTag(player: Player): PlayerTag?
	local tagName: string? = nil

	-- Check user-specific tags first
	tagName = ChatTagsData.USER_TAGS[player.UserId]

	-- Check gamepass tags
	if not tagName then
		for id, name in ChatTagsData.GAMEPASS_TAGS do
			local _, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
			if owns then
				tagName = name
				break
			end
		end
	end

	-- Check group tags
	if not tagName then
		for _, group in ChatTagsData.GROUP_TAGS do
			if not group.GroupId or not group.Roles then
				continue
			end

			local _, rank = pcall(player.GetRankInGroupAsync, player, group.GroupId)
			if rank and group.Roles[rank] then
				tagName = group.Roles[rank]
				break
			end
		end
	end

	-- Return tag data if found
	local tagData = tagName and ChatTagsData.TAGS[tagName]
	if tagData then
		return {
			Text = tagData.Text,
			Color = `#{tagData.Color:ToHex()}`,
		}
	end

	return nil
end

local chat = {}

function chat.getPlayerTag(userId: number): PlayerTag?
	local resolver = resolvers[userId]
	return resolver and resolver.tag
end

function chat.init()
	playerLifecycle.onPlayerAdded(function(player)
		resolvers[player.UserId] = {
			player = player,
			tag = resolvePlayerTag(player),
		}
	end, function(player)
		resolvers[player.UserId] = nil
	end)

	TextChatService.OnIncomingMessage = function(message)
		local props = Instance.new("TextChatMessageProperties")
		local player = message.TextSource and Players:GetPlayerByUserId(message.TextSource.UserId)
		local tag = player and chat.getPlayerTag(player.UserId)

		if tag then
			props.PrefixText = `<font color="{tag.Color}">{tag.Text}</font> {message.PrefixText}`
		end

		return props
	end
end

return chat
