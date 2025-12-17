-- Licensed under the MIT License
-- Copyright (c) 2025 Zylx

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local ChatTags = require(ReplicatedStorage.GameData.ChatTags)

local function getPlayerTag(player: Player): (string?, string?)
	-- Check UserId tags first
	local tagName = ChatTags.USER_TAGS[player.UserId]
	if tagName then
		local tag = ChatTags.TAGS[tagName]
		if tag then
			return tag.Text, tag.Color
		end
	end

	-- Check group tags
	for _, group in ChatTags.GROUP_TAGS do
		local rank = player:GetRankInGroup(group.GroupId)
		local groupTagName = group.Roles[rank]
		if groupTagName then
			local tag = ChatTags.TAGS[groupTagName]
			if tag then
				return tag.Text, tag.Color
			end
		end
	end

	return nil, nil
end

local ChatTagsModule = {}

function ChatTagsModule.Init(): ()
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local props = Instance.new("TextChatMessageProperties")

		if message.TextSource then
			local player = Players:GetPlayerByUserId(message.TextSource.UserId)
			if player then
				local tagText, tagColor = getPlayerTag(player)
				if tagText and tagColor then
					props.PrefixText = `<font color='{tagColor}'>{tagText}</font> ` .. message.PrefixText
				end
			end
		end

		return props
	end
end

return ChatTagsModule
