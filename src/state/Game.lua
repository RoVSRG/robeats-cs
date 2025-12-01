local Val = require(game.ReplicatedStorage.Libraries.Val)
local GameStats = require(game.ReplicatedStorage.State.GameStats)

local Game = {}

-- Re-export GameStats for convenience
Game.stats = GameStats

-- Current game results (set after gameplay finishes)
Game.results = nil :: {
	score: number,
	accuracy: number,
	rating: number,
	combo: number,
	maxCombo: number,
	marvelous: number,
	perfect: number,
	great: number,
	good: number,
	bad: number,
	miss: number,
	totalNotes: number,
	notesHit: number,
	grade: string,
	songKey: string | number,
	rate: number,
}?

Game.currentGame = Val.new(nil) -- Current active game instance

return Game
