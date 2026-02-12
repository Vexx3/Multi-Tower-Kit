--[[
	Command: /fakewin <player> <ending> [difficulty] [time] [global]
	Broadcasts a fake win message (no stats/badges awarded).
]]

local BlinkServer = require("../../Network/BlinkServer")
local ConchTypes = require("../../../shared/conchTypes")
local Util = require("../../../shared/utils/util")
local conch = require("../../../../Packages/conch")

return function()
	conch.register("fakewin", {
		description = "Broadcasts a fake win message (no stats/badges)",
		permissions = { "fake-win" },
		arguments = function()
			return conch.args.player("player", "Player to display as winner"),
				conch.args.string("ending", "Ending/Tower name to display"),
				conch.args.optional(ConchTypes.difficultyName("difficulty", "Difficulty name")),
				conch.args.optional(conch.args.number("time", "Run time in seconds")),
				conch.args.optional(conch.args.boolean("global", "Send as global message"))
		end,

		callback = function(player: Player, endingName: string, difficulty: string?, time: number?, isGlobal: boolean?)
			local difficultyName = difficulty or "default"
			local runTime = time or 0
			local globalFlag = if isGlobal then isGlobal else false

			local diffInfo = Util.getDifficulty(difficultyName)
			local clientMsgInfo = {
				playerName = player.Name,
				endingName = endingName,
				time = runTime,
				boostsUsed = {},
				allJumps = false,
				color = diffInfo.color,
				fancyFont = diffInfo.fancyFont,
				global = globalFlag,
			}

			BlinkServer.GameWinAnnouncement.FireAll(clientMsgInfo)
			conch.log("info", `Sent fake win for {player.Name} on '{endingName}' ({difficulty}) at {time}s`)
		end,
	})
end
