-- More information about these types is available in the documentation:
-- https://vexx3.github.io/MTK-Dev/api/Types

-- Convenience
export type List<T> = { [number]: T }
export type Dictionary<T> = { [string]: T }

-- This type represents a tower
-- It uses the Instance type for the folders to allow flexebility between Folders and Models
-- but it mostly is used just to make working with Luau types less annoying lol
export type TowerInfo = {
	-- Basic information
	Name: string,
	Difficulty: string,
	BadgeID: number,
	TowerPoints: number,
	AllJumpsPoints: number?,
	AJBadgeID: number?,
	NoBoosts: boolean?,

	-- Important instances
	Folder: Instance,
	SpawnLocation: BasePart,
	ClientObjects: Instance?,

	-- Endings
	Endings: Dictionary<EndingInfo>,

	-- Anticheat stuff
	MinimumTime: number,
	Checkpoints: List<BasePart>,
	CheckpointCount: number,
}

export type TowerStat = {
	Attempts: number,
	Wins: number,
	AllJumpsWins: number,
	TotalTimeSpentSeconds: number,
	TotalTimeSpentFormatted: string,
	BestWinTimeSeconds: number,
	BestWinTimeFormatted: string,
	BestAJWinTimeSeconds: number,
	BestAJWinTimeFormatted: string,
}

-- The Ending type represents an ending for a tower, this type was created to account for "secret endings" some towers have
-- Every ending has it's own difficulty, seperate from the tower's

-- Every tower is implictly given an ending called "default", it inherits the
-- name and difficulty from it's parent tower, and if a winpad is not
-- configured to trigger a special ending, the "default" ending will be triggered
export type EndingInfo = {
	-- Basic info
	Name: string,
	Difficulty: string,

	-- Badges
	BadgeID: number,
	PreventTowerBadge: boolean,

	-- Relations
	ParentTower: string,
	WinroomMarker: string,
}

-- Represents a tower rush
export type TowerRush = {
	WinroomMarker: string,
	Towers: List<string>,
	NoBoosts: boolean,
}

-- Represents a player, also containing information specific to them
export type PlayerInfo = {
	-- Game information
	Player: Player,
	GameTimer: number,
	LastRestart: number,

	-- Tower information
	CurrentTower: string,
	CurrentTowerCheckpoint: number,
	BoostItemNames: Dictionary<string>,
	BoostItemUsed: boolean,
	TowerTimer: number,
	AllJumpsMode: boolean,
	PracticeMode: boolean,

	-- Tower rush information
	CurrentTowerRush: string,
	CurrentTowerRushIndex: number,
	CurrentTowerRushSplitTime: number,

	-- Technical flags
	TouchEventBusy: boolean,
	IsLoadingTower: boolean,
	HasEverpresentCOs: boolean,
	DebugItemUsed: boolean,
}

-- Representing a difficulty, storing both cosmetic and pragmatic information about it
export type DifficultyInfo = {
	Title: string,
	Rating: number,

	FancyFont: boolean,
	Color: Color3,
	GlobalAnnouncement: boolean,
	GlobalAJAnnouncement: boolean?,

	-- realm related
	DifficultyImage: string?,

	-- webhook emojis
	DifficultyEmoji: string?,
}

return nil
