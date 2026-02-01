local Leaderboard = {}

local function setupLeaderboard(player: Player)
	local leaderstats = Instance.new("Folder")
	-- 'leaderstats' is a reserved name Roblox recognizes for creating a leaderboard
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	return leaderstats
end

local function setupStat(leaderstats: Folder, statName: string)
	local stat = Instance.new("IntValue")
	stat.Name = statName
	stat.Value = 0
	stat.Parent = leaderstats
	return stat
end

function Leaderboard.setStat(player: Player, statName: string, value: any)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = setupLeaderboard(player)
	end

	local stat = leaderstats:FindFirstChild(statName)
	if not stat then
		stat = setupStat(leaderstats, statName)
	end

	stat.Value = value
end

return Leaderboard
