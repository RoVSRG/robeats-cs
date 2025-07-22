local InputUtil = require(game.ReplicatedStorage.Shared.InputUtil)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)

local GameTrack = {
	Track1 = 1;
	Track2 = 2;
	Track3 = 3;
	Track4 = 4;
}

local _track_dict = SPDict:new():add_table(GameTrack)
function GameTrack:get_track_count()
	return _track_dict:count()
end
function GameTrack:track_itr()
	return _track_dict:key_itr()
end

local _key_to_track_index = SPDict:new():add_table({
	[InputUtil.KEY_TRACK1] = GameTrack.Track1;
	[InputUtil.KEY_TRACK2] = GameTrack.Track2;
	[InputUtil.KEY_TRACK3] = GameTrack.Track3;
	[InputUtil.KEY_TRACK4] = GameTrack.Track4;
})
function GameTrack:inpututil_key_to_track_index()
	return _key_to_track_index
end

return GameTrack