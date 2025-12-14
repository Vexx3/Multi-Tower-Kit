-- Licensed under the MIT License
-- Copyright (c) 2025 Zylx

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared

local Util = require(Shared.Util)
local ZapServer = require(ServerScriptService.ZapServer)
local args = require(Shared.ConchTypes)
local conch = require(ReplicatedStorage.Packages.conch)

return function()
	conch.register("fakewin", {
		description = "Broadcasts a fake win message (no stats/badges)",
		permissions = { "fake-win" },
		arguments = function()
			return conch.args.player("player", "Player to display as winner"),
				conch.args.string("ending", "Ending/Tower name to display"),
				conch.args.optional(args.difficulty_name("difficulty", "Difficulty name")),
				conch.args.optional(conch.args.number("time", "Run time in seconds")),
				conch.args.optional(conch.args.boolean("global", "Send as global message"))
		end,

		callback = function(
			player: Player,
			endingName: string,
			difficulty: string?,
			time: number?,
			isGlobal: boolean?
		)
			local difficultyName = difficulty or "default"
			local runTime = time or 0
			local globalFlag = if isGlobal then isGlobal else false

			local diffInfo = Util:GetDifficulty(difficultyName)
			local clientMsgInfo = {
				PlayerName = player.Name,
				EndingName = endingName,
				Time = runTime,
				BoostsUsed = {},
				Color = diffInfo.Color,
				FancyFont = diffInfo.FancyFont,
				Global = globalFlag,
			}

			ZapServer.GameWinAnnouncement.FireAll(clientMsgInfo)
			conch.log(
				"info",
				`Sent fake win for {player.Name} on '{endingName}' ({difficulty}) at {time}s`
			)
		end,
	})
end
