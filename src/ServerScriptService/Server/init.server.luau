local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Loader = require(Packages.Loader)
Loader.SpawnAll(Loader.LoadDescendants(script.Parent), "Init")
