local Val = require(game.ReplicatedStorage.Libraries.Val)

local SongDatabase = require(game.ReplicatedStorage.SongDatabase)

local Transient = {}
Transient.initialized = false

----------------------------------------------------------------
-- SONG SELECTION STATE
----------------------------------------------------------------

Transient.song = {
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

Transient.page = Val.new(1)

----------------------------------------------------------------

Transient.profileAttributes = {
	name = Val.new("Player"),
	avatar = Val.new(""),
	tier = Val.new("NIL"),
	rank = Val.new("#???"),
	rating = Val.new(0),
	xpProgress = Val.new(0.0),
	accuracy = Val.new(0.0),
	playCount = Val.new(0),
}

Transient.profile = Val.calc(function(get)
	local profile = {}

	for k, v in Transient.profileAttributes do
		profile[k] = get(v)
	end

	return profile
end)

function Transient.updateProfile(
	player: Player,
	avatar: string,
	tier: string,
	rank: string,
	rating: number,
	accuracy: number,
	playCount: number
)
	local profile = Transient.profileAttributes

	Val.batch(function(set)
		set(profile.name, player.DisplayName or player.Name)
		set(profile.avatar, avatar)
		set(profile.tier, tier)
		set(profile.rank, rank)
		set(profile.rating, rating)
		set(profile.accuracy, accuracy)
		set(profile.playCount, playCount)
	end)

	Transient.initialized = true
end

function Transient.updateProfilePartial(updates: {
	rank: string?,
	rating: number?,
	accuracy: number?,
	playCount: number?,
})
	Val.batch(function(set)
		if updates.rank then
			set(Transient.profileAttributes.rank, updates.rank)
		end
		if updates.rating then
			set(Transient.profileAttributes.rating, updates.rating)
		end
		if updates.accuracy then
			set(Transient.profileAttributes.accuracy, updates.accuracy)
		end
		if updates.playCount then
			set(Transient.profileAttributes.playCount, updates.playCount)
		end
	end)
end

return Transient
