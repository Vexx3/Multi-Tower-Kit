local Loader = require("@self/Loader")

Loader.SpawnAll(
	Loader.LoadDescendants(script.Parent),
	"Init"
)
