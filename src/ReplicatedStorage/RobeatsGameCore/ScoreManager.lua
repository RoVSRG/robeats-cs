local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local InputUtil = require(game.ReplicatedStorage.Shared.InputUtil)
local NoteResultPopupEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.NoteResultPopupEffect)
local NoteResultPopupEffect2D = require(game.ReplicatedStorage.RobeatsGameCore.Effects.NoteResultPopupEffect2D)
local HoldingNoteEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.HoldingNoteEffect)
local HoldingNoteEffect2D = require(game.ReplicatedStorage.RobeatsGameCore.Effects.HoldingNoteEffect2D)
local RenderableHit = require(game.ReplicatedStorage.RobeatsGameCore.RenderableHit)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)

local Signal = require(game.ReplicatedStorage.Packages.Signal)

local ScoreManager = {}

function ScoreManager:new(_game)
	local self = {}
	
	local _chain = 0
	function self:get_chain() return _chain end

	local result_to_point_increase = {
		[NoteResult.Miss] = 0;
		[NoteResult.Bad] = 50;
		[NoteResult.Good] = 100;
		[NoteResult.Great] = 200;
		[NoteResult.Perfect] = 300;
		[NoteResult.Marvelous] = 375;
	}

	local _marvelous_count = 0
	local _perfect_count = 0
	local _great_count = 0
	local _good_count = 0
	local _bad_count = 0
	local _miss_count = 0
	local _max_chain = 0
	local _score = 0
	local _ghost_taps = 0
	local _hits = {}

	local _on_change = Signal.new()

	function self:get_end_records() return _marvelous_count,_perfect_count,_great_count,_good_count,_bad_count,_miss_count,_max_chain end

	function self:get_total_judgements()
		return _marvelous_count + _perfect_count + _great_count + _good_count + _bad_count
	end

	function self:get_accuracy()
		local total_count = self:get_total_judgements() + _miss_count
		
		if total_count == 0 then
			return 0
		end

		return ((_marvelous_count * 1.0) + (_perfect_count * 1.0) + (_great_count * 0.75) + (_good_count * 0.37) + (_bad_count * 0.25)) / total_count
	end

	function self:get_mean()
		local mean = 0

		for _, hit in ipairs(_hits) do
			mean += hit.time_left
		end

		if #_hits ~= 0 then
			mean /= #_hits
		end

		return mean
	end

	local _frame_has_played_sfx = false

	function self:register_hit(
		note_result,
		slot_index,
		track_index,
		params,
		renderable_hit
	)
		local track = _game:get_tracksystem(slot_index):get_track(track_index)

		if (not params.GhostTap) and _game:get_judgement_visibility()[note_result + 1] then
			if _game:get_2d_mode() then
				_game._effects:add_effect(NoteResultPopupEffect2D:new(
					_game,
					note_result
				))
			else
				_game._effects:add_effect(NoteResultPopupEffect:new(
					_game,
					track:get_end_position() + Vector3.new(0,0.25,0),
					note_result
				))
			end
		end

		if params.PlaySFX == true and (not params.GhostTap) then
			
			--Make sure only one sfx is played per frame
			if _frame_has_played_sfx == false then
				if note_result ~= NoteResult.Miss then
					if params.IsHeldNoteBegin == true then
						_game._audio_manager:get_hit_sfx_group():play_first()
					else
						_game._audio_manager:get_hit_sfx_group():play_alternating()
					end
				else
					_game._sfx_manager:play_sfx(SFXManager.SFX_MISS)
				end
				_frame_has_played_sfx = true
			end
			
			--Create an effect at HoldEffectPosition if PlayHoldEffect is true
			if params.PlayHoldEffect then
				if note_result ~= NoteResult.Miss then
					if _game:get_2d_mode() then
						_game._effects:add_effect(HoldingNoteEffect2D:new(
							_game,
							track_index
						))
					else
						_game._effects:add_effect(HoldingNoteEffect:new(
							_game,
							params.HoldEffectPosition,
							note_result
						))
					end
				end
			end
		end
		
		--Increment stats
		if note_result == NoteResult.Marvelous then
			_marvelous_count += 1
			_chain += 1

		elseif note_result == NoteResult.Perfect then
			_chain += 1
			_perfect_count += 1

		elseif note_result == NoteResult.Great then
			_chain += 1
			_great_count += 1

		elseif note_result == NoteResult.Good then
			_good_count += 1

		elseif note_result == NoteResult.Bad then
			_chain = 0
			_bad_count = _bad_count + 1
		else
			if params.GhostTap then
				_ghost_taps += 1

			elseif _chain > 0 then
				_chain = 0
				_miss_count = _miss_count + 1

			elseif params.TimeMiss == true then
				_miss_count = _miss_count + 1
			end
		end

		_score += result_to_point_increase[note_result]

		_max_chain = math.max(_chain,_max_chain)
		table.insert(_hits, renderable_hit)

		_on_change:Fire(_marvelous_count,_perfect_count,_great_count,_good_count,_bad_count,_miss_count,_max_chain,_chain,_score,renderable_hit)
	end

	function self:get_hits() return _hits end

	function self:get_score() return _score end

	function self:get_ghost_taps() return _ghost_taps end

	function self:get_on_change() return _on_change end

	function self:get_chain() return _chain end

	function self:update()
		_frame_has_played_sfx = false
	end

	return self
end

return ScoreManager
