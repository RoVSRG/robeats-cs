local Val = require(game.ReplicatedStorage.Libraries.Val)

local Game = {}

Game.results = Val.scope {
    open = Val.new(false),
    score = Val.new(nil)
}

Game.currentGame = Val.new(nil) -- Current active game instance

return Game