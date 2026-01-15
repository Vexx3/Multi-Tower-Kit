-- Configuration for tower difficulties, including cosmetic and gameplay settings.

local Types = require("../Types")

type DifficultyInfo = Types.DifficultyInfo

local difficulties: { [string]: DifficultyInfo } = {
	Easy = {
		title = "Easy",
		rating = 1,

		fancyFont = false,
		color = Color3.fromRGB(124, 255, 77),
		globalAnnouncement = false,

		difficultyImage = "rbxassetid://83047584080250",

		difficultyEmoji = "<:Easy:1301038309509955605>",
	},

	Medium = {
		title = "Medium",
		rating = 2,

		fancyFont = false,
		color = Color3.fromRGB(255, 255, 0),
		globalAnnouncement = false,

		difficultyImage = "rbxassetid://119769712720704",

		difficultyEmoji = "<:Medium:1301040372608143401>",
	},

	Hard = {
		title = "Hard",
		rating = 3,

		fancyFont = false,
		color = Color3.fromRGB(255, 162, 0),
		globalAnnouncement = false,

		difficultyImage = "rbxassetid://140187386588235",

		difficultyEmoji = "<:Hard:1301040697356582933>",
	},

	Difficult = {
		title = "Difficult",
		rating = 4,

		fancyFont = false,
		color = Color3.fromRGB(255, 80, 80),
		globalAnnouncement = false,

		difficultyImage = "rbxassetid://139841926896555",

		difficultyEmoji = "<:Difficult:1301040794169511977>",
	},

	Challenging = {
		title = "Challenging",
		rating = 5,

		fancyFont = false,
		color = Color3.fromRGB(200, 0, 0),
		globalAnnouncement = false,

		difficultyImage = "rbxassetid://94154288411120",

		difficultyEmoji = "<:Challenging:1301041033382985789>",
	},

	Intense = {
		title = "Intense",
		rating = 6,

		fancyFont = false,
		color = Color3.fromRGB(0, 0, 0),
		globalAnnouncement = false,

		difficultyImage = "rbxassetid://101774383327800",

		difficultyEmoji = "<:Intense:1301041176098508851>",
	},

	Remorseless = {
		title = "Remorseless",
		rating = 7,

		fancyFont = false,
		color = Color3.fromRGB(255, 0, 230),
		globalAnnouncement = false,

		difficultyImage = "rbxassetid://116331833567780",

		difficultyEmoji = "<:Remorseless:1301041291215241321>",
	},

	Insane = {
		title = "Insane",
		rating = 8,

		fancyFont = false,
		color = Color3.fromRGB(0, 0, 255),
		globalAnnouncement = true,

		difficultyImage = "rbxassetid://82804483457618",

		difficultyEmoji = "<:Insane:1301041430445162528>",
	},

	Extreme = {
		title = "Extreme",
		rating = 9,

		fancyFont = false,
		color = Color3.fromRGB(3, 137, 255),
		globalAnnouncement = true,

		difficultyImage = "rbxassetid://92001649502043",

		difficultyEmoji = "<:Extreme:1301041835854004265>",
	},

	Terrifying = {
		title = "Terrifying",
		rating = 10,

		fancyFont = false,
		color = Color3.fromRGB(0, 255, 255),
		globalAnnouncement = true,

		difficultyImage = "rbxassetid://86595383533997",

		difficultyEmoji = "<:Terrifying:1301041950010642483>",
	},

	Catastrophic = {
		title = "Catastrophic",
		rating = 11,

		fancyFont = true,
		color = Color3.fromRGB(255, 255, 255),
		globalAnnouncement = true,

		difficultyImage = "rbxassetid://102078640534270",

		difficultyEmoji = "<:Catastrophic:1301042083179663362>",
	},

	Horrific = {
		title = "Horrific",
		rating = 12,

		fancyFont = true,
		color = Color3.fromRGB(255, 163, 252),
		globalAnnouncement = true,

		difficultyImage = "rbxassetid://87361619716878",
	},

	Unreal = {
		title = "Unreal",
		rating = 13,

		fancyFont = true,
		color = Color3.fromRGB(161, 0, 194),
		globalAnnouncement = true,

		difficultyImage = "rbxassetid://76309329757383",
	},

	["Nil"] = {
		title = "Nil",
		rating = 14,

		fancyFont = true,
		color = Color3.fromRGB(101, 102, 109),
		globalAnnouncement = true,
		globalAjAnnouncement = true,

		difficultyImage = "rbxassetid://71617965011918",
	},
}

local function getSubDetails(num: number)
	if num == 0 then
		return "Baseline", Color3.fromRGB(35, 202, 199)
	elseif num <= 0.11 then
		return "Bottom", Color3.fromRGB(35, 202, 132)
	elseif num <= 0.22 then
		return "Bottom-Low", Color3.fromRGB(35, 202, 65)
	elseif num <= 0.33 then
		return "Low", Color3.fromRGB(89, 202, 35)
	elseif num <= 0.44 then
		return "Low-Mid", Color3.fromRGB(151, 202, 35)
	elseif num <= 0.55 then
		return "Mid", Color3.fromRGB(201, 202, 35)
	elseif num <= 0.66 then
		return "Mid-High", Color3.fromRGB(202, 164, 35)
	elseif num <= 0.77 then
		return "High", Color3.fromRGB(202, 125, 35)
	elseif num <= 0.88 then
		return "High-Peak", Color3.fromRGB(202, 74, 35)
	elseif num <= 0.99 then
		return "Peak", Color3.fromRGB(202, 35, 35)
	end

	return "Unknown", Color3.fromRGB(255, 255, 255)
end

return {
	data = difficulties,
	getSubDetails = getSubDetails,
}
