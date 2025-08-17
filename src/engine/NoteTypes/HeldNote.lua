local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteBase = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.NoteBase)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local HitParams = require(game.ReplicatedStorage.RobeatsGameCore.HitParams)
local HoldingNoteEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.HoldingNoteEffect)
local FlashEvery = require(game.ReplicatedStorage.Shared.FlashEvery)
local RenderableHit = require(game.ReplicatedStorage.RobeatsGameCore.RenderableHit)
local TriggerNoteEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.TriggerNoteEffect)

local HeldNote = {}
HeldNote.Type = "HeldNote"

HeldNote.State = {
	Pre = 0, --HeldNote first hit arriving
	Holding = 1, --HeldNote first hit success, currently holding
	HoldMissedActive = 2, --HeldNote first hit failed, second hit arriving
	Passed = 3, --HeldNote second hit passed
	DoRemove = 4,
}

local _head_outline_position_offset_default
local _tail_outline_position_offset_default
local _head_adorn_default
local _head_outline_adorn_default
local _tail_adorn_default
local _tail_outline_adorn_default
local _body_adorn_default
local _body_outline_left_adorn_default
local _body_outline_right_adorn_default

function HeldNote:new(_game, _track_index, _slot_index, _creation_time_ms, _hit_time_ms, _duration_time_ms)
	local self = NoteBase:NoteBase()
	self.ClassName = HeldNote.Type

	local _note_obj

	local _body
	local _head
	local _tail
	local _body_adorn, _head_adorn, _tail_adorn

	local _state = HeldNote.State.Pre
	local _did_trigger_head = false
	local _did_trigger_tail = false
	local _show_trigger_fx = _game:get_hit_lighting()

	function self:cons()
		_note_obj = _game._object_pool:depool(self.ClassName)
		if _note_obj == nil then
			_note_obj = EnvironmentSetup:get_element_protos_folder().HeldNoteAdornProto:Clone()

			if _head_adorn_default == nil or _tail_adorn_default == nil or _body_adorn_default == nil then
				_head_adorn_default = _note_obj.Head.Head.Adorn:Clone()
				_tail_adorn_default = _note_obj.Tail.Tail.Adorn:Clone()
				_body_adorn_default = _note_obj.Body.Body.Adorn:Clone()
			end

			--We are animating the Adorn CFrames, so set the parent parts to position (0,0,0) but keep the rotation
			_note_obj.Body:SetPrimaryPartCFrame(
				CFrame.new(Vector3.new()) * SPUtil:part_cframe_rotation(_note_obj.Body.PrimaryPart)
			)
			_note_obj.Head:SetPrimaryPartCFrame(
				CFrame.new(Vector3.new()) * SPUtil:part_cframe_rotation(_note_obj.Head.PrimaryPart)
			)
			_note_obj.Tail:SetPrimaryPartCFrame(
				CFrame.new(Vector3.new()) * SPUtil:part_cframe_rotation(_note_obj.Tail.PrimaryPart)
			)
		end
		_note_obj.Parent = EnvironmentSetup:get_local_elements_folder()

		_body = _note_obj.Body.Body
		_body_adorn = _body.Adorn
		_head = _note_obj.Head.Head
		_head_adorn = _head.Adorn
		_tail = _note_obj.Tail.Tail
		_tail_adorn = _tail.Adorn

		local _note_color = _game:get_note_color()

		_body_adorn.Color3 = _note_color
		_head_adorn.Color3 = _note_color
		_tail_adorn.Color3 = _note_color

		_state = HeldNote.State.Pre
		self:update_visual(1)
	end

	--Cache start and end position since they are used every frame
	local __get_start_position = nil
	local function get_start_position()
		if __get_start_position == nil then
			__get_start_position = _game:get_tracksystem(_slot_index):get_track(_track_index):get_start_position()
		end
		return __get_start_position
	end

	local __get_end_position = nil
	local function get_end_position()
		if __get_end_position == nil then
			__get_end_position = _game:get_tracksystem(_slot_index):get_track(_track_index):get_end_position()
		end
		return __get_end_position
	end

	local function get_head_position()
		return SPUtil:vec3_lerp(
			get_start_position(),
			get_end_position(),
			math.clamp(
				1
					- (_hit_time_ms - _game._audio_manager:get_current_time_ms())
						/ _game._audio_manager:get_note_prebuffer_time_ms(),
				0,
				9999
			) -- YOLO
		)
	end

	local function get_tail_hit_time()
		return _hit_time_ms + _duration_time_ms
	end

	local function get_visual_tail_hit_time()
		local ln_cut_ms = _game:get_ln_cut()
		return _hit_time_ms + _duration_time_ms - ln_cut_ms
	end

	local function tail_visible()
		return not (
			get_visual_tail_hit_time()
			> _game._audio_manager:get_current_time_ms() + _game._audio_manager:get_note_prebuffer_time_ms()
		)
	end

	local function get_tail_t()
		return 1
			- (get_visual_tail_hit_time() - _game._audio_manager:get_current_time_ms())
				/ _game._audio_manager:get_note_prebuffer_time_ms()
	end

	local function get_tail_position()
		if not tail_visible() then
			return get_start_position()
		else
			local tail_t = get_tail_t()
			return SPUtil:vec3_lerp(
				get_start_position(),
				get_end_position(),
				math.clamp(tail_t, 0, 9999) -- SAME YOLO
			)
		end
	end

	function self:update_visual(dt_scale)
		local head_pos = get_head_position()
		local tail_pos = get_tail_position()

		--Magic number to offset Adorn position by (to look good)
		local OVERALL_OFFSET = Vector3.new(0, -0.35, 0)

		_head_adorn.CFrame = CFrame.new(_head.CFrame:vectorToObjectSpace(head_pos)) + OVERALL_OFFSET
		_tail_adorn.CFrame = CFrame.new(_tail.CFrame:vectorToObjectSpace(tail_pos)) + OVERALL_OFFSET

		if _did_trigger_head then
			if _game._audio_manager:get_current_time_ms() > _hit_time_ms then
				head_pos = get_end_position()
			end
		end

		local tail_to_head = head_pos - tail_pos
		local ln_transparency = 0.5

		--Calculate transparency for head and tail
		if _state == HeldNote.State.Pre then
			_head_adorn.Transparency = 0
		else
			_head_adorn.Transparency = 1
		end

		if _game:get_ln_tails() == false then
			if _state == HeldNote.State.Passed and _did_trigger_tail then
				_tail_adorn.Transparency = 1
			else
				if tail_visible() then
					_tail_adorn.Transparency = ln_transparency
				else
					_tail_adorn.Transparency = 1
				end
			end
		else
			_tail_adorn.Transparency = 1
		end

		local head_t = (_game._audio_manager:get_current_time_ms() - _creation_time_ms)
			/ (_hit_time_ms - _creation_time_ms)

		do
			--Set body rotation by setting the rotation of the adorn's parent part
			_note_obj.Body:SetPrimaryPartCFrame(
				CFrame.Angles(0, SPUtil:deg_to_rad(SPUtil:dir_ang_deg(tail_to_head.x, -tail_to_head.z) + 90), 0)
			)

			--Set Adorn position to halfway between head and tail position
			local body_pos = (tail_to_head * 0.5) + tail_pos
			_body_adorn.CFrame = CFrame.new(_body.CFrame:vectorToObjectSpace(body_pos) + OVERALL_OFFSET)

			--Calculate scaling factor magic number (to look good)
			local body_scale_factor =
				CurveUtil:YForPointOf2PtLine(Vector2.new(0, 0.25), Vector2.new(1, 0.65), SPUtil:clamp(head_t, 0, 1))
			local body_radius = _body_adorn_default.Radius * body_scale_factor

			_body_adorn.Height = tail_to_head.magnitude - _head_adorn.Radius
			_body_adorn.Radius = body_radius
		end

		do
			--Scale head and tail scaling factor magic number (to look good)
			local head_scale_factor =
				CurveUtil:YForPointOf2PtLine(Vector2.new(0, 0.383), Vector2.new(1, 0.85), SPUtil:clamp(head_t, 0, 1))
			local tail_scale_factor = CurveUtil:YForPointOf2PtLine(
				Vector2.new(0, 0.383),
				Vector2.new(1, 0.85),
				SPUtil:clamp(get_tail_t(), 0, 1)
			)

			_head_adorn.Radius = _head_adorn_default.Radius * head_scale_factor
			_tail_adorn.Radius = _tail_adorn_default.Radius * tail_scale_factor

			-- _head_outline_adorn.Radius = _head_outline_adorn_default.Radius * head_scale_factor
			-- _tail_outline_adorn.Radius = _tail_outline_adorn_default.Radius * tail_scale_factor
		end

		--Calculate transparency for the body and body outlines
		local target_transparency = 0
		local imm = false
		if _state == HeldNote.State.HoldMissedActive then
			target_transparency = 0.9
			-- _body_outline_left_adorn.Transparency = 1
			-- _body_outline_right_adorn.Transparency = 1
		elseif _state == HeldNote.State.Passed and _did_trigger_tail then
			target_transparency = 1
			imm = true
			-- _body_outline_left_adorn.Transparency = 1
			-- _body_outline_right_adorn.Transparency = 1
		else
			target_transparency = ln_transparency
		end

		if imm then
			_body_adorn.Transparency = target_transparency
		else
			_body_adorn.Transparency = CurveUtil:Expt(
				_body_adorn.Transparency,
				target_transparency,
				CurveUtil:NormalizedDefaultExptValueInSeconds(0.15),
				dt_scale
			)
		end
	end

	local _hold_flash = FlashEvery:new(0.15)
	_hold_flash:flash_now()

	--[[Override--]]
	function self:update(dt_scale)
		self:update_visual(dt_scale)

		if _state == HeldNote.State.Pre then
			if
				_game._audio_manager:get_current_time_ms()
				> (_hit_time_ms - _game._audio_manager:get_note_remove_time())
			then
				--Time missed first hit
				_game._score_manager:register_hit(
					NoteResult.Miss,
					_slot_index,
					_track_index,
					HitParams:new():set_play_sfx(false):set_play_hold_effect(false):set_time_miss(true)
				)

				_game._effects:add_effect(HoldingNoteEffect:new(_game, get_head_position(), NoteResult.Miss))

				_state = HeldNote.State.HoldMissedActive
			end
		elseif
			_state == HeldNote.State.Holding
			or _state == HeldNote.State.HoldMissedActive
			or _state == HeldNote.State.Passed
		then
			if _state == HeldNote.State.Holding then
				_hold_flash:update(dt_scale)
				if _hold_flash:do_flash() then
					_game._effects:add_effect(
						HoldingNoteEffect:new(
							_game,
							_game:get_tracksystem(_slot_index):get_track(_track_index):get_end_position(),
							NoteResult.Perfect
						)
					)
				end
			end

			if
				_game._audio_manager:get_current_time_ms()
				> (get_tail_hit_time() - _game._audio_manager:get_note_remove_time())
			then
				if _state == HeldNote.State.Holding or _state == HeldNote.State.HoldMissedActive then
					_game._effects:add_effect(HoldingNoteEffect:new(_game, get_tail_position(), NoteResult.Miss))

					--Time missed second hit
					_game._score_manager:register_hit(
						NoteResult.Miss,
						_slot_index,
						_track_index,
						HitParams:new():set_play_sfx(false):set_play_hold_effect(false):set_time_miss(true)
					)
				end

				_state = HeldNote.State.DoRemove
			end
		end
	end

	--[[Override--]]
	function self:should_remove()
		return _state == HeldNote.State.DoRemove
	end

	--[[Override--]]
	function self:do_remove()
		_game._object_pool:repool(self.ClassName, _note_obj)
	end

	--[[Override--]]
	function self:test_hit()
		if _state == HeldNote.State.Pre then
			local time_to_end = _game._audio_manager:get_current_time_ms() - _hit_time_ms
			local did_hit, note_result = NoteResult:timedelta_to_result(time_to_end, _game)

			if did_hit then
				return did_hit, note_result, RenderableHit:new(_hit_time_ms, time_to_end, note_result)
			end

			return false, NoteResult.Miss
		elseif _state == HeldNote.State.HoldMissedActive then
			local time_to_end = _game._audio_manager:get_current_time_ms() - get_tail_hit_time()
			local did_hit, note_result = NoteResult:timedelta_to_result(time_to_end, _game)

			if did_hit then
				return did_hit, note_result, RenderableHit:new(get_tail_hit_time(), time_to_end, note_result)
			end

			return false, NoteResult.Miss
		end

		return false, NoteResult.Miss
	end

	--[[Override--]]
	function self:on_hit(note_result, i_notes, renderable_hit)
		if _state == HeldNote.State.Pre then
			if _show_trigger_fx then
				_game._effects:add_effect(TriggerNoteEffect:new(_game, get_head_position(), note_result))
			end

			--Hit the first note
			_game._score_manager:register_hit(
				note_result,
				_slot_index,
				_track_index,
				HitParams:new():set_play_hold_effect(false):set_held_note_begin(true)
			)

			_did_trigger_head = true
			_state = HeldNote.State.Holding
		elseif _state == HeldNote.State.HoldMissedActive then
			if _show_trigger_fx then
				_game._effects:add_effect(TriggerNoteEffect:new(_game, get_tail_position(), note_result))
			end

			if _show_trigger_fx then
				_game._effects:add_effect(TriggerNoteEffect:new(_game, get_tail_position(), note_result))
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
			_state = HeldNote.State.Passed
		end
	end

	--[[Override--]]
	function self:test_release()
		if _state == HeldNote.State.Holding or _state == HeldNote.State.HoldMissedActive then
			local time_to_end = _game._audio_manager:get_current_time_ms() - get_tail_hit_time()
			local did_hit, note_result = NoteResult:release_timedelta_to_result(time_to_end, _game)

			if did_hit then
				return did_hit, note_result, RenderableHit:new(get_tail_hit_time(), time_to_end, note_result)
			end

			if _state == HeldNote.State.HoldMissedActive then
				return false, NoteResult.Miss
			else
				return true, NoteResult.Miss
			end
		end

		return false, NoteResult.Miss
	end
	--[[Override--]]
	function self:on_release(note_result, i_notes, renderable_hit)
		if _state == HeldNote.State.Holding or _state == HeldNote.State.HoldMissedActive then
			if note_result == NoteResult.Miss then
				--Holding or missed first hit, missed second hit
				_game._score_manager:register_hit(
					note_result,
					_slot_index,
					_track_index,
					HitParams:new():set_play_hold_effect(false),
					renderable_hit
				)
				_state = HeldNote.State.HoldMissedActive
			else
				if _show_trigger_fx then
					_game._effects:add_effect(TriggerNoteEffect:new(_game, get_tail_position(), note_result))
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
				_state = HeldNote.State.Passed
			end
		end
	end

	--[[Override--]]
	function self:get_track_index()
		return _track_index
	end

	self:cons()
	return self
end

return HeldNote
