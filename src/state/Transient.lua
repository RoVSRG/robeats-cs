local Val = require(game.ReplicatedStorage.Libraries.Val)

local Transient = {}

----------------------------------------------------------------
-- SONG SELECTION STATE
----------------------------------------------------------------

Transient.song = Val.scope {
	selected = Val.new(nil),
	rate = Val.new(100),
	loading = Val.new(false),
	playing = Val.new(false),
	lastResult = Val.new(nil)
}

Transient.profile = Val.scope {
	playerUsername = Val.new(""),
	playerAvatarUrl = Val.new(""),
	playerTier = Val.new(""),
	playerRank = Val.new(""),
	playerRating = Val.new(0),
	xpProgress = Val.new(0.0)
}

return Transient
