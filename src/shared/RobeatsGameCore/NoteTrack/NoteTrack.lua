local SPUtil = require("@shared/Shared/SPUtil")
local CurveUtil = require("@shared/Shared/CurveUtil")
local TriggerButton = require("@shared/RobeatsGameCore/NoteTrack/TriggerButton")
local GameSlot = require("@shared/RobeatsGameCore/Enums/GameSlot")
local EnvironmentSetup = require("@shared/RobeatsGameCore/EnvironmentSetup")
local GameTrack = require("@shared/RobeatsGameCore/Enums/GameTrack")
local AssertType = require("@shared/Shared/AssertType")
local DebugOut = require("@shared/Shared/DebugOut")

local NoteTrack = {}

function NoteTrack:new(_game, _parent_track_system, _track_obj, _game_track, _config)
	AssertType:is_enum_member(_game_track, GameTrack)
	local self = {}
	
	local _trigger_button
	local _start_position
	local _end_position
	
	function self:cons(player_info)
		local start_position_marker = _track_obj:FindFirstChild("StartPosition")
		if start_position_marker == nil then
			return DebugOut:errf("StartPosition marker not found under _track_obj(%s)", _track_obj.Name)
		end
		_start_position = start_position_marker.Position
		
		local end_position_marker = _track_obj:FindFirstChild("EndPosition")
		if end_position_marker == nil then
			return DebugOut:errf("EndPosition marker not found under _track_obj(%s)", _track_obj.Name)
		end
		_end_position = end_position_marker.Position

		_trigger_button = TriggerButton:new(
			_game,
			self,
			self:get_end_position()
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
		_track_obj:Destroy()
	end
	
	self:cons()
	return self
end

return NoteTrack
