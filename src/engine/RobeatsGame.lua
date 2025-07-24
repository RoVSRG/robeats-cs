local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local InputUtil = require(game.ReplicatedStorage.Shared.InputUtil)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local AudioManager = require(game.ReplicatedStorage.RobeatsGameCore.AudioManager)
local ObjectPool = require(game.ReplicatedStorage.RobeatsGameCore.ObjectPool)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local ScoreManager = require(game.ReplicatedStorage.RobeatsGameCore.ScoreManager)
local NoteTrackSystem = require(game.ReplicatedStorage.RobeatsGameCore.NoteTrack.NoteTrackSystem)
local NoteTrackSystem2D = require(game.ReplicatedStorage.RobeatsGameCore.NoteTrack.NoteTrackSystem2D)
local EffectSystem = require(game.ReplicatedStorage.RobeatsGameCore.Effects.EffectSystem)
local GameSlot = require(game.ReplicatedStorage.RobeatsGameCore.Enums.GameSlot)
local GameTrack = require(game.ReplicatedStorage.RobeatsGameCore.Enums.GameTrack)
local AssertType = require(game.ReplicatedStorage.Shared.AssertType)
local Signal = require(game.ReplicatedStorage.Libraries.LemonSignal)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local Skins = require(game.ReplicatedStorage.Skins)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local Replay = require(game.ReplicatedStorage.RobeatsGameCore.Replay)
local FlashEvery = require(game.ReplicatedStorage.Shared.FlashEvery)

-- local Flipper = require(game.ReplicatedStorage.Packages.Flipper)

local Mods = require(game.ReplicatedStorage.RobeatsGameCore.Enums.Mods)

local ContentProvider = game:GetService("ContentProvider")

local RobeatsGame = {}
RobeatsGame.Mode = {
	Setup = 1;
	Game = 2;
	GameEnded = 3;
}

function RobeatsGame:new(_game_environment_center_position, _config)
	local self = {
		_tracksystems = SPDict:new();
		_audio_manager = nil;
		_score_manager = nil;
		_effects = EffectSystem:new();
		_input = InputUtil:new();
		_sfx_manager = SFXManager:new();
		_object_pool = ObjectPool:new();
	}

	local left_tar_orientation = math.rad(13.5);
	local right_tar_orientation = math.rad(-13.5);

	local _2d_left_tar_pos = 0.1;
	local _2d_right_tar_pos = -0.1;

	self.target_cam_orientation = 0;
	self.target_2d_playfield_pos = 0;

	self.keybind_pressed = Instance.new("BindableEvent")
	self._config = _config

	self.SPRING_CONSTANTS = { frequency = 3.5, dampingRatio = 0.5 }
	self._2D_SPRING_CONSTANTS = { frequency = 2, dampingRatio = 1 }

	local _skin
	local _2d_hit_pos
	local _get_2d_mode = false
	local _is_upscroll = false
	local _ln_transparent = false
	local _show_hit_lighting = false
	local _hide_ln_tails = false
	local _judgement_visibility = {
		[NoteResult.Marvelous] = true,
		[NoteResult.Perfect] = true,
		[NoteResult.Great] = true,
		[NoteResult.Good] = true,
		[NoteResult.Bad] = true,
		[NoteResult.Miss] = true,
	}
	local _note_color = Color3.fromRGB(255, 175, 0)
	local _mods = {}
	local _note_color_affects_2d

	local replay
	local send_replay_data = FlashEvery:new(1.8)

	local skin_loaded = true

	function self:get_skin_loaded()
		return skin_loaded
	end

	self._audio_manager = AudioManager:new(self)
	self._score_manager = ScoreManager:new(self)

	self._mode_changed = Signal.new()

	self.original_cam_cf = CFrame.new()
	
	local _local_game_slot = 0
	function self:get_local_game_slot() return _local_game_slot end
	
	local _current_mode = RobeatsGame.Mode.Setup
	function self:get_mode() return _current_mode end
	function self:set_mode(val) 
		AssertType:is_enum_member(val, RobeatsGame.Mode)
		_current_mode = val 
		self._mode_changed:Fire(_current_mode)

		if val == RobeatsGame.Mode.GameEnded then
            if game.StarterGui:GetCoreGuiEnabled("PlayerList") == false then
                game.StarterGui:SetCoreGuiEnabled("PlayerList", true)
			end
			
			if game.StarterGui:GetCoreGuiEnabled("Chat") == false then
                game.StarterGui:SetCoreGuiEnabled("Chat", true)
            end
		end
	end

	function self:get_replay_hits()
		return replay:get_hits()
	end

	--[[ 2D Implementations ]]
	function self:get_skin() return _skin end
	function self:set_skin(val) _skin = val end

	function self:get_2d_mode() return _get_2d_mode end
	function self:set_2d_mode(val) _get_2d_mode = val end

	function self:get_2d_hit_position() return _2d_hit_pos end
	function self:set_2d_hit_position(val)
		_2d_hit_pos = val;
	end

	function self:is_upscroll() return _is_upscroll end
	function self:set_upscroll_mode(val) 
		_is_upscroll = val
		self._input:invert_keys(val)
	end
	--[[ END of 2D Implementations ]]

	function self:set_ln_transparent(val) _ln_transparent = val end
	function self:get_ln_transparent() return _ln_transparent end

	function self:set_hit_lighting(val) _show_hit_lighting = val end
	function self:get_hit_lighting() return _show_hit_lighting end

	function self:get_ln_tails() return _hide_ln_tails end
	function self:set_ln_tails(val) _hide_ln_tails = val end

	function self:get_judgement_visibility() return _judgement_visibility end
	function self:set_judgement_visibility(val) _judgement_visibility = val end

	function self:get_note_color() return _note_color end
	function self:set_note_color(val) _note_color = val end

	function self:get_target_cam_orientation() return self.target_cam_orientation end
	function self:set_target_cam_orientation(val: number) self.target_cam_orientation = val end

	function self:get_target_2d_playfield_pos() return self.target_2d_playfield_pos end
	function self:set_target_2d_playfield_pos(val) self.target_2d_playfield_pos = val end

	function self:get_mods() return _mods end
	function self:set_mods(val) _mods = val end
	function self:is_mod_active(mod)
		for _, itr_mod in ipairs(_mods) do
			if mod == itr_mod then
				return true
			end
		end
		return false 
	end

	function self:get_note_color_affects_2d() return _note_color_affects_2d end
	function self:set_note_color_affects_2d(val) _note_color_affects_2d = val end

	function self:get_game_environment_center_position()
		return _game_environment_center_position
	end

	function self:setup_world(game_slot)
		_local_game_slot = game_slot
		workspace.CurrentCamera.CFrame = GameSlot:slot_to_camera_cframe_offset(self:get_local_game_slot()) + CFrame.new(self:get_game_environment_center_position())
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		workspace.CurrentCamera.CameraSubject = nil
		self.original_cam_cf = workspace.CurrentCamera.CFrame -- find a way to implement this honestly
		self:set_target_cam_orientation(self.original_cam_cf.Rotation.Z)
		self:set_target_2d_playfield_pos(if self:get_2d_mode() then self.original_2d_playfield_pos.X.Scale else 0) -- this might not work

		if self:is_mod_active(Mods.Sway) then
			-- self._sway_motor = Flipper.SingleMotor.new(0);

			-- self._sway_motor:onStep(function(val)
			-- 	if not self:get_2d_mode() then
			-- 		workspace.CurrentCamera.CFrame = self.original_cam_cf * CFrame.Angles(0, 0, val)
			-- 	else
			-- 		self._gameplay_frame.Position = UDim2.fromScale(self.original_2d_playfield_pos.X.Scale + val, self._gameplay_frame.Position.Y.Scale)
			-- 	end
			-- end)
		end
	end

	function self:start_game(_start_time_ms)
		if self:get_2d_mode() then
			self._tracksystems:add(self:get_local_game_slot(), NoteTrackSystem2D:new(self,self:get_local_game_slot()))
		else
			self._tracksystems:add(self:get_local_game_slot(), NoteTrackSystem:new(self,self:get_local_game_slot()))
		end

		self._audio_manager:start_play(_start_time_ms)
		_current_mode = RobeatsGame.Mode.Game
	end

	function self:get_tracksystem(index)
		return self._tracksystems:get(index)
	end
	function self:get_local_tracksystem()
		return self:get_tracksystem(self:get_local_game_slot())
	end
	function self:tracksystems_itr()
		return self._tracksystems:key_itr()
	end
	
	function self:add_replay_hit(track, action, judgement, scoreData)
		replay:add_replay_hit(self._audio_manager:get_current_time_ms(true), track, action, judgement, scoreData)
	end
	
	function self:update(dt_scale)
		send_replay_data:update(dt_scale)

		if _current_mode == RobeatsGame.Mode.Game then
			self._audio_manager:update(dt_scale)

			-- if self._input:control_just_pressed(InputUtil.KEY_SPEEDUP) then
			-- 	self._config.NoteSpeed += 1
			-- elseif self._input:control_just_pressed(InputUtil.KEY_SPEEDDOWN) then
			-- 	self._config.NoteSpeed -= 1
			-- end

			if replay.viewing then
				local actions = replay:get_actions_this_frame(self._audio_manager:get_current_time_ms(true))

				for _, action in actions do
					if action.action == Replay.HitType.Press then
						self:get_local_tracksystem():press_track_index(action.track, action.judgement)
					elseif action.action == Replay.HitType.Release then
						self:get_local_tracksystem():release_track_index(action.track, action.judgement)
					end
				end
			else
				for itr_key,itr_index in GameTrack:inpututil_key_to_track_index():key_itr() do
					if self._input:control_just_pressed(itr_key) then
						--mod work


						self.keybind_pressed:Fire(itr_index)
						
						local note_result = self:get_local_tracksystem():press_track_index(itr_index)

						self:add_replay_hit(itr_index, Replay.HitType.Press, note_result, self._score_manager:get_end_records())

						if self:is_mod_active(Mods.Sway) then
							if itr_key == 0 or itr_key == 1 then
								if not self:get_2d_mode() then
									self:set_target_cam_orientation(left_tar_orientation)
								else
									self:set_target_2d_playfield_pos(_2d_left_tar_pos)
								end
							elseif itr_key == 2 or itr_key == 3 then
								if not self:get_2d_mode() then
									self:set_target_cam_orientation(right_tar_orientation)
								else
									self:set_target_2d_playfield_pos(_2d_right_tar_pos)
								end
							else
								self:set_target_cam_orientation(0)
								self:set_target_2d_playfield_pos(self.original_2d_playfield_pos.X.Scale);
							end

							-- if not self:get_2d_mode() then
							-- 	self._sway_motor:setGoal(Flipper.Spring.new(self:get_target_cam_orientation(), self.SPRING_CONSTANTS))
							-- else
							-- 	self._sway_motor:setGoal(Flipper.Spring.new(self:get_target_2d_playfield_pos(), self._2D_SPRING_CONSTANTS))
							-- end
							
						end
						
					end

					if self._input:control_just_released(itr_key) then
						local note_result = self:get_local_tracksystem():release_track_index(itr_index)

						self:add_replay_hit(itr_index, Replay.HitType.Release, note_result, self._score_manager:get_end_records())

						if self:is_mod_active(Mods.Sway) then
							-- if not self:get_2d_mode() then
							-- 	self:set_target_cam_orientation(0)
							-- 	self._sway_motor:setGoal(Flipper.Spring.new(0, self.SPRING_CONSTANTS))
							-- else
							-- 	self:set_target_2d_playfield_pos(self.original_2d_playfield_pos.X.Scale)
							-- 	self._sway_motor:setGoal(Flipper.Spring.new(0, self.SPRING_CONSTANTS))
							-- end
						end
					end
				end
			end

			if send_replay_data:do_flash() and not self:is_viewing_replay() then
				replay:send_last_hits()
			end
			
			for _, itr in self._tracksystems:key_itr() do
				itr:update(dt_scale)
			end
			
			self._sfx_manager:update()
			self._score_manager:update()

			self._effects:update(dt_scale)

			self._input:post_update()
		end
	end

	function self:load(_song_key, _local_player_slot, _config, _replay: any?)
		-- replay = Replay.perfect(SongDatabase:get_hash_for_key(_song_key), _config.SongRate)
		replay = _replay or Replay:new({ viewing = false })

		self:set_mods(_config.Mods)

		EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Game)

		if _config.Use2DLane then
			skin_loaded = false

			local skin_name = _config.Skin2D
			local skin = Skins:get_skin(_config.Skin2D)

			if not skin then
				DebugOut:puts("No skin specified, defaulting to first usable skin...")

				skin_name = Skins:key_list():get(1)
				skin = Skins:get_skin(skin_name)
			end

			self:set_skin(skin)
			self:set_note_color_affects_2d(_config.NoteColorAffects2D)

			task.spawn(function()
				ContentProvider:PreloadAsync({ skin })
				skin_loaded = true
			end)

			EnvironmentSetup:setup_2d_environment(_skin, _config)
			self._gameplay_frame = EnvironmentSetup:get_player_gui_root():WaitForChild("GameplayFrame")
			self.original_2d_playfield_pos = self._gameplay_frame.Position

		end

		self._audio_manager:load_song(_song_key, _config)
		self:setup_world(_local_player_slot)
	end
	
	function self:is_viewing_replay()
		return replay.viewing
	end

	function self:teardown()
		for _, val in self:tracksystems_itr() do
			val:teardown()
		end
		self._audio_manager:teardown()
		self._effects:teardown()

		if self:get_2d_mode() then
			EnvironmentSetup:teardown_2d_environment()
		end

		EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Menu)
	end

	return self
end

return RobeatsGame

