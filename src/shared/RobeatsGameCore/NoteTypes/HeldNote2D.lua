local AssertType = require(game.ReplicatedStorage.Shared.AssertType)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteBase = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.NoteBase)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local HitParams = require(game.ReplicatedStorage.RobeatsGameCore.HitParams)
local HoldingNoteEffect2D = require(game.ReplicatedStorage.RobeatsGameCore.Effects.HoldingNoteEffect2D)
local FlashEvery = require(game.ReplicatedStorage.Shared.FlashEvery)
local RenderableHit = require(game.ReplicatedStorage.RobeatsGameCore.RenderableHit)
local TriggerNoteEffect2D = require(game.ReplicatedStorage.RobeatsGameCore.Effects.TriggerNoteEffect2D)
local Skins = require(game.ReplicatedStorage.Skins)


local HeldNote2D = {}
HeldNote2D.Type = "HeldNote2D"

HeldNote2D.State = {
	Pre = 0; --HeldNote2D first hit arriving
	Holding = 1; --HeldNote2D first hit success, currently holding
	HoldMissedActive = 2; --HeldNote2D first hit failed, second hit arriving
	Passed = 3; --HeldNote2D second hit passed
	DoRemove = 4;
}

function HeldNote2D:new(
	_game,
	_track_index,
	_slot_index,
	_creation_time_ms,
	_hit_time_ms,
	_duration_time_ms
)
	local self = NoteBase:NoteBase()
	self.ClassName = HeldNote2D.Type
	
	local _game_audio_manager_get_current_time_ms = 0
	local _note_obj
	
	local _body
	local _head
	local _tail
	
	local _state = HeldNote2D.State.Pre
	local _did_trigger_head = false
	local _did_trigger_tail = false
	local _show_trigger_fx = _game:get_hit_lighting()
	
	function self:cons()
		local _gameplay_frame = EnvironmentSetup:get_player_gui_root().GameplayFrame
		local tracks = _gameplay_frame.Tracks

		local _skin = _game:get_skin()
		local proto = _skin.HeldNoteProto

		_note_obj = _game._object_pool:depool(self.ClassName)
		if _note_obj == nil then
			_note_obj = proto:Clone()
			_note_obj.Body.Position = UDim2.new(0.5,0,-1,0)
			_note_obj.Body.ZIndex = 2
			_note_obj.Head.Position = UDim2.new(0.5,0,-1,0)
			_note_obj.Head.ZIndex = 3
			_note_obj.Tail.Position = UDim2.new(0.5,0,-1,0)
			_note_obj.Head.ZIndex = 3
		end

		_body = _note_obj.Body
		_head = _note_obj.Head
		_tail = _note_obj.Tail

		if _game:get_note_color_affects_2d() then
			local _note_color = _game:get_note_color()

			_body.BackgroundColor3 = _note_color

			local _head_image = _head:FindFirstChildWhichIsA("ImageLabel")
			local _tail_image = _tail:FindFirstChildWhichIsA("ImageLabel")

			if _head_image then
				_head_image.ImageColor3 = _note_color
			end

			if _tail_image then
				_tail_image.ImageColor3 = _note_color
			end
		end

		_state = HeldNote2D.State.Pre
		self:update_visual(1)
		_note_obj.Parent = tracks['Track'.._track_index]
	end	
	
	local function get_head_position()
		return 1 - (_hit_time_ms - _game._audio_manager:get_current_time_ms()) / _game._audio_manager:get_note_prebuffer_time_ms()
	end
	
	local function get_tail_hit_time()
		return _hit_time_ms + _duration_time_ms
	end
	
	local function tail_visible()
		return not (get_tail_hit_time() > _game._audio_manager:get_current_time_ms() + _game._audio_manager:get_note_prebuffer_time_ms())
	end
	
	local function get_tail_t()
		return 1 - (get_tail_hit_time() - _game._audio_manager:get_current_time_ms()) / _game._audio_manager:get_note_prebuffer_time_ms()
	end
	
	local function get_tail_position()
		if not tail_visible() then
			return 0
		else
			return get_tail_t()
		end
	end
	
	-- NOTE: This update_visual code is based on rosu!mania
	function self:update_visual(dt_scale)
		local head_pos = get_head_position()
		local tail_pos = get_tail_position()
		
		if _did_trigger_head then
			if _game._audio_manager:get_current_time_ms() > _hit_time_ms then
				if _state ~= HeldNote2D.State.HoldMissedActive then
					head_pos = 1

					if tail_pos > 1 then
						if _state ~= HeldNote2D.State.Passed then
							tail_pos = 1
						end
					end
				end
			end
		end
		
		_head.Position = UDim2.new(0.5, 0, head_pos, 0)
		_tail.Position = UDim2.new(0.5, 0, tail_pos, 0)

		local tail_to_head = (head_pos - tail_pos)
		
		if _state == HeldNote2D.State.Pre then
			_head.Visible = true
		end
		
		if _game:get_ln_tails() == false then
			if _state == HeldNote2D.State.Passed and _did_trigger_tail then
				_tail.Visible = false
				_head.Visible = false
			else
				_tail.Visible = tail_visible()
			end
		else
			_tail.Visible = false
		end

		do
			local _body_pos = (tail_to_head * 0.5) + tail_pos
			_body.Position = UDim2.new(0.5, 0, _body_pos, 0)
			_body.Size = UDim2.new(_body.Size.X.Scale, 0, tail_to_head, 0)
		end
		
		local target_transparency = 0
		local imm = false

		if _state == HeldNote2D.State.HoldMissedActive then
			target_transparency = 0.9
			if _did_trigger_head then
				_head.Visible = false
			end

		elseif _state == HeldNote2D.State.Passed and _did_trigger_tail then
			target_transparency = 1
			imm = true
		else
			target_transparency = 0
		end
		
		if imm then
			_body.BackgroundTransparency = target_transparency
			if _tail:FindFirstChild("ImageLabel") ~= nil then
				_tail.ImageLabel.ImageTransparency = target_transparency
			else
				_tail.BackgroundTransparency = target_transparency
			end
		else
			_body.BackgroundTransparency = CurveUtil:Expt(
				_body.BackgroundTransparency,
				target_transparency,
				CurveUtil:NormalizedDefaultExptValueInSeconds(0.15),
				dt_scale
			)
			
			if _tail:FindFirstChild("ImageLabel") ~= nil then
				_tail.ImageLabel.ImageTransparency = CurveUtil:Expt(
					_tail.ImageLabel.ImageTransparency,
					target_transparency,
					CurveUtil:NormalizedDefaultExptValueInSeconds(0.15),
					dt_scale
				)
			else
				_tail.BackgroundTransparency = CurveUtil:Expt(
					_tail.BackgroundTransparency,
					target_transparency,
					CurveUtil:NormalizedDefaultExptValueInSeconds(0.15),
					dt_scale
				)
			end
		end
	end

	local _hold_flash = FlashEvery:new(0.15)
	_hold_flash:flash_now()

	--[[Override--]] function self:update(dt_scale)
		_game_audio_manager_get_current_time_ms = _game._audio_manager:get_current_time_ms()
		
		self:update_visual(dt_scale)

		if _has_notified_held_note_begin == false then
			if _hit_time_ms < _game_audio_manager_get_current_time_ms then
				--_game._audio_manager:notify_held_note_begin(_hit_time_ms)
				_has_notified_held_note_begin = true
			end
		end
		
		--if _state == HeldNote2D.State.Holding then
		--	_game._world_effect_manager:notify_frame_hold(_game, _slot_index, _track_index)
		--end
		
		if _state == HeldNote2D.State.Pre then
			if _game_audio_manager_get_current_time_ms > (_hit_time_ms - _game._audio_manager:get_note_remove_time()) then
				_game._score_manager:register_hit(
					NoteResult.Miss,
					_slot_index,
					_track_index,
					HitParams:new():set_play_sfx(false):set_play_hold_effect(false):set_time_miss(true)
				)
				
				_state = HeldNote2D.State.HoldMissedActive
			end
		elseif _state == HeldNote2D.State.Holding or _state == HeldNote2D.State.HoldMissedActive or _state == HeldNote2D.State.Passed then
			if _state == HeldNote2D.State.Holding then
				_hold_flash:update(dt_scale)
				if _hold_flash:do_flash() then
					_game._effects:add_effect(HoldingNoteEffect2D:new(_game, _track_index))
				end
			end
			
			if _game_audio_manager_get_current_time_ms > (get_tail_hit_time() - _game._audio_manager:get_note_remove_time()) then
				if _state == HeldNote2D.State.Holding or _state == HeldNote2D.State.HoldMissedActive then
					_game._score_manager:register_hit(
						NoteResult.Miss,
						_slot_index,
						_track_index,
						HitParams:new():set_play_sfx(false):set_play_hold_effect(false):set_time_miss(true)
					)
				end
				
				_state = HeldNote2D.State.DoRemove
			end
		end
	end

	--[[Override--]] function self:should_remove()
		return _state == HeldNote2D.State.DoRemove
	end

	--[[Override--]] function self:do_remove()
		_game._object_pool:repool(self.ClassName,_note_obj)
	end

	--[[Override--]] function self:test_hit()
		if _state == HeldNote2D.State.Pre then
			local time_to_end = _game._audio_manager:get_current_time_ms() - _hit_time_ms
			local did_hit, note_result = NoteResult:timedelta_to_result(time_to_end, _game)

			if did_hit then
				return did_hit, note_result, RenderableHit:new(_hit_time_ms, time_to_end, note_result)
			end

			return false, NoteResult.Miss

		elseif _state == HeldNote2D.State.HoldMissedActive then
			local time_to_end = _game._audio_manager:get_current_time_ms() - get_tail_hit_time()
			local did_hit, note_result = NoteResult:timedelta_to_result(time_to_end, _game)

			if did_hit then
				return did_hit, note_result, RenderableHit:new(get_tail_hit_time(), time_to_end, note_result)
			end

			return false, NoteResult.Miss

		end

		return false, NoteResult.Miss
	end

	--[[Override--]] function self:on_hit(note_result, i_notes, renderable_hit)
		if _state == HeldNote2D.State.Pre then
			if _show_trigger_fx then
				_game._effects:add_effect(TriggerNoteEffect2D:new(
					_game,
					_track_index
				))
			end
			
			
			--Hit the first note
			_game._score_manager:register_hit(
				note_result, 
				_slot_index, 
				_track_index, 
				HitParams:new():set_play_hold_effect(false):set_held_note_begin(true)
			)

			_did_trigger_head = true
			_state = HeldNote2D.State.Holding

		elseif _state == HeldNote2D.State.HoldMissedActive then
			if _show_trigger_fx then
				_game._effects:add_effect(TriggerNoteEffect2D:new(
					_game,
					_track_index
				))
			end

			if _show_trigger_fx then
				_game._effects:add_effect(TriggerNoteEffect2D:new(
					_game,
					_track_index
				))

			end
			
			--Missed the first note, hit the second note
			_game._score_manager:register_hit(
				note_result,
				_slot_index,
				_track_index,
				HitParams:new():set_play_hold_effect(true, get_tail_position()),
				renderable_hit
			)

			_did_trigger_tail = true
			_state = HeldNote2D.State.Passed
		end
	end

	--[[Override--]] function self:test_release()
		if _state == HeldNote2D.State.Holding or _state == HeldNote2D.State.HoldMissedActive then
			local time_to_end = _game._audio_manager:get_current_time_ms() - get_tail_hit_time()
			local did_hit, note_result = NoteResult:release_timedelta_to_result(time_to_end, _game)

			if did_hit then
				return did_hit, note_result, RenderableHit:new(get_tail_hit_time(), time_to_end, note_result)
			end

			if _state == HeldNote2D.State.HoldMissedActive then
				return false, NoteResult.Miss
			else
				return true, NoteResult.Miss
			end
		end

		return false, NoteResult.Miss
	end
	--[[Override--]] function self:on_release(note_result, i_notes, renderable_hit)
		if _state == HeldNote2D.State.Holding or _state == HeldNote2D.State.HoldMissedActive then
			if note_result == NoteResult.Miss then
				--Holding or missed first hit, missed second hit
				_game._score_manager:register_hit(
					note_result, 
					_slot_index, 
					_track_index,	
					HitParams:new():set_play_hold_effect(false),
					renderable_hit
				)
				_state = HeldNote2D.State.HoldMissedActive
			else

				if _show_trigger_fx then
					_game._effects:add_effect(TriggerNoteEffect2D:new(
						_game,
						_track_index
					))

				end
				--Holding or missed first hit, hit second hit
				_game._score_manager:register_hit(
					note_result,
					_slot_index,
					_track_index,
					HitParams:new():set_play_hold_effect(true, get_tail_position()),
					renderable_hit
				)
				_did_trigger_tail = true
				_state = HeldNote2D.State.Passed
			end
		end

	end

	--[[Override--]] function self:get_track_index()
		return _track_index
	end


	self:cons()
	return self
end

return HeldNote2D