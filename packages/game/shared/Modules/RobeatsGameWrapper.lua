--!strict
-- RobeatsGameWrapper: A high-level wrapper around RobeatsGame for external scripts
-- Provides a clean, camelCase API for managing song playback and game lifecycle

local RobeatsGame = require(game.ReplicatedStorage.RobeatsGameCore.RobeatsGame)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local Replay = require(game.ReplicatedStorage.RobeatsGameCore.Replay)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local Signal = require(game.ReplicatedStorage.Libraries.LemonSignal)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local Options = require(game.ReplicatedStorage.State.Options)
local Rating = require(game.ReplicatedStorage.Calculator.Rating)

local Remotes = game.ReplicatedStorage.Remotes

local Transient = require(game.ReplicatedStorage.State.Transient)

local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Types
export type GameConfig = {
	-- Song Settings
	songKey: string | number,

	-- Advanced Settings
	startTimeMs: number?,
	gameSlot: number?,

	-- Replay Settings
	replay: any?,
	recordReplay: boolean?,
}

export type GameStats = {
	rating: number,
	score: number,
	accuracy: number,
	combo: number,
	maxCombo: number,
	marvelous: number,
	perfect: number,
	great: number,
	good: number,
	bad: number,
	miss: number,
	totalNotes: number,
	notesHit: number,
	grade: string,
	hits: { [number]: any }, -- Renderable hits
	mean: number, -- Running mean of hit timings
}

export type GameState = "idle" | "loading" | "ready" | "playing" | "paused" | "finished"

local RobeatsGameWrapper = {}
RobeatsGameWrapper.__index = RobeatsGameWrapper

function RobeatsGameWrapper.new()
	local self = setmetatable({}, RobeatsGameWrapper)

	-- Core game instance
	self._game = nil :: any
	self._updateConnection = nil :: RBXScriptConnection?

	-- State management
	self._state = "idle" :: GameState
	self._config = nil :: GameConfig?
	self._startTime = 0

	-- Events
	self.stateChanged = Signal.new() :: any
	self.songStarted = Signal.new() :: any
	self.songFinished = Signal.new() :: any
	self.noteHit = Signal.new() :: any
	self.noteMissed = Signal.new() :: any
	self.scoreChanged = Signal.new() :: any
	self.updated = Signal.new() :: any

	-- Initialize stats
	self._stats = {} :: GameStats
	self:_resetStats()

	return self
end

function RobeatsGameWrapper:_setState(newState: GameState)
	if self._state ~= newState then
		local oldState = self._state
		self._state = newState
		self.stateChanged:Fire(newState, oldState)
	end
end

function RobeatsGameWrapper:_setupEventListeners()
	if not self._game then
		return
	end

	local key = Transient.song.selected:get()
	local rate = Transient.song.rate:get()
	local song = SongDatabase:GetSongByKey(key)

	-- Connect to score manager events
	local scoreManager = self._game._score_manager
	if scoreManager then
		-- Listen for score manager changes
		-- Parameters: marvelous_count, perfect_count, great_count, good_count, bad_count, miss_count, max_chain, chain, score, renderable_hit
		scoreManager:get_on_change():Connect(
			function(
				marvelous: number,
				perfect: number,
				great: number,
				good: number,
				bad: number,
				miss: number,
				maxChain: number,
				chain: number,
				score: number,
				renderableHit: any,
				hits: any
			)
				-- Update all stats from ScoreManager
				self._stats.marvelous = marvelous
				self._stats.perfect = perfect
				self._stats.great = great
				self._stats.good = good
				self._stats.bad = bad
				self._stats.miss = miss
				self._stats.score = score
				self._stats.maxCombo = maxChain
				self._stats.combo = chain
				self._stats.notesHit = marvelous + perfect + great + good + bad
				self._stats.hits = hits

				self._stats.accuracy = (scoreManager:get_accuracy() :: number) * 100 -- Convert to percentage
				self._stats.rating = Rating.calculateRating(rate / 100, self._stats.accuracy, song.Difficulty)

				-- Update mean using ScoreManager's method
				self._stats.mean = scoreManager:get_mean()

				-- Update accuracy using ScoreManager's method

				-- Fire events
				self.scoreChanged:Fire(self._stats)

				-- Fire note hit/miss events based on renderable hit
				if renderableHit then
					local judgement = renderableHit.judgement
					if judgement == NoteResult.Miss then
						self.noteMissed:Fire()
					else
						self.noteHit:Fire(judgement)
					end
				end
			end
		)
	end

	-- Listen for mode changes
	self._game._mode_changed:Connect(function(mode)
		if mode == RobeatsGame.Mode.Game then
			self:_setState("playing")
			self.songStarted:Fire()
		elseif mode == RobeatsGame.Mode.GameEnded then
			self:_setState("finished")
			self.songFinished:Fire(self:getStats())

			local profile = Remotes.Functions.SubmitScore:InvokeServer(self:getStats(), {
				rate = Transient.song.rate:get(),
				hash = Transient.song.hash:get(),
				overallDifficulty = Options.OverallDifficulty:get(),
			})

			if profile then
				Transient.profile.playerRank:set("#" .. profile.rank)
				Transient.profile.playerRating:set(profile.rating)
			end
		end
	end)
end

function RobeatsGameWrapper:_calculateGrade(): string
	local accuracy = self._stats.accuracy

	if accuracy >= 100 then
		return "SS"
	elseif accuracy >= 95 then
		return "S"
	elseif accuracy >= 90 then
		return "A"
	elseif accuracy >= 80 then
		return "B"
	elseif accuracy >= 70 then
		return "C"
	elseif accuracy >= 60 then
		return "D"
	else
		return "F"
	end
end

function RobeatsGameWrapper:_resetStats()
	self._stats = {
		score = 0,
		accuracy = 100,
		combo = 0,
		maxCombo = 0,
		marvelous = 0,
		perfect = 0,
		great = 0,
		good = 0,
		bad = 0,
		miss = 0,
		totalNotes = 0,
		notesHit = 0,
		grade = "F",
		rating = 0,
		hits = {},
		mean = 0,
	}
end

-- Public API

function RobeatsGameWrapper:loadSong(config: GameConfig)
	if self._state ~= "idle" then
		warn("[RobeatsGameWrapper] Cannot load song while game is active. Call stop() first.")
		return false
	end

	self:_setState("loading")
	self:_resetStats()

	-- Store minimal config
	self._config = config

	-- Create game instance - no config needed, it reads from Options
	self._game = RobeatsGame.new(EnvironmentSetup:get_game_environment_center_position())

	-- Load the song - reduced parameters
	local replay = config.replay
	if not replay and config.recordReplay then
		replay = Replay:new({ viewing = false })
	end

	self._game:load(config.songKey, config.gameSlot or 0, replay)

	-- Setup event listeners
	self:_setupEventListeners()

	-- Count total notes
	local songData = SongDatabase:GetSongByKey(config.songKey)
	local folderName = songData.FolderName

	local hitObjects = SongDatabase:GetHitObjectsForFolderName(folderName)

	if songData and hitObjects then
		self._stats.totalNotes = #hitObjects
	end

	self:_setState("ready")
	return true
end

function RobeatsGameWrapper:start()
	if self._state ~= "ready" then
		warn("[RobeatsGameWrapper] Cannot start song - game not ready. Call loadSong() first.")
		return false
	end

	if not self._game then
		warn("[RobeatsGameWrapper] No game instance found.")
		return false
	end

	-- Hide core GUI elements during gameplay
	StarterGui:SetCoreGuiEnabled("PlayerList", false)
	StarterGui:SetCoreGuiEnabled("Chat", false)

	-- Start the game
	self._startTime = tick()
	self._game:start_game()

	-- Setup update loop
	self._updateConnection = RunService.Heartbeat:Connect(function(dt: number)
		if self._game and (self._state :: string) == "playing" then
			local dt_scale = CurveUtil:DeltaTimeToTimescale(dt)
			self._game:update(dt_scale)

			self.updated:Fire(dt_scale, self:getCurrentTime(), self:getSongLength(), self:getProgress())
		end
	end)

	return true
end

function RobeatsGameWrapper:pause()
	if self._state ~= "playing" then
		return false
	end

	self:_setState("paused")

	if self._game and self._game._audio_manager then
		self._game._audio_manager:pause()
	end

	return true
end

function RobeatsGameWrapper:resume()
	if self._state ~= "paused" then
		return false
	end

	self:_setState("playing")

	if self._game and self._game._audio_manager then
		self._game._audio_manager:resume()
	end

	return true
end

function RobeatsGameWrapper:stop()
	if self._state == "idle" then
		return false
	end

	-- Disconnect update loop
	if self._updateConnection then
		self._updateConnection:Disconnect()
		self._updateConnection = nil :: any
	end

	-- Teardown game
	if self._game then
		self._game:teardown()
		self._game = nil :: any
	end

	-- Restore core GUI
	StarterGui:SetCoreGuiEnabled("PlayerList", true)
	StarterGui:SetCoreGuiEnabled("Chat", true)

	self:_setState("idle")
	return true
end

-- Getters

function RobeatsGameWrapper:getState(): GameState
	return self._state
end

function RobeatsGameWrapper:getStats(): GameStats
	self._stats.grade = self:_calculateGrade()
	return table.clone(self._stats)
end

function RobeatsGameWrapper:getCurrentTime(): number
	if self._game and self._game._audio_manager then
		return (self._game._audio_manager:get_current_time_ms() :: any) / 1000 -- Convert to seconds
	end
	return 0
end

function RobeatsGameWrapper:getSongLength(): number
	if self._game and self._game._audio_manager then
		return (self._game._audio_manager:get_song_length_ms() :: any) / 1000 -- Convert to seconds
	end
	return 0
end

function RobeatsGameWrapper:getProgress(): number
	local length = self:getSongLength()
	if length > 0 then
		return (self:getCurrentTime() :: any) / length
	end
	return 0
end

function RobeatsGameWrapper:isPlaying(): boolean
	return self._state == "playing"
end

function RobeatsGameWrapper:isPaused(): boolean
	return self._state == "paused"
end

function RobeatsGameWrapper:isFinished(): boolean
	return self._state == "finished"
end

-- Settings updates
-- Volume settings are now handled automatically through the Options system.
-- Update Options.MusicVolume and Options.HitsoundVolume directly to change volumes.

function RobeatsGameWrapper:getReplay(): any?
	if self._game then
		return self._game:get_replay_hits()
	end
	return nil
end

-- Cleanup
function RobeatsGameWrapper:destroy()
	self:stop()

	-- Disconnect all events
	self.stateChanged:DisconnectAll()
	self.songStarted:DisconnectAll()
	self.songFinished:DisconnectAll()
	self.noteHit:DisconnectAll()
	self.noteMissed:DisconnectAll()
	self.scoreChanged:DisconnectAll()
	self.updated:DisconnectAll()
end

return RobeatsGameWrapper
