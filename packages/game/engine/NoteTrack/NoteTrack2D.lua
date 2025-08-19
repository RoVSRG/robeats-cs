local TriggerButton2D = require(game.ReplicatedStorage.RobeatsGameCore.NoteTrack.TriggerButton2D)
local GameTrack = require(game.ReplicatedStorage.RobeatsGameCore.Enums.GameTrack)
local AssertType = require(game.ReplicatedStorage.Shared.AssertType)

local NoteTrack = {}

function NoteTrack:new(_game, _parent_track_system, _game_track)
	AssertType:is_enum_member(_game_track, GameTrack)
	local self = {}

	local _trigger_button
	local _start_position = nil -- No positions needed in 2D mode
	local _end_position = nil

	function self:cons()
		_trigger_button = TriggerButton2D:new(_game, self, _game_track)
	end

	function self:get_track_obj()
		return nil
	end -- No track object in 2D mode
	function self:get_start_position()
		return _start_position
	end
	function self:get_end_position()
		return _end_position
	end

	function self:press()
		_trigger_button:press()
	end
	function self:release()
		_trigger_button:release()
	end

	function self:update(dt_scale)
		if not _game._config.HideReceptorGlow then
			_trigger_button:update(dt_scale)
		end
	end

	function self:teardown()
		_trigger_button:teardown()
	end

	self:cons()
	return self
end

return NoteTrack
