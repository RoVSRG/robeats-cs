local Val = require(game.ReplicatedStorage.Libraries.Val)

local SongDatabase = require(game.ReplicatedStorage.SongDatabase)

local Transient = {}

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

----------------------------------------------------------------

local _profileScope = {
	name = Val.new(""),
	avatar = Val.new(""),
	tier = Val.new(""),
	rank = Val.new(""),
	rating = Val.new(0),
	xpProgress = Val.new(0.0),
	accuracy = Val.new(0.0),
	playCount = Val.new(0),
}

Transient.profile = Val.calc(function(get)
	local profile = {}

	for k, v in _profileScope do
		profile[k] = get(v)
	end

	return profile
end)

Transient.previousProfile = Val.new(nil)

Transient.profile:on(function(profile, previousProfile)
	print("Profile updated:", previousProfile.playCount, "->", profile.playCount)

	Transient.previousProfile:set(previousProfile)
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
	local profile = _profileScope

	Val.batch(function(set)
		set(profile.name, player.DisplayName or player.Name)
		set(profile.avatar, avatar)
		set(profile.tier, tier)
		set(profile.rank, rank)
		set(profile.rating, rating)
		set(profile.accuracy, accuracy)
		set(profile.playCount, playCount)
	end)
end

function Transient.updateProfilePartial(updates: {
	rank: string?,
	rating: number?,
	accuracy: number?,
	playCount: number?,
})
	Val.batch(function(set)
		if updates.rank then
			set(_profileScope.rank, updates.rank)
		end
		if updates.rating then
			set(_profileScope.rating, updates.rating)
		end
		if updates.accuracy then
			set(_profileScope.accuracy, updates.accuracy)
		end
		if updates.playCount then
			set(_profileScope.playCount, updates.playCount)
		end
	end)
end

return Transient
