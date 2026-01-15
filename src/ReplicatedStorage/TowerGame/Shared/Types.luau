-- Defines common types used across the MTK codebase.
-- All game-wide type definitions should live here.

export type List<T> = { [number]: T }
export type Dictionary<T> = { [string]: T }

type Seconds = number

export type TimeStat = {
	seconds: Seconds,
	formatted: string,
}

type BasicTowerInfo = {
	name: string,
	difficulty: string,
	badgeId: number,
}

export type TowerInfo = BasicTowerInfo & {
	towerPoints: number,
	allJumpsPoints: number?,
	ajBadgeId: number?,
	noBoosts: boolean?,

	folder: Instance,
	spawnLocation: BasePart,
	clientObjects: Instance?,

	endings: Dictionary<EndingInfo>,

	minimumTime: Seconds,
	checkpoints: List<BasePart>,
	checkpointCount: number,
}

export type EndingInfo = BasicTowerInfo & {
	preventTowerBadge: boolean,
	parentTower: string,
	winroomMarker: string,
}

export type TowerRush = {
	winroomMarker: string,
	towers: List<string>,
	noBoosts: boolean,
}

export type TowerStat = {
	attempts: number,
	wins: number,
	allJumpsWins: number,
	totalTimeSpent: TimeStat,
	bestWinTime: TimeStat,
	bestAjWinTime: TimeStat,
}

export type PlayerMode = "Normal" | "AllJumps" | "Practice"

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

export type PlayerInfo = PlayerRunTime & PlayerTowerState & PlayerRushState & PlayerFlags

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
	completedTowers: List<string>,
	completedAjTowers: List<string>,
	towerStats: Dictionary<TowerStat>,
	completedTowerRushes: List<string>,
	towerRushStats: Dictionary<TowerStat>,
	settings: Settings,
}

export type ClientConfig = {
	winMessage: string,
	winMessageAj: string,
	winMessageBoostsUsed: string,
	chatChannel: string,
	chatFontFace: string,
	chatFontSize: number,
	chatFancyFontFace: string,
	chatFancyFontSize: number,
}

export type GlobalConfig = {
	timerSyncInterval: number,
	checkpointInterval: number,
	restartCooldown: number,
	restartResetsTowerRush: boolean,
	winpadInterval: number,
	winpadsChangeColor: boolean,
	winpadsChangeMaterial: boolean,
	useDisplayName: boolean,
	checkpointsMissingWarning: boolean,
	noMinimumTimeWarning: boolean,
	r15Warning: boolean,
	dataStoreKey: string,
	dataStoreKeyStudio: string,
	webhooksEnabled: boolean,
	webhookNormalMessage: string,
	webhookAjMessage: string,
	webhookBoostsUsed: string,
	roles: Dictionary<List<string>>,
	userRoles: { [number]: List<string> },
	adminHotkey: Enum.KeyCode,
}

export type ChatTagDefinition = {
	Text: string,
	Color: Color3,
}

export type ChatGroupTag = {
	GroupId: number,
	Roles: { [number]: string },
}

export type ChatTagsConfig = {
	TAGS: Dictionary<ChatTagDefinition>,
	USER_TAGS: { [number]: string },
	GAMEPASS_TAGS: { [number]: string },
	GROUP_TAGS: List<ChatGroupTag>,
}

export type DifficultyInfo = {
	read title: string,
	read rating: number,
	read fancyFont: boolean,
	read color: Color3,
	read globalAnnouncement: boolean,
	read globalAjAnnouncement: boolean?,
	read difficultyImage: string?,
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
