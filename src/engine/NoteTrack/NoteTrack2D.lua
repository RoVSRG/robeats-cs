local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local TriggerButton2D = require(game.ReplicatedStorage.RobeatsGameCore.NoteTrack.TriggerButton2D)
local GameSlot = require(game.ReplicatedStorage.RobeatsGameCore.Enums.GameSlot)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local GameTrack = require(game.ReplicatedStorage.RobeatsGameCore.Enums.GameTrack)
local AssertType = require(game.ReplicatedStorage.Shared.AssertType)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)

local NoteTrack = {}

function NoteTrack:new(_game, _parent_track_system, _game_track)
	AssertType:is_enum_member(_game_track, GameTrack)
	local self = {}
	
	local _trigger_button
	local _start_position
	local _end_position
	
	function self:cons(player_info)
		_trigger_button = TriggerButton2D:new(
			_game,
			self,
			_game_track
		)
	end
	
	function self:get_track_obj() return _track_obj end
	function self:get_start_position() return _start_position end
	function self:get_end_position() return _end_position end
	
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
