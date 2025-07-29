local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteBase = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.NoteBase)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local HitParams = require(game.ReplicatedStorage.RobeatsGameCore.HitParams)
local HoldingNoteEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.HoldingNoteEffect)
local TriggerNoteEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.TriggerNoteEffect)
local RenderableHit = require(game.ReplicatedStorage.RobeatsGameCore.RenderableHit)


local SingleNote = {}
SingleNote.Type = "SingleNote"

SingleNote.State = {
	Pre = 0;
	DoRemove = 1;
}

local _outline_top_position_offset_default
local _outline_bottom_position_offset_default
local _body_adorn_default
local _outline_bottom_adorn_default
local _outline_top_adorn_default

function SingleNote:new(_game, _track_index, _slot_index, _creation_time_ms, _hit_time_ms)
	local self = NoteBase:NoteBase()
	self.ClassName = SingleNote.Type
	
	local _state = SingleNote.State.Pre
	
	--Parametric T: Goes from 0 to 1
	local _t = 0
	
	local _note_obj
	local _body, _outline_top, _outline_bottom
	local _position = Vector3.new()
	local _body_adorn, _outline_top_adorn, _outline_bottom_adorn
	local _show_trigger_fx = _game:get_hit_lighting()
	
	function self:cons()
		_note_obj = _game._object_pool:depool(self.ClassName)
		if _note_obj == nil then
			_note_obj = EnvironmentSetup:get_element_protos_folder().SingleNoteAdornProto:Clone()
			
			--Copy the default values
			if _outline_top_position_offset_default == nil then
				_outline_top_position_offset_default = _note_obj.OutlineTop.Position - _note_obj.PrimaryPart.Position
				_outline_bottom_position_offset_default = _note_obj.OutlineBottom.Position - _note_obj.PrimaryPart.Position
				_body_adorn_default = _note_obj.Body.Adorn:Clone()
				_outline_bottom_adorn_default = _note_obj.OutlineBottom.Adorn:Clone()
				_outline_top_adorn_default = _note_obj.OutlineTop.Adorn:Clone()
			end
			
			--We are animating the Adorn CFrames, so set the parent parts to position (0,0,0)
			_note_obj.Body.CFrame = (CFrame.new(Vector3.new()) * SPUtil:part_cframe_rotation(_note_obj.Body))
			_note_obj.OutlineTop.CFrame = (CFrame.new(Vector3.new()) * SPUtil:part_cframe_rotation(_note_obj.OutlineTop))
			_note_obj.OutlineBottom.CFrame = (CFrame.new(Vector3.new()) * SPUtil:part_cframe_rotation(_note_obj.OutlineBottom))
		end
		_note_obj.Parent = EnvironmentSetup:get_local_elements_folder()

		_body = _note_obj.Body
		_outline_top = _note_obj.OutlineTop
		_outline_bottom = _note_obj.OutlineBottom
		_body_adorn = _body.Adorn
		_outline_top_adorn = _outline_top.Adorn
		_outline_bottom_adorn = _outline_bottom.Adorn

		_body.Adorn.Color3 = _game:get_note_color()
		
		self:update_visual(1)
	end
	
	function self:update_visual(dt_scale)
		local parent_track = _game:get_tracksystem(_slot_index):get_track(_track_index)
		_position = SPUtil:vec3_lerp(
			parent_track:get_start_position(),
			parent_track:get_end_position(),
			_t
		)
		--Magic number! Set Y position of single note to look good lined up against held note beginning/ends
		_position = Vector3.new(
			_position.X,
			0.25 + _game:get_game_environment_center_position().Y,
			_position.Z
		)
		
		--Note scales in size from spawn (t=0, scale is 0.25) to deletion (t=1, scale is 0.925)
		local size = CurveUtil:YForPointOf2PtLine(
			Vector2.new(0,0.25),
			Vector2.new(1,0.925),
			SPUtil:clamp(_t,0,1)
		)
		
		--Animate Body.Adorn, OutlineBottom.Adorn and OutlineTop.Adorn
		_body_adorn.CFrame = CFrame.new(_body.CFrame:vectorToObjectSpace(_position))
		_body_adorn.Height = size * _body_adorn_default.Height
		_body_adorn.Radius = size * _body_adorn_default.Radius

		_outline_bottom_adorn.CFrame = CFrame.new(_body.CFrame:vectorToObjectSpace(
			_position + (_outline_bottom_position_offset_default * size)
		))
		_outline_bottom_adorn.Height = size * _outline_bottom_adorn_default.Height
		_outline_bottom_adorn.Radius = size * _outline_bottom_adorn_default.Radius

		_outline_top_adorn.CFrame = CFrame.new(_body.CFrame:vectorToObjectSpace(
			_position + (_outline_top_position_offset_default * size)
		))
		_outline_top_adorn.Height = size * _outline_top_adorn_default.Height
		_outline_top_adorn.Radius = size * _outline_top_adorn_default.Radius
	end
	
	--[[Override--]] function self:update(dt_scale)
		if _state == SingleNote.State.Pre then
			--_t = (_game._audio_manager:get_current_time_ms() - _creation_time_ms) / (_hit_time_ms - _creation_time_ms)
			_t = math.clamp(1 - (_hit_time_ms - _game._audio_manager:get_current_time_ms()) / _game._audio_manager:get_note_prebuffer_time_ms(), 0, 9999)

			self:update_visual(dt_scale)
			
			if self:should_remove(_game) then
				_game._score_manager:register_hit(
					NoteResult.Miss,
					_slot_index,
					_track_index,
					HitParams:new():set_play_sfx(false):set_play_hold_effect(false):set_time_miss(true)
				)
			end
		end
	end

	--[[Override--]] function self:should_remove()
		--Remove if state is DoRemove (set on hit), or if NOTE_REMOVE_TIME past the hit time
		return _state == SingleNote.State.DoRemove or self:get_time_to_end() < _game._audio_manager:get_note_remove_time()
	end
	
	function self:get_time_to_end()
		return (_hit_time_ms - _creation_time_ms) * (1 - _t)
	end

	--[[Override--]] function self:do_remove()
		_game._object_pool:repool(self.ClassName,_note_obj)
	end

	--[[Override--]] function self:test_hit()
		local time_to_end = self:get_time_to_end()
		local did_hit, note_result = NoteResult:timedelta_to_result(time_to_end, _game)

		if did_hit then
			return did_hit, note_result, RenderableHit:new(_hit_time_ms, time_to_end, note_result)
		end

		return false, NoteResult.Miss
	end

	--[[Override--]] function self:on_hit(note_result, i_notes, renderable_hit)

		if _show_trigger_fx then
			_game._effects:add_effect(TriggerNoteEffect:new(
					_game,
					_position,
					note_result
				))
		end

		_game._score_manager:register_hit(
			note_result,
			_slot_index,
			_track_index,
			HitParams:new():set_play_hold_effect(true, _position),
			renderable_hit
		)

		_state = SingleNote.State.DoRemove
	end

	--[[Override--]] function self:test_release()
		return false, NoteResult.Miss
	end
	
	--[[Override--]] function self:on_release(note_result,i_notes)
	end
	
	--[[Override--]] function self:get_track_index()
		return _track_index
	end

	self:cons()
	return self
end

return SingleNote

