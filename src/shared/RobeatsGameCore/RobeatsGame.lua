-- RobeatsGame.lua
local EnvironmentSetup = require("@shared/RobeatsGameCore/EnvironmentSetup")
local InputUtil = require("@shared/Shared/InputUtil")
local SPDict = require("@shared/Shared/SPDict")
local AudioManager = require("@shared/RobeatsGameCore/AudioManager")
local ObjectPool = require("@shared/RobeatsGameCore/ObjectPool")
local SFXManager = require("@shared/RobeatsGameCore/SFXManager")
local ScoreManager = require("@shared/RobeatsGameCore/ScoreManager")
local NoteTrackSystem = require("@shared/RobeatsGameCore/NoteTrack/NoteTrackSystem")
local NoteTrackSystem2D = require("@shared/RobeatsGameCore/NoteTrack/NoteTrackSystem2D")
local EffectSystem = require("@shared/RobeatsGameCore/Effects/EffectSystem")
local GameSlot = require("@shared/RobeatsGameCore/Enums/GameSlot")
local GameTrack = require("@shared/RobeatsGameCore/Enums/GameTrack")
local NoteResult = require("@shared/RobeatsGameCore/Enums/NoteResult")

local RobeatsGame = {}
RobeatsGame.__index = RobeatsGame

RobeatsGame.Mode = {
	Setup = 1,
	Playing = 2,
	Ended = 3
}

-- Constructor
function RobeatsGame.new(centerPos, config)
	local self = setmetatable({}, RobeatsGame)

	self._centerPos = centerPos
	self._config = config

	-- Core subsystems
	self._tracksystems = SPDict:new()
	self._audioManager = AudioManager:new(self)
	self._scoreManager = ScoreManager:new(self)
	self._effects = EffectSystem:new()
	self._input = InputUtil:new()
	self._sfxManager = SFXManager:new()
	self._objectPool = ObjectPool:new()

	self._laneMode2D = config.Use2DLane or false
	self._currentMode = RobeatsGame.Mode.Setup

	return self
end

---------------------------------------------------
-- ENVIRONMENT SETUP
---------------------------------------------------
function RobeatsGame:setupWorld(localSlot)
	self._localSlot = localSlot

	workspace.CurrentCamera.CFrame = GameSlot:slot_to_camera_cframe_offset(localSlot) + self._centerPos
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	workspace.CurrentCamera.CameraSubject = nil

	-- Setup track systems
	if self._laneMode2D then
		self._tracksystems:add(localSlot, NoteTrackSystem2D:new(self, localSlot))
	else
		self._tracksystems:add(localSlot, NoteTrackSystem:new(self, localSlot))
	end
end

---------------------------------------------------
-- LOADING A SONG
---------------------------------------------------
function RobeatsGame:load(songData, localSlot, config)
	-- songData:
	-- {
	--    metadata = { AudioAssetId, Length, etc. },
	--    hitObjects = { [1] = {Time=..., Track=...,Type=...}, ... }
	-- }

	EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Game)

	-- Setup environment for 2D if needed
	if config.Use2DLane then
		local skin = config.Skin2D
		EnvironmentSetup:setup_2d_environment(skin, config)
		self._gameplayFrame = EnvironmentSetup:get_player_gui_root():WaitForChild("GameplayFrame")
	end

	self._audioManager:loadSong(songData.metadata, songData.hitObjects, config)
	self:setupWorld(localSlot)
	self._scoreManager:reset()
end

---------------------------------------------------
-- START GAME
---------------------------------------------------
function RobeatsGame:startGame(startTimeMs)
	self._audioManager:start_play(startTimeMs)
	self._currentMode = RobeatsGame.Mode.Playing
end

---------------------------------------------------
-- UPDATE LOOP
---------------------------------------------------
function RobeatsGame:update(dt)
	if self._currentMode ~= RobeatsGame.Mode.Playing then return end

	-- Update audio time, spawn notes
	self._audioManager:update(dt)

	-- Handle inputs → feed to track system
	for key, trackIndex in GameTrack:inpututil_key_to_track_index():key_itr() do
		if self._input:control_just_pressed(key) then
			local noteResult = self:get_local_tracksystem():press_track_index(trackIndex)
			self._scoreManager:register_judgement(noteResult)
		end

		if self._input:control_just_released(key) then
			local noteResult = self:get_local_tracksystem():release_track_index(trackIndex)
			self._scoreManager:register_judgement(noteResult)
		end
	end

	-- Update track systems, effects, scoring
	for _, trackSys in self._tracksystems:key_itr() do
		trackSys:update(dt)
	end

	self._sfxManager:update()
	self._scoreManager:update()
	self._effects:update(dt)
	self._input:post_update()

	-- Check if finished
	if self._audioManager:is_finished() then
		self._currentMode = RobeatsGame.Mode.Ended
	end
end

---------------------------------------------------
-- GETTERS
---------------------------------------------------
function RobeatsGame:get_local_tracksystem()
	return self._tracksystems:get(self._localSlot)
end

function RobeatsGame:get_score()
	return self._scoreManager:get_score()
end

function RobeatsGame:get_accuracy()
	return self._scoreManager:get_accuracy()
end

function RobeatsGame:get_progress()
	return self._audioManager:get_current_time_ms(true) / self._audioManager:get_song_length_ms()
end

function RobeatsGame:get_time_left()
	local length = self._audioManager:get_song_length_ms() / 1000
	local current = self._audioManager:get_current_time_ms(true) / 1000
	return math.max(length - current, 0)
end

---------------------------------------------------
-- CLEANUP
---------------------------------------------------
function RobeatsGame:teardown()
	for _, trackSys in self._tracksystems:key_itr() do
		trackSys:teardown()
	end
	self._audioManager:teardown()
	self._effects:teardown()

	if self._laneMode2D then
		EnvironmentSetup:teardown_2d_environment()
	end

	EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Menu)
end

return RobeatsGame
