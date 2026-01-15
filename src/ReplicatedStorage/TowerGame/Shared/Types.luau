-- Defines common types used across the MTK codebase.

-- Convenience
export type List<T> = { [number]: T }
export type Dictionary<T> = { [string]: T }

type BasicTowerInfo = {
	name: string,
	difficulty: string,
	badgeId: number,
}

type Seconds = number

type TimeStat = {
	seconds: Seconds,
	formatted: string,
}

type PlayerRunTime = {
	player: Player,
	gameTimer: Seconds,
	lastRestart: Seconds,
}

type PlayerTowerState = {
	currentTower: string,
	currentCheckpoint: number,
	towerTimer: Seconds,
	mode: PlayerMode,
}

type PlayerRushState = {
	currentTowerRush: string,
	currentTowerRushIndex: number,
	currentTowerRushSplitTime: Seconds,
}

type PlayerFlags = {
	touchEventBusy: boolean,
	isLoadingTower: boolean,
	hasEverpresentCOs: boolean,
	debugItemUsed: boolean,
	boostItemUsed: boolean,
	boostItemNames: Dictionary<string>,
}

-- This type represents a tower
-- It uses the Instance type for the folders to allow flexibility between Folders and Models
-- but it mostly is used just to make working with Luau types less annoying lol
export type TowerInfo = BasicTowerInfo & {
	-- Basic information
	towerPoints: number,
	allJumpsPoints: number?,
	ajBadgeId: number?,
	noBoosts: boolean?,

	-- Important instances
	folder: Instance,
	spawnLocation: BasePart,
	clientObjects: Instance?,

	-- Endings
	endings: Dictionary<EndingInfo>,

	-- Anticheat stuff
	minimumTime: Seconds,
	checkpoints: List<BasePart>,
	checkpointCount: number,
}

export type TowerStat = {
	attempts: number,
	wins: number,
	allJumpsWins: number,

	totalTimeSpent: TimeStat,
	bestWinTime: TimeStat,
	bestAjWinTime: TimeStat,
}

-- Every tower is implicitly given an ending called "default", it inherits the
-- name and difficulty from its parent tower, and if a winpad is not
-- configured to trigger a special ending, the "default" ending will be triggered
export type EndingInfo = BasicTowerInfo & {
	preventTowerBadge: boolean,

	-- Relations
	parentTower: string,
	winroomMarker: string,
}

-- Represents a tower rush
export type TowerRush = {
	winroomMarker: string,
	towers: List<string>,
	noBoosts: boolean,
}

export type PlayerMode = "Normal" | "AllJumps" | "Practice"

-- Player Settings
export type Settings = {
	quickResetDelay: number,
	resetOnDeath: boolean,
	highFPSPhysicsFix: boolean,
	utility: "Off" | "Emote" | "Alignment",
	lowDetailMode: "Off" | "On" | "Ultra",
	fpsDisplay: boolean,
	hideTimer: boolean,
	invisiblePlayers: "Off" | "Not Friended" | "Everyone Else" | "Near",
	keyDisplayLimit: number,
	hideBubbleChat: boolean,
	musicVolume: number,
	keybinds: {
		quickRestart: string,
		cornerFlip: string,
		createCheckpoint: string,
		teleportCheckpoint: string,
		removeCheckpoint: string,
		playAnimation: string,
	},
	extendedCompletions: boolean,
}

export type PlayerData = {
	towers: number,
	allJumps: number,
	completedTowers: { string },
	completedAjTowers: { string },
	towerStats: { [string]: TowerStat },
	completedTowerRushes: { string },
	towerRushStats: { [string]: TowerStat },
	settings: Settings,
}

-- Represents a player, also containing information specific to them
export type PlayerInfo = PlayerRunTime & PlayerTowerState & PlayerRushState & PlayerFlags

-- Representing a difficulty, storing both cosmetic and pragmatic information about it
export type DifficultyInfo = {
	read title: string,
	read rating: number,

	read fancyFont: boolean,
	read color: Color3,
	read globalAnnouncement: boolean,
	read globalAjAnnouncement: boolean?,

	-- realm related
	read difficultyImage: string?,

	-- webhook emojis
	read difficultyEmoji: string?,
}

export type RealmTowerInfo = {
	read name: string,
	read badgeId: number,
	read rating: number,
	read numDifficulty: number,
	read rush: boolean?,
}

export type RealmArea = {
	read title: string,
	read emblem: string,
	read placeId: number,
	read towers: Dictionary<RealmTowerInfo>,
	read requirements: {
		read points: number,
		read difficultyLocks: List<{ read rating: number, read count: number }>,
	}?,
}

export type RealmWorld = Dictionary<RealmArea>
export type Realms = Dictionary<RealmWorld>

return nil
