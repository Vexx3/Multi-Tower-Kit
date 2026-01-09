local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerGame = ReplicatedStorage.TowerGame
local Shared = TowerGame.Shared

local Types = require(Shared.Types)

type Dictionary<T> = Types.Dictionary<T>
type PlayerInfo = Types.PlayerInfo
type TowerInfo = Types.TowerInfo

local DataInfo = {}

DataInfo.PlayerInfo = {} :: Dictionary<PlayerInfo>
DataInfo.TowerInfo = {} :: Dictionary<TowerInfo>

return DataInfo
