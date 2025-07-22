local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RobeatsGame = require(ReplicatedStorage.RobeatsGameCore.RobeatsGame)
local Signal = require(ReplicatedStorage.Libraries.LemonSignal)
local Val = require(ReplicatedStorage.Libraries.Val)

local EnvironmentSetup = require(ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local Skins = require(ReplicatedStorage.Skins)

local GameSessionManager = {}
GameSessionManager.__index = GameSessionManager

function GameSessionManager.new()
	local self = setmetatable({}, GameSessionManager)

	self._game = nil

	-- Active session info
	self._currentSong = nil          -- Full metadata table
	self._currentHitObjects = nil    -- Decoded chart
	self._currentConfig = nil        -- Gameplay config
	self._currentLaneMode = nil      -- "2D" or "3D"
	self._environmentActive = false
	self._activeSkin = nil

	self._heartbeatConnection = nil

	-- Reactive UI values
	self.state = {
		progress = Val.new(0),
		timeLeft = Val.new(0),
		isRunning = Val.new(false),
		score = Val.new(0),
		accuracy = Val.new(0),
	}

	-- Lifecycle signals
	self.onLoaded = Signal.new()   -- Fires when chart & environment loaded
	self.onStart = Signal.new()    -- Fires when gameplay actually begins
	self.onFinish = Signal.new()   -- Fires when song ends (score/accuracy)

	-- Prepare environment baseline
	EnvironmentSetup:initial_setup()

	return self
end

-----------------------------------------------------------
-- ENVIRONMENT MANAGEMENT
-----------------------------------------------------------

function GameSessionManager:_teardownEnvironment()
	if self._currentLaneMode == "2D" then
		EnvironmentSetup:teardown_2d_environment()
	end

	-- Always reset mode back to menu
	EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Menu)
	self._environmentActive = false
	self._currentLaneMode = nil
	self._activeSkin = nil
end

function GameSessionManager:_setupEnvironment(laneMode, config)
	self:_teardownEnvironment()

	if laneMode == "2D" then
		local skinName = config.Skin2D or "Default"
		local skin = Skins:get_skin(skinName)

		if not skin then
			warn("[GameSessionManager] Invalid skin", skinName, "fallback to first available")
			skinName = Skins:key_list():get(1)
			skin = Skins:get_skin(skinName)
		end

		self._activeSkin = skin
		EnvironmentSetup:setup_2d_environment(skin, config)
		self._currentLaneMode = "2D"

	elseif laneMode == "3D" then
		self._currentLaneMode = "3D"
		-- 3D doesn’t need skin setup right now
	else
		error("[GameSessionManager] Invalid laneMode: must be '2D' or '3D'")
	end

	EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Game)
	self._environmentActive = true
end

-----------------------------------------------------------
-- GAMEPLAY LIFECYCLE
-----------------------------------------------------------

-- Load a song: expects a table:
-- {
--    metadata = { Name, ArtistName, Difficulty, Length, ID, ... },
--    hitObjects = { table of decoded chart }
-- }
function GameSessionManager:loadSong(songData, laneMode, config)
	assert(songData and songData.metadata and songData.hitObjects, "[GameSessionManager] loadSong requires {metadata, hitObjects}")

	-- Save session info
	self._currentSong = songData.metadata
	self._currentHitObjects = songData.hitObjects
	self._currentConfig = config

	-- Setup environment (2D skin, 3D world, etc.)
	self:_setupEnvironment(laneMode, config)

	-- Teardown previous game if running
	if self._game then
		self._game:teardown()
		self._game = nil
	end

	-- Create RobeatsGame instance
	local centerPos = Vector3.new(0, 0, 0)
	self._game = RobeatsGame.new(centerPos, config)

	-- Directly pass chart data (NO SongDatabase lookup)
	self._game:load(songData.hitObjects, songData.metadata, config)

	-- Notify listeners
	self.onLoaded:Fire(songData.metadata, config)

	return self
end

function GameSessionManager:start()
	if not self._game then
		warn("[GameSessionManager] Tried to start() without loading a song")
		return
	end

	-- Kick off actual gameplay
	self._game:start_game(0)
	self.state.isRunning:set(true)
	self.onStart:Fire()

	-- Bind to Heartbeat for continuous updates
	self._heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		self:_update(dt)
	end)
end

function GameSessionManager:_update(dt)
	if not self._game or not self.state.isRunning:get() then return end

	self._game:update(dt)

	local audioManager = self._game._audio_manager
	local currentTime = audioManager:get_current_time_ms(true) / 1000
	local songLength = audioManager:get_song_length_ms() / 1000

	self.state.progress:set(math.clamp(currentTime / songLength, 0, 1))
	self.state.timeLeft:set(math.max(songLength - currentTime, 0))

	local scoreMgr = self._game._score_manager
	self.state.score:set(scoreMgr:get_score())
	self.state.accuracy:set(scoreMgr:get_accuracy())

	if audioManager:is_finished() then
		self:finish()
	end
end

function GameSessionManager:finish()
	if not self._game then return end

	self.state.isRunning:set(false)

	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end

	self.onFinish:Fire({
		metadata = self._currentSong,
		score = self.state.score:get(),
		accuracy = self.state.accuracy:get()
	})
end

function GameSessionManager:teardown()
	if self._game then
		self._game:teardown()
		self._game = nil
	end
	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end
	self:_teardownEnvironment()
	self.state.isRunning:set(false)
end

-----------------------------------------------------------
-- CONVENIENCE ENTRYPOINT
-----------------------------------------------------------

-- One-shot: load + start in one call
function GameSessionManager:playSong(songData, laneMode, config)
	self:loadSong(songData, laneMode, config)
	self:start()
end

-----------------------------------------------------------
-- ACCESSORS
-----------------------------------------------------------
function GameSessionManager:getActiveSong()
	return self._currentSong
end

function GameSessionManager:getActiveConfig()
	return self._currentConfig
end

function GameSessionManager:getLaneMode()
	return self._currentLaneMode
end

function GameSessionManager:isRunning()
	return self.state.isRunning:get()
end

return GameSessionManager.new()
