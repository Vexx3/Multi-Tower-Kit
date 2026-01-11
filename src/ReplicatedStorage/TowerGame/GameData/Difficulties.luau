-- More info: https://vexx3.github.io/MTK-Dev/docs/Configuration#configuring-difficulties

local Types = require("../Shared/Types")

type DifficultyInfo = Types.DifficultyInfo

local Difficulties: { [string]: DifficultyInfo } = {
	Easy = {
		Title = "Easy",
		Rating = 1,

		FancyFont = false,
		Color = Color3.fromRGB(124, 255, 77),
		GlobalAnnouncement = false,
		GlobalAJAnnouncement = false,

		DifficultyImage = "rbxassetid://83047584080250",

		DifficultyEmoji = "<:Easy:1301038309509955605>",
	},

	Medium = {
		Title = "Medium",
		Rating = 2,

		FancyFont = false,
		Color = Color3.fromRGB(255, 255, 0),
		GlobalAnnouncement = false,

		DifficultyImage = "rbxassetid://119769712720704",

		DifficultyEmoji = "<:Medium:1301040372608143401>",
	},

	Hard = {
		Title = "Hard",
		Rating = 3,

		FancyFont = false,
		Color = Color3.fromRGB(255, 162, 0),
		GlobalAnnouncement = false,

		DifficultyImage = "rbxassetid://140187386588235",

		DifficultyEmoji = "<:Hard:1301040697356582933>",
	},

	Difficult = {
		Title = "Difficult",
		Rating = 4,

		FancyFont = false,
		Color = Color3.fromRGB(255, 80, 80),
		GlobalAnnouncement = false,

		DifficultyImage = "rbxassetid://139841926896555",

		DifficultyEmoji = "<:Difficult:1301040794169511977>",
	},

	Challenging = {
		Title = "Challenging",
		Rating = 5,

		FancyFont = false,
		Color = Color3.fromRGB(200, 0, 0),
		GlobalAnnouncement = false,

		DifficultyImage = "rbxassetid://94154288411120",

		DifficultyEmoji = "<:Challenging:1301041033382985789>",
	},

	Intense = {
		Title = "Intense",
		Rating = 6,

		FancyFont = false,
		Color = Color3.fromRGB(0, 0, 0),
		GlobalAnnouncement = false,

		DifficultyImage = "rbxassetid://101774383327800",

		DifficultyEmoji = "<:Intense:1301041176098508851>",
	},

	Remorseless = {
		Title = "Remorseless",
		Rating = 7,

		FancyFont = false,
		Color = Color3.fromRGB(255, 0, 230),
		GlobalAnnouncement = false,

		DifficultyImage = "rbxassetid://116331833567780",

		DifficultyEmoji = "<:Remorseless:1301041291215241321>",
	},

	Insane = {
		Title = "Insane",
		Rating = 8,

		FancyFont = false,
		Color = Color3.fromRGB(0, 0, 255),
		GlobalAnnouncement = true,
		GlobalAJAnnouncement = true,

		DifficultyImage = "rbxassetid://82804483457618",

		DifficultyEmoji = "<:Insane:1301041430445162528>",
	},

	Extreme = {
		Title = "Extreme",
		Rating = 9,

		FancyFont = false,
		Color = Color3.fromRGB(3, 137, 255),
		GlobalAnnouncement = true,

		DifficultyImage = "rbxassetid://92001649502043",

		DifficultyEmoji = "<:Extreme:1301041835854004265>",
	},

	Terrifying = {
		Title = "Terrifying",
		Rating = 10,

		FancyFont = false,
		Color = Color3.fromRGB(0, 255, 255),
		GlobalAnnouncement = true,

		DifficultyImage = "rbxassetid://86595383533997",

		DifficultyEmoji = "<:Terrifying:1301041950010642483>",
	},

	Catastrophic = {
		Title = "Catastrophic",
		Rating = 11,

		FancyFont = true,
		Color = Color3.fromRGB(255, 255, 255),
		GlobalAnnouncement = true,

		DifficultyImage = "rbxassetid://102078640534270",

		DifficultyEmoji = "<:Catastrophic:1301042083179663362>",
	},

	Horrific = {
		Title = "Horrific",
		Rating = 12,

		FancyFont = true,
		Color = Color3.fromRGB(255, 163, 252),
		GlobalAnnouncement = true,

		DifficultyImage = "rbxassetid://87361619716878",
	},

	Unreal = {
		Title = "Unreal",
		Rating = 13,

		FancyFont = true,
		Color = Color3.fromRGB(161, 0, 194),
		GlobalAnnouncement = true,

		DifficultyImage = "rbxassetid://76309329757383",
	},
}

local function GetSubDetails(num: number)
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

return table.freeze({
	Data = Difficulties,
	GetSubDetails = GetSubDetails,
})
