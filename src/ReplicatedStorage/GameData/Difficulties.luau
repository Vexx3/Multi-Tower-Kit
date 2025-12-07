local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

type DifficultyInfo = Types.DifficultyInfo

local Difficulties: { [string]: DifficultyInfo } = {
	Easy = {
		Title = "Easy",
		Rating = 1,

		FancyFont = false,
		Color = Color3.fromRGB(124, 255, 77),
		GlobalAnnouncement = false,

		DifficultyEmoji = "<:Easy:1301038309509955605>",
	},

	Medium = {
		Title = "Medium",
		Rating = 2,

		FancyFont = false,
		Color = Color3.fromRGB(255, 255, 0),
		GlobalAnnouncement = false,

		DifficultyEmoji = "<:Medium:1301040372608143401>",
	},

	Hard = {
		Title = "Hard",
		Rating = 3,

		FancyFont = false,
		Color = Color3.fromRGB(255, 162, 0),
		GlobalAnnouncement = false,

		DifficultyEmoji = "<:Hard:1301040697356582933>",
	},

	Difficult = {
		Title = "Difficult",
		Rating = 4,

		FancyFont = false,
		Color = Color3.fromRGB(255, 80, 80),
		GlobalAnnouncement = false,

		DifficultyEmoji = "<:Difficult:1301040794169511977>",
	},

	Challenging = {
		Title = "Challenging",
		Rating = 5,

		FancyFont = false,
		Color = Color3.fromRGB(200, 0, 0),
		GlobalAnnouncement = false,

		DifficultyEmoji = "<:Challenging:1301041033382985789>",
	},

	Intense = {
		Title = "Intense",
		Rating = 6,

		FancyFont = false,
		Color = Color3.fromRGB(0, 0, 0),
		GlobalAnnouncement = false,

		DifficultyEmoji = "<:Intense:1301041176098508851>",
	},

	Remorseless = {
		Title = "Remorseless",
		Rating = 7,

		FancyFont = false,
		Color = Color3.fromRGB(255, 0, 230),
		GlobalAnnouncement = false,

		DifficultyEmoji = "<:Remorseless:1301041291215241321>",
	},

	Insane = {
		Title = "Insane",
		Rating = 8,

		FancyFont = false,
		Color = Color3.fromRGB(0, 0, 255),
		GlobalAnnouncement = true,

		DifficultyEmoji = "<:Insane:1301041430445162528>",
	},

	Extreme = {
		Title = "Extreme",
		Rating = 9,

		FancyFont = false,
		Color = Color3.fromRGB(3, 137, 255),
		GlobalAnnouncement = true,

		DifficultyEmoji = "<:Extreme:1301041835854004265>",
	},

	Terrifying = {
		Title = "Terrifying",
		Rating = 10,

		FancyFont = false,
		Color = Color3.fromRGB(0, 255, 255),
		GlobalAnnouncement = true,

		DifficultyEmoji = "<:Terrifying:1301041950010642483>",
	},

	Catastrophic = {
		Title = "Catastrophic",
		Rating = 11,

		FancyFont = true,
		Color = Color3.fromRGB(255, 255, 255),
		GlobalAnnouncement = true,

		DifficultyEmoji = "<:Catastrophic:1301042083179663362>",
	},

	Horrific = {
		Title = "Horrific",
		Rating = 12,

		FancyFont = true,
		Color = Color3.fromRGB(255, 163, 252),
		GlobalAnnouncement = true,
	},

	Unreal = {
		Title = "Unreal",
		Rating = 13,

		FancyFont = true,
		Color = Color3.fromRGB(161, 0, 194),
		GlobalAnnouncement = true,
	},
}

return Difficulties
