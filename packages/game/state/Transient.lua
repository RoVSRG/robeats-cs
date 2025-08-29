local Val = require(game.ReplicatedStorage.Libraries.Val)

local SongDatabase = require(game.ReplicatedStorage.SongDatabase)

local Transient = {}

----------------------------------------------------------------
-- SONG SELECTION STATE
----------------------------------------------------------------

Transient.song = Val.scope({
	selected = Val.new(nil),
	rate = Val.new(100),
	loading = Val.new(false),
	playing = Val.new(false),
	lastResult = Val.new(nil),
})

Transient.song.hash = Val.calc(function(get)
	local song = get(Transient.song.selected)

	if song then
		return SongDatabase:GetPropertyByKey(song, "MD5Hash")
	end

	return nil
end)

----------------------------------------------------------------

Transient.profile = Val.scope({
	name = Val.new(""),
	avatar = Val.new(""),
	tier = Val.new(""),
	rank = Val.new(""),
	rating = Val.new(0),
	xpProgress = Val.new(0.0),
	accuracy = Val.new(0.0),
	playCount = Val.new(0),
})

return Transient
