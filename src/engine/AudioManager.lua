local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local HitSFXGroup = require(game.ReplicatedStorage.RobeatsGameCore.HitSFXGroup)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local AssertType = require(game.ReplicatedStorage.Shared.AssertType)
local TimingPresets = require(game.ReplicatedStorage.RobeatsGameCore.TimingPresets)
local SingleNote = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.SingleNote)
local HeldNote = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.HeldNote)
local SingleNote2D = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.SingleNote2D)
local HeldNote2D = require(game.ReplicatedStorage.RobeatsGameCore.NoteTypes.HeldNote2D)
local Config = require(game.ReplicatedStorage.RobeatsGameCore.Types.Config)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local Mods = require(game.ReplicatedStorage.RobeatsGameCore.Enums.Mods)

local AudioManager = {}
AudioManager.Mode = {
	NotLoaded = 0, --No audio is loaded (call AudioManager:load_song)
	Loading = 1, --Audio is loading
	PreStart = 3, --Doing the pre-start countdown
	Playing = 4, --Game is playing
	PostPlaying = 5, --Delay before ending game
	Finished = 6, --Game has finished
}

function AudioManager:new(_game)
	local self = {}

	local _rate = 1 --Rate multiplier, you may implement some sort of way to modify the rate at runtime.
	function self:set_rate(rate)
		_rate = rate
	end
	function self:get_rate()
		return _rate
	end

	--Note speed in milliseconds, from time it takes to spawn the note to time the note is hit. Default value is 2000, or 2 seconds.

	local _note_prebuffer_time = 0

	local _song_key = 0
	function self:get_song_key()
		return _song_key
	end

	local _timing_preset
	function self:get_timing_preset()
		return _timing_preset
	end

	--Note timings: millisecond offset (positive is early, negative is late) mapping to what the note result is
	local _note_bad_max = 300
	local _note_good_max = 260 --Default: 260
	local _note_great_max = 140 --Default: 140
	local _note_perfect_max = 40 --Default: 40
	local _note_marvelous_max = 20 --Default: 40
	local _note_marvelous_min = -20 --Default: -20
	local _note_perfect_min = -40 --Default: -20
	local _note_great_min = -140 --Default: -70
	local _note_good_min = -260
	local _note_bad_min = -300

	--Called in NoteResult:timedelta_to_result(time_to_end, _game)
	function self:get_note_result_timing()
		return _note_bad_max,
			_note_good_max,
			_note_great_max,
			_note_perfect_max,
			_note_marvelous_max,
			_note_marvelous_min,
			_note_perfect_min,
			_note_great_min,
			_note_good_min,
			_note_bad_min
	end

	--Time in milliseconds after note expected hit time to remove note (and do a Time miss)
	local _note_remove_time = -200 --Default: -200
	function self:get_note_remove_time()
		return _note_remove_time
	end

	--Time in milliseconds countdown will take
	local _pre_countdown_time_ms = 3000 --Default: 3000

	--Time in milliseconds to wait after game finishes to end
	local _post_finish_wait_time_ms = 1000 --Default:300

	--Audio offset is milliseconds
	local _audio_time_offset = 0

	--The game audio
	local _bgm = Instance.new("Sound")
	_bgm.Parent = EnvironmentSetup:get_local_elements_folder()
	_bgm.Name = "BGM"
	function self:get_bgm()
		return _bgm
	end

	--Keeping track of BGM TimePosition ourselves (Sound.TimePosition does not update at 60fps)
	local _bgm_time_position = 0
	local _current_audio_data
	local _hit_objects

	--Index of _current_audio_data.HitObject we are currently at
	local _audio_data_index = 1

	--Hit sounds (group is determined by the song map)
	local _hit_sfx_group = nil
	function self:get_hit_sfx_group()
		return _hit_sfx_group
	end

	local _current_mode = AudioManager.Mode.NotLoaded
	function self:get_mode()
		return _current_mode
	end

	local _is_playing = false
	local _pre_start_time_ms = 0
	local _post_playing_time_ms = 0
	local _audio_volume = 0.5
	local _music_volume_multiplier = 1.0
	local _hitsounds

	function self:get_hitsounds()
		return _hitsounds
	end

	local _note_count = 0
	function self:get_note_count()
		return _note_count
	end

	function self:get_note_prebuffer_time_ms(): number
		return _note_prebuffer_time
	end

	function self:load_song(song_key, _config: Config.GameConfig)
		_song_key = song_key
		_current_mode = AudioManager.Mode.Loading
		_audio_data_index = 1
		_current_audio_data = SongDatabase:GetSongByKey(_song_key)

		local sfxg_id = _current_audio_data.AudioHitSFXGroup or 0 -- Default to 0 if not specified
		_hit_sfx_group = HitSFXGroup:new(_game, sfxg_id, _config.HitsoundVolume or 1.0)
		_hit_sfx_group:preload()

		--Apply audio offset
		_audio_time_offset = _config.GlobalAudioOffset or 0
		_audio_time_offset = _audio_time_offset + _current_audio_data.TimeOffset

		--Apply song rate
		self:set_rate(_config.SongRate / 100)

		_hitsounds = _config.Hitsounds
		
		--Apply music volume multiplier from options
		_music_volume_multiplier = _config.MusicVolume or 1.0

		--Add hit objects and perform note count calculations
		-- For now, using the folder name method - this should be enhanced to handle song keys properly
		local songData = SongDatabase:GetSongByKey(_song_key)
		if songData and songData.FolderName then
			_hit_objects = SongDatabase:GetHitObjectsForFolderName(songData.FolderName) or {}
		else
			_hit_objects = {}
		end

		print(#_hit_objects, "hit objects loaded for song key:", _song_key)

		-- TODO: Apply rate scaling and mirror mod transformations to _hit_objects here

		for i = 1, #_hit_objects do
			local itr = _hit_objects[i]
			if itr.Type == 1 then
				_note_count = _note_count + 1
			else
				_note_count = _note_count + 2
			end

			-- Apply rate scaling
			itr.Time = itr.Time / _rate

			if itr.Duration then
				itr.Duration = itr.Duration / _rate
			end
		end

		--Load background music
		_bgm.SoundId = _current_audio_data.AudioID
		_bgm.Playing = true
		_bgm.Volume = 0
		_bgm.PlaybackSpeed = 0
		_bgm_time_position = 0

		--Set default audio volume if it isn't specified
		if _current_audio_data.AudioVolume ~= nil then
			_audio_volume = _current_audio_data.AudioVolume
		end

		--Apply note speed multiplier
		_note_prebuffer_time = 13720 / math.clamp(_config.NoteSpeed or 50, 1, 100)

		--Apply timing windows
		if not _config.UseCustomJudgements then
			_timing_preset = TimingPresets.calculateTimingWindows(_config.OverallDifficulty or 5)
			_note_bad_max = _timing_preset.NoteBadMaxMS
			_note_good_max = _timing_preset.NoteGoodMaxMS
			_note_great_max = _timing_preset.NoteGreatMaxMS
			_note_perfect_max = _timing_preset.NotePerfectMaxMS
			_note_marvelous_max = _timing_preset.NoteMarvelousMaxMS
			_note_marvelous_min = _timing_preset.NoteMarvelousMinMS
			_note_perfect_min = _timing_preset.NotePerfectMinMS
			_note_great_min = _timing_preset.NoteGreatMinMS
			_note_good_min = _timing_preset.NoteGoodMinMS
			_note_bad_min = _timing_preset.NoteBadMinMS
		else
			_note_bad_max = _config.CustomBadPreset or 300
			_note_good_max = _config.CustomGoodPreset or 260
			_note_great_max = _config.CustomGreatPreset or 140
			_note_perfect_max = _config.CustomPerfectPreset or 40
			_note_marvelous_max = _config.CustomMarvelousPreset or 20
			_note_marvelous_min = -(_config.CustomMarvelousPreset or 20)
			_note_perfect_min = -(_config.CustomPerfectPreset or 40)
			_note_great_min = -(_config.CustomGreatPreset or 140)
			_note_good_min = -(_config.CustomGoodPreset or 260)
			_note_bad_min = -(_config.CustomBadPreset or 300)
		end
	end

	function self:teardown()
		_bgm:Destroy()
	end

	function self:is_ready_to_play()
		return _current_audio_data ~= nil and _bgm.IsLoaded == true and _game:get_skin_loaded()
	end

	function self:is_prestart()
		return _current_mode == AudioManager.Mode.PreStart
	end
	function self:is_playing()
		return _current_mode == AudioManager.Mode.Playing
	end
	function self:is_finished()
		return _current_mode == AudioManager.Mode.Finished
	end

	local function push_back_single_note(i, itr_hitobj, current_time_ms, hit_time)
		local track_number = itr_hitobj.Track
		AssertType:is_int(track_number)

		for _, tracksystem in _game:tracksystems_itr() do
			if _game:get_2d_mode() then
				tracksystem:get_notes():push_back(
					SingleNote2D:new(_game, track_number, tracksystem:get_game_slot(), current_time_ms, hit_time)
				)
			else
				tracksystem
					:get_notes()
					:push_back(
						SingleNote:new(_game, track_number, tracksystem:get_game_slot(), current_time_ms, hit_time)
					)
			end
		end
	end

	local function push_back_heldnote(i, itr_hitobj, current_time_ms, hit_time, duration)
		local track_number = itr_hitobj.Track
		AssertType:is_int(track_number)

		for _, tracksystem in _game:tracksystems_itr() do
			if _game:get_2d_mode() then
				tracksystem:get_notes():push_back(
					HeldNote2D:new(
						_game,
						track_number,
						tracksystem:get_game_slot(),
						current_time_ms,
						hit_time,
						duration
					)
				)
			else
				tracksystem:get_notes():push_back(
					HeldNote:new(_game, track_number, tracksystem:get_game_slot(), current_time_ms, hit_time, duration)
				)
			end
		end
	end

	function self:start_play(_start_time_ms)
		_current_mode = AudioManager.Mode.PreStart
		_pre_start_time_ms = 0

		if not _start_time_ms then
			_start_time_ms = math.max(0, _hit_objects[1].Time - _note_prebuffer_time - _pre_countdown_time_ms)
		end

		_bgm_time_position = _start_time_ms / 1000

		_bgm.TimePosition = _bgm_time_position - (_audio_time_offset / 1000)

		for _, hitObject in _hit_objects do
			if _bgm_time_position * 1000 > hitObject.Time + _note_bad_max then
				_audio_data_index = _audio_data_index + 1
				continue
			end
		end
	end

	local _raise_pre_start_trigger = false
	local _raise_pre_start_trigger_val = 0
	local _raise_pre_start_trigger_duration = 0
	function self:raise_pre_start_trigger()
		local rtv = _raise_pre_start_trigger
		_raise_pre_start_trigger = false
		return rtv, _raise_pre_start_trigger_val, _raise_pre_start_trigger_duration
	end

	local _sync_timer = 0
	local _raise_ended_trigger = false
	local _raise_just_finished = false

	function self:update(dt_scale)
		_note_prebuffer_time = 13720 / math.clamp(_game._config.NoteSpeed, 1, 100)

		if _current_mode == AudioManager.Mode.PreStart then
			--Do pre-start countdown
			local pre_start_time_pre = _pre_start_time_ms
			local pre_start_time_post = _pre_start_time_ms + CurveUtil:TimescaleToDeltaTime(dt_scale) * 1000
			_pre_start_time_ms = pre_start_time_post

			local PCT_3 = _pre_countdown_time_ms * 0.2
			local PCT_2 = _pre_countdown_time_ms * 0.4
			local PCT_1 = _pre_countdown_time_ms * 0.6
			local PCT_START = _pre_countdown_time_ms * 0.8

			if pre_start_time_pre < PCT_3 and pre_start_time_post > PCT_3 then
				_raise_pre_start_trigger = true
				_raise_pre_start_trigger_val = 4
				_raise_pre_start_trigger_duration = PCT_2 - PCT_3
			elseif pre_start_time_pre < PCT_2 and pre_start_time_post > PCT_2 then
				_raise_pre_start_trigger = true
				_raise_pre_start_trigger_val = 3
				_raise_pre_start_trigger_duration = PCT_1 - PCT_2
			elseif pre_start_time_pre < PCT_1 and pre_start_time_post > PCT_1 then
				_raise_pre_start_trigger = true
				_raise_pre_start_trigger_val = 2
				_raise_pre_start_trigger_duration = PCT_START - PCT_1
			elseif pre_start_time_pre < PCT_START and pre_start_time_post > PCT_START then
				_raise_pre_start_trigger = true
				_raise_pre_start_trigger_val = 1
				_raise_pre_start_trigger_duration = _pre_countdown_time_ms - PCT_START
			end

			if _pre_start_time_ms >= _pre_countdown_time_ms then
				-- _bgm.TimePosition = 0
				_bgm.Volume = _audio_volume * _music_volume_multiplier
				_bgm.PlaybackSpeed = _rate

				_current_mode = AudioManager.Mode.Playing
			end

			self:update_spawn_notes(dt_scale)
		elseif _current_mode == AudioManager.Mode.Playing then
			self:update_spawn_notes(dt_scale)
			_bgm_time_position =
				math.min(_bgm_time_position + CurveUtil:TimescaleToDeltaTime(dt_scale), self:get_song_length_ms())

			--[[
				Estrol's TODO: fix with rate first

			_sync_timer += CurveUtil:TimescaleToDeltaTime(dt_scale)
			if _bgm.IsLoaded == true and math.abs(_bgm_time_position - _bgm.TimePosition) > 0.15 and _sync_timer > 5 then
				_sync_timer = 0
				_bgm.TimePosition = _bgm_time_position

				warn("[Audio] Force sync")
			end]]

			if _raise_ended_trigger == true or self:get_current_time_ms() > self:get_song_length_ms() then
				_current_mode = AudioManager.Mode.PostPlaying
			end
		elseif _current_mode == AudioManager.Mode.PostPlaying then
			_post_playing_time_ms = _post_playing_time_ms + CurveUtil:TimescaleToDeltaTime(dt_scale) * 1000
			if _post_playing_time_ms > _post_finish_wait_time_ms then
				_current_mode = AudioManager.Mode.Finished
				_raise_just_finished = true
			end
		end
	end

	function self:get_just_finished()
		local rtv = _raise_just_finished
		_raise_just_finished = false
		return rtv
	end

	local inferred_song_length

	function self:infer_song_length()
		if inferred_song_length then
			return inferred_song_length
		end

		if #_hit_objects == 0 then
			return nil
		end

		local initialHitTime
		local largestEndTime

		for i = #_hit_objects, 1, -1 do
			local hitObject = _hit_objects[i]
			local endTime = hitObject.Time + (hitObject.Duration or 0)

			if not largestEndTime and not initialHitTime then
				initialHitTime = hitObject.Time
				largestEndTime = endTime
				continue
			end

			if hitObject.Time ~= initialHitTime then
				break
			end

			if endTime > largestEndTime then
				largestEndTime = endTime
			end
		end

		inferred_song_length = largestEndTime

		return inferred_song_length
	end

	function self:update_spawn_notes()
		local current_time_ms: number = self:get_current_time_ms()
		local note_prebuffer_time_ms: number = self:get_note_prebuffer_time_ms()

		local test_time = current_time_ms + note_prebuffer_time_ms - _pre_countdown_time_ms

		for i = _audio_data_index, #_hit_objects do
			local itr_hitobj = _hit_objects[i]

			local hitObjectType = itr_hitobj.Duration ~= nil and 2 or 1

			if test_time >= itr_hitobj.Time then
				if hitObjectType == 1 then
					push_back_single_note(i, itr_hitobj, current_time_ms, itr_hitobj.Time + _pre_countdown_time_ms)
				elseif hitObjectType == 2 then
					if itr_hitobj.Duration > 0 then
						push_back_heldnote(
							i,
							itr_hitobj,
							current_time_ms,
							itr_hitobj.Time + _pre_countdown_time_ms,
							itr_hitobj.Duration
						)
					else
						push_back_single_note(i, itr_hitobj, current_time_ms, itr_hitobj.Time + _pre_countdown_time_ms)
					end
				end
				_audio_data_index = _audio_data_index + 1
			else
				break
			end
		end
	end

	function self:get_current_time_ms(no_offset): number
		return _bgm_time_position * 1000 + (if no_offset then 0 else _pre_start_time_ms) + _audio_time_offset
	end

	function self:get_song_length_ms(): number
		if #_hit_objects == 0 then
			-- If no hit objects, use BGM length as fallback
			if _bgm.IsLoaded then
				return _bgm.TimeLength * 1000 + _audio_time_offset + _pre_countdown_time_ms
			else
				return 30000 + _audio_time_offset + _pre_countdown_time_ms -- 30 second fallback
			end
		end

		-- Add the pre-countdown time to match how notes are scheduled
		return self:infer_song_length() + _audio_time_offset + _pre_countdown_time_ms + _post_finish_wait_time_ms
	end

	return self
end

return AudioManager
