local CurveUtil = require("@shared/Shared/CurveUtil")
local HitSFXGroup = require("@shared/RobeatsGameCore/HitSFXGroup")
local EnvironmentSetup = require("@shared/RobeatsGameCore/EnvironmentSetup")
local AssertType = require("@shared/Shared/AssertType")
local TimingPresets = require("@shared/RobeatsGameCore/TimingPresets")
local SingleNote = require("@shared/RobeatsGameCore/NoteTypes/SingleNote")
local HeldNote = require("@shared/RobeatsGameCore/NoteTypes/HeldNote")
local SingleNote2D = require("@shared/RobeatsGameCore/NoteTypes/SingleNote2D")
local HeldNote2D = require("@shared/RobeatsGameCore/NoteTypes/HeldNote2D")

local AudioManager = {}
AudioManager.Mode = {
	NotLoaded = 0,
	Loading = 1,
	PreStart = 2,
	Playing = 3,
	Finished = 4,
}

function AudioManager:new(_game)
	local self = {}

	-- internal state
	local _mode = AudioManager.Mode.NotLoaded
	local _rate = 1
	local _note_prebuffer_time = 0
	local _timing_windows = {} -- filled in loadSong
	local _hit_sfx_group = nil
	local _song_data = nil
	local _hit_objects = {}
	local _audio_index = 1
	local _pre_countdown_ms = 3000
	local _countdown_elapsed = 0
	local _bgm_time_position = 0
	local _audio_time_offset = 0
	local _bgm_volume = 0.5

	-- set up background music sound
	local _bgm = Instance.new("Sound")
	_bgm.Name = "BGM"
	_bgm.Parent = EnvironmentSetup:get_local_elements_folder()

	-- getters
	function self:get_mode()
		return _mode
	end
	function self:get_rate()
		return _rate
	end
	function self:get_note_prebuffer_ms()
		return _note_prebuffer_time
	end
	function self:get_current_time_ms()
		return _bgm_time_position * 1000 + _audio_time_offset
	end
	function self:get_song_length_ms()
		local length = _bgm.TimeLength * 1000
		return length * 1000 / _rate + _pre_countdown_ms
	end

	-- load metadata + hitobjects
	function self:loadSong(songData, hitObjects, config)
		_song_data = songData
		_hit_objects = hitObjects
		_audio_index = 1
		_countdown_elapsed = 0
		_mode = AudioManager.Mode.Loading

		-- hit SFX
		if songData.AudioHitSFXGroup then
			_hit_sfx_group = HitSFXGroup:new(_game, songData.AudioHitSFXGroup)
			_hit_sfx_group:preload()
		end

		-- audio offset & rate
		_audio_time_offset = (config.AudioOffset or 0) + (songData.AudioTimeOffset or 0)
		_rate = (config.SongRate or 100) / 100
		_bgm.Volume = 0
		_bgm.PlaybackSpeed = 0
		_bgm.SoundId = songData.AudioAssetId
		_bgm:Play() -- preload

		-- volume
		_bgm_volume = songData.AudioVolume or 1

		-- note prebuffer
		_note_prebuffer_time = 13720 / math.clamp(config.NoteSpeed or 1, 1, 100)

		-- timing windows
		local preset = TimingPresets[config.TimingPreset or "Default"]
		if preset then
			_timing_windows = {
				preset.NoteBadMaxMS,
				preset.NoteGoodMaxMS,
				preset.NoteGreatMaxMS,
				preset.NotePerfectMaxMS,
				preset.NoteMarvelousMaxMS,
				-preset.NoteMarvelousMinMS,
				-preset.NotePerfectMinMS,
				-preset.NoteGreatMinMS,
				-preset.NoteGoodMinMS,
				-preset.NoteBadMinMS,
			}
		else
			_timing_windows = {
				300,
				260,
				140,
				40,
				20,
				-20,
				-40,
				-140,
				-260,
				-300,
			}
		end
	end

	-- begin playback (triggers countdown → play)
	function self:startPlay()
		if _mode ~= AudioManager.Mode.Loading then
			return
		end
		_mode = AudioManager.Mode.PreStart
	end

	-- spawn a single note into track systems
	local function pushSingle(i, obj, currentMs, hitMs)
		local proto = _game:get_2d_mode() and SingleNote2D or SingleNote
		for _, ts in _game:tracksystems_itr() do
			ts:get_notes():push_back(proto:new(_game, obj.Track, ts:get_game_slot(), currentMs, hitMs))
		end
	end

	-- spawn a held note into track systems
	local function pushHeld(i, obj, currentMs, hitMs, dur)
		local proto = _game:get_2d_mode() and HeldNote2D or HeldNote
		for _, ts in _game:tracksystems_itr() do
			ts:get_notes():push_back(proto:new(_game, obj.Track, ts:get_game_slot(), currentMs, hitMs, dur))
		end
	end

	-- update loop
	function self:update(dt_scale)
		if _mode == AudioManager.Mode.PreStart then
			-- countdown
			local deltaMs = CurveUtil:TimescaleToDeltaTime(dt_scale) * 1000
			_countdown_elapsed += deltaMs
			if _countdown_elapsed >= _pre_countdown_ms then
				-- start audio
				_bgm.Volume = _bgm_volume
				_bgm.PlaybackSpeed = _rate
				_mode = AudioManager.Mode.Playing
			end

			-- spawn early notes
			self:updateSpawn(dt_scale)
		elseif _mode == AudioManager.Mode.Playing then
			_bgm_time_position =
				math.min(_bgm_time_position + CurveUtil:TimescaleToDeltaTime(dt_scale), _bgm.TimeLength)

			self:updateSpawn(dt_scale)

			if _bgm_time_position >= _bgm.TimeLength then
				_mode = AudioManager.Mode.Finished
			end
		end
	end

	-- spawn notes when within prebuffer window
	function self:updateSpawn(dt_scale)
		local currentMs = self:get_current_time_ms()
		local buffer = self:get_note_prebuffer_ms()
		while _audio_index <= #_hit_objects and currentMs + buffer >= _hit_objects[_audio_index].Time do
			local obj = _hit_objects[_audio_index]
			if obj.Type == 1 then
				pushSingle(_audio_index, obj, currentMs, obj.Time + buffer)
			else
				pushHeld(_audio_index, obj, currentMs, obj.Time + buffer, obj.Duration or 0)
			end
			_audio_index += 1
		end
	end

	-- teardown when done
	function self:teardown()
		_bgm:Stop()
		_bgm:Destroy()
		_mode = AudioManager.Mode.NotLoaded
	end

	return self
end

return AudioManager
