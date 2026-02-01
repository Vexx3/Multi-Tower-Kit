--[[
	ChatController - Handles chat customization including tags and prefixes.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared
local Packages = ReplicatedStorage.Packages

local ChatTagsData = require(Shared.Data.ChatTags)
local Observers = require(Packages.observers)

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

local ChatController = {}

function ChatController.getPlayerTag(userId: number): PlayerTag?
	local resolver = resolvers[userId]
	return resolver and resolver.tag
end

function ChatController.init()
	Observers.observePlayer(function(player)
		resolvers[player.UserId] = {
			player = player,
			tag = resolvePlayerTag(player),
		}
		return function() end
	end, function(player)
		resolvers[player.UserId] = nil
	end)

	TextChatService.OnIncomingMessage = function(message)
		local props = Instance.new("TextChatMessageProperties")
		local player = message.TextSource and Players:GetPlayerByUserId(message.TextSource.UserId)
		local tag = player and ChatController.getPlayerTag(player.UserId)

		if tag then
			props.PrefixText = `<font color="{tag.Color}">{tag.Text}</font> {message.PrefixText}`
		end

		return props
	end
end

return ChatController
