--[=[
	Defines common types used across the MTK codebase.
	All game-wide type definitions should live here.

	@class Types
]=]

--[=[
	@type List<T> { [number]: T }
	@within Types
	A sequential array of values.
]=]
export type List<T> = { [number]: T }

--[=[
	@type Dictionary<T> { [string]: T }
	@within Types
	A string-keyed map of values.
]=]
export type Dictionary<T> = { [string]: T }

type Seconds = number

--[=[
	@interface TimeStat
	@within Types
	.seconds number -- Time in seconds
	.formatted string -- Human-readable formatted time string
]=]
export type TimeStat = {
	seconds: Seconds,
	formatted: string,
}

type BasicTowerInfo = {
	name: string,
	difficulty: string,
	badgeId: number,
}

--[=[
	@interface TowerInfo
	@within Types
	.name string -- Display name of the tower
	.difficulty string -- Difficulty tier (e.g., "Easy", "Medium", "Extreme")
	.badgeId number -- Roblox badge ID for normal completion
	.towerPoints number -- Points awarded for completion
	.allJumpsPoints number? -- Points for all-jumps completion
	.ajBadgeId number? -- Badge ID for all-jumps completion
	.noBoosts boolean? -- Whether boosts are disabled
	.folder Instance -- Workspace folder containing the tower
	.spawnLocation BasePart -- Spawn point for the tower
	.clientObjects Instance? -- Client-side visual objects
	.endings Dictionary<EndingInfo> -- Available endings/winpads
	.minimumTime number -- Minimum time required to complete
	.checkpoints List<BasePart> -- Ordered checkpoint parts
	.checkpointCount number -- Total number of checkpoints
]=]
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

--[=[
	@interface EndingInfo
	@within Types
	.name string -- Display name of the ending
	.difficulty string -- Difficulty tier of this ending
	.badgeId number -- Badge ID for this specific ending
	.preventTowerBadge boolean -- If true, don't award the tower's main badge
	.parentTower string -- Acronym of the tower this ending belongs to
	.winroomMarker string -- Marker name for teleport destination
]=]
export type EndingInfo = BasicTowerInfo & {
	preventTowerBadge: boolean,
	parentTower: string,
	winroomMarker: string,
}

--[=[
	@interface TowerRush
	@within Types
	.winroomMarker string -- Marker name for rush completion teleport
	.towers List<string> -- Ordered list of tower acronyms
	.noBoosts boolean -- Whether boosts are disabled for this rush
]=]
export type TowerRush = {
	winroomMarker: string,
	towers: List<string>,
	noBoosts: boolean,
}

--[=[
	@interface TowerStat
	@within Types
	.attempts number -- Total attempts on this tower
	.wins number -- Total normal completions
	.allJumpsWins number -- Total all-jumps completions
	.totalTimeSpent TimeStat -- Cumulative time spent
	.bestWinTime TimeStat -- Best normal completion time
	.bestAjWinTime TimeStat -- Best all-jumps completion time
]=]
export type TowerStat = {
	attempts: number,
	wins: number,
	allJumpsWins: number,
	totalTimeSpent: TimeStat,
	bestWinTime: TimeStat,
	bestAjWinTime: TimeStat,
}

--[=[
	@type PlayerMode "Normal" | "AllJumps" | "Practice"
	@within Types
	The current game mode for a player.
]=]
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

--[=[
	@interface PlayerInfo
	@within Types
	.player Player -- The Roblox Player instance
	.gameTimer number -- Total time in server
	.lastRestart number -- Timestamp of last restart
	.currentTower string -- Current tower acronym (empty if none)
	.currentCheckpoint number -- Current checkpoint index
	.towerTimer number -- Time spent in current tower attempt
	.mode PlayerMode -- Current game mode
	.currentTowerRush string -- Current rush name (empty if none)
	.currentTowerRushIndex number -- Current tower index in rush
	.currentTowerRushSplitTime number -- Time at last tower split
	.touchEventBusy boolean -- Prevents double-touch processing
	.isLoadingTower boolean -- Tower load in progress
	.hasEverpresentCOs boolean -- Has received everpresent client objects
	.debugItemUsed boolean -- Used a debug item this attempt
	.boostItemUsed boolean -- Used a boost item this attempt
	.boostItemNames Dictionary<string> -- Names of boosts used
]=]
export type PlayerInfo = PlayerRunTime & PlayerTowerState & PlayerRushState & PlayerFlags

export type Settings = {
	quickResetDelay: number,
	resetOnDeath: boolean,
	highFPSPhysicsFix: boolean,
	utility: "Off" | "Emote" | "Alignment",
	towerLoadingBehavior: "Load All" | "Unload Towers" | "Unload All",
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
	-- Ticket system
	tickets: number,
	ticketCooldowns: Dictionary<number>, -- tower acronym -> timestamp when cooldown expires
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
