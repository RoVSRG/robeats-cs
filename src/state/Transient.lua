local Val = require(game.ReplicatedStorage.Libraries.Val)

local SongDatabase = require(game.ReplicatedStorage.SongDatabase)

local Transient = {}

----------------------------------------------------------------
-- SONG SELECTION STATE
----------------------------------------------------------------

Transient.song = Val.scope {
	selected = Val.new(nil),
	rate = Val.new(100),
	loading = Val.new(false),
	playing = Val.new(false),
	lastResult = Val.new(nil),
}

Transient.song.hash = Val.calc(function(get)
	local song = get(Transient.song.selected)

	if song then
		return SongDatabase:GetPropertyByKey(song, "MD5Hash")
	end

	return nil
end)

----------------------------------------------------------------

Transient.profile = Val.scope {
	playerUsername = Val.new(""),
	playerAvatarUrl = Val.new(""),
	playerTier = Val.new(""),
	playerRank = Val.new(""),
	playerRating = Val.new(0),
	xpProgress = Val.new(0.0)
}

return Transient
