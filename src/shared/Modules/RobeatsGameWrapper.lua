--!strict
-- RobeatsGameWrapper: A high-level wrapper around RobeatsGame for external scripts
-- Provides a clean, camelCase API for managing song playback and game lifecycle

local RobeatsGame = require(game.ReplicatedStorage.RobeatsGameCore.RobeatsGame)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local Replay = require(game.ReplicatedStorage.RobeatsGameCore.Replay)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local Signal = require(game.ReplicatedStorage.Libraries.LemonSignal)

local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Types
export type GameConfig = {
	-- Song Settings
	songKey: string | number,
	songRate: number?,
	audioOffset: number?,
	
	-- Gameplay Settings
	noteSpeed: number?,
	timingPreset: string?,
	mods: {string}?,
	
	-- Visual Settings
	use2DMode: boolean?,
	skin2D: string?,
	upscroll: boolean?,
	noteColor: Color3?,
	noteColorAffects2D: boolean?,
	
	-- Effects Settings
	hideReceptorGlow: boolean?,
	receptorTransparency: number?,
	lnTransparency: boolean?,
	hideLnTails: boolean?,
	showHitLighting: boolean?,
	
	-- Judgement Visibility
	judgementVisibility: {
		marvelous: boolean?,
		perfect: boolean?,
		great: boolean?,
		good: boolean?,
		bad: boolean?,
		miss: boolean?,
	}?,
	
	-- Audio Settings
	hitsounds: boolean?,
	hitsoundVolume: number?,
	musicVolume: number?,
	
	-- Advanced Settings
	startTimeMs: number?,
	gameSlot: number?,
	environmentPosition: Vector3?,
	
	-- Replay Settings
	replay: any?,
	recordReplay: boolean?,
}

export type GameStats = {
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
}

export type GameState = "idle" | "loading" | "ready" | "playing" | "paused" | "finished"

-- Default configuration values
local DEFAULT_CONFIG = {
	songRate = 1,
	audioOffset = 0,
	noteSpeed = 2000,
	timingPreset = "Default",
	mods = {},
	use2DMode = false,
	upscroll = false,
	noteColor = Color3.fromRGB(255, 175, 0),
	noteColorAffects2D = true,
	hideReceptorGlow = false,
	receptorTransparency = 0,
	lnTransparency = false,
	hideLnTails = false,
	showHitLighting = true,
	judgementVisibility = {
		marvelous = true,
		perfect = true,
		great = true,
		good = true,
		bad = true,
		miss = true,
	},
	hitsounds = true,
	hitsoundVolume = 0.5,
	musicVolume = 0.5,
	startTimeMs = 0,
	gameSlot = 0,
	environmentPosition = Vector3.new(0, 0, 0),
	recordReplay = false,
}

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
	self.comboChanged = Signal.new() :: any
	self.scoreChanged = Signal.new() :: any
	
	-- Statistics tracking
	self._stats = {
		score = 0,
		accuracy = 0,
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
	} :: GameStats
	
	return self
end

function RobeatsGameWrapper:_setState(newState: GameState)
	if self._state ~= newState then
		local oldState = self._state
		self._state = newState
		self.stateChanged:Fire(newState, oldState)
	end
end

function RobeatsGameWrapper:_mergeConfig(userConfig: GameConfig): GameConfig
	local config = table.clone(DEFAULT_CONFIG)
	
	-- Merge user config
	for key, value in pairs(userConfig) do
		if key == "judgementVisibility" and type(value) == "table" then
			config.judgementVisibility = table.clone(DEFAULT_CONFIG.judgementVisibility)
			for judge, visible in pairs(value) do
				config.judgementVisibility[judge] = visible
			end
		else
			config[key] = value
		end
	end
	
	return config
end

function RobeatsGameWrapper:_buildRobeatsConfig(config: GameConfig)
	-- Convert our clean config to RobeatsGame's expected format
	local visibility = config.judgementVisibility or DEFAULT_CONFIG.judgementVisibility
	local judgementMap = {
		[NoteResult.Marvelous] = visibility.marvelous,
		[NoteResult.Perfect] = visibility.perfect,
		[NoteResult.Great] = visibility.great,
		[NoteResult.Good] = visibility.good,
		[NoteResult.Bad] = visibility.bad,
		[NoteResult.Miss] = visibility.miss,
	}
	
	return {
		-- Song settings
		SongRate = config.songRate,
		AudioOffset = config.audioOffset,
		
		-- Gameplay settings
		NoteSpeed = config.noteSpeed,
		TimingPreset = config.timingPreset,
		Mods = config.mods,
		
		-- Visual settings
		Use2DLane = config.use2DMode,
		Skin2D = config.skin2D,
		NoteColorAffects2D = config.noteColorAffects2D,
		
		-- Audio settings
		Hitsounds = config.hitsounds,
		HitsoundVolume = config.hitsoundVolume,
		MusicVolume = config.musicVolume,
		
		-- Other internal settings
		JudgementVisibility = judgementMap,
	}
end

function RobeatsGameWrapper:_setupEventListeners()
	if not self._game then return end
	
	-- Connect to score manager events
	local scoreManager = self._game._score_manager
	if scoreManager then
		-- Listen for score changes
		scoreManager.score_changed:Connect(function(score: number)
			self._stats.score = score
			self.scoreChanged:Fire(score)
		end)
		
		-- Listen for combo changes
		scoreManager.combo_changed:Connect(function(combo: number)
			self._stats.combo = combo
			if combo > self._stats.maxCombo then
				self._stats.maxCombo = combo
			end
			self.comboChanged:Fire(combo)
		end)
		
		-- Listen for note hits
		scoreManager.note_hit:Connect(function(noteResult)
			self._stats.notesHit = (self._stats.notesHit :: number) + 1
			
			-- Update judgement counts
			if noteResult == NoteResult.Marvelous then
				self._stats.marvelous = (self._stats.marvelous :: number) + 1
			elseif noteResult == NoteResult.Perfect then
				self._stats.perfect = (self._stats.perfect :: number) + 1
			elseif noteResult == NoteResult.Great then
				self._stats.great = (self._stats.great :: number) + 1
			elseif noteResult == NoteResult.Good then
				self._stats.good = (self._stats.good :: number) + 1
			elseif noteResult == NoteResult.Bad then
				self._stats.bad = (self._stats.bad :: number) + 1
			elseif noteResult == NoteResult.Miss then
				self._stats.miss = (self._stats.miss :: number) + 1
				self.noteMissed:Fire()
			end
			
			if noteResult ~= NoteResult.Miss then
				self.noteHit:Fire(noteResult)
			end
			
			-- Update accuracy
			self:_updateAccuracy()
		end)
	end
	
	-- Listen for mode changes
	self._game._mode_changed:Connect(function(mode)
		if mode == RobeatsGame.Mode.Game then
			self:_setState("playing")
			self.songStarted:Fire()
		elseif mode == RobeatsGame.Mode.GameEnded then
			self:_setState("finished")
			self._stats.grade = self:_calculateGrade()
			self.songFinished:Fire(self:getStats())
		end
	end)
end

function RobeatsGameWrapper:_updateAccuracy()
    local stats = self._stats :: any

	local totalWeight = (stats.marvelous * 100) +
		(stats.perfect * 99) +
		(stats.great * 70) +
		(stats.good * 30) +
		(stats.bad * 5) +
		(stats.miss * 0)

	local maxWeight = stats.totalNotes * 100

	if maxWeight > 0 then
		stats.accuracy = (totalWeight / maxWeight) * 100
	else
		stats.accuracy = 100
	end
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
	
	-- Merge with defaults
	local finalConfig = self:_mergeConfig(config)
	self._config = finalConfig
	
	-- Create game instance
	self._game = RobeatsGame:new(
		finalConfig.environmentPosition,
		self:_buildRobeatsConfig(finalConfig)
	)
	
	-- Setup visual settings
	if finalConfig.use2DMode then
		self._game:set_2d_mode(true)
		self._game:set_upscroll_mode(finalConfig.upscroll)
	end
	
	self._game:set_note_color(finalConfig.noteColor)
	self._game:set_ln_transparent(finalConfig.lnTransparency)
	self._game:set_hit_lighting(finalConfig.showHitLighting)
	self._game:set_ln_tails(finalConfig.hideLnTails)
	
	-- Load the song
	local replay = finalConfig.replay
	if not replay and finalConfig.recordReplay then
		replay = Replay:new({ viewing = false })
	end
	
	self._game:load(
		finalConfig.songKey,
		finalConfig.gameSlot,
		self:_buildRobeatsConfig(finalConfig),
		replay
	)
	
	-- Setup event listeners
	self:_setupEventListeners()
	
	-- Count total notes
	local songData = SongDatabase:GetSongByKey(finalConfig.songKey)
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
	self._game:start_game(self._config.startTimeMs or 0)
	
	-- Setup update loop
	self._updateConnection = RunService.Heartbeat:Connect(function(dt: number)
		if self._game and (self._state :: string) == "playing" then
			self._game:update(dt * 60) -- Convert to dt_scale
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

-- Settings updates (only work during gameplay)

function RobeatsGameWrapper:setNoteSpeed(speed: number)
	if self._game then
		self._config.noteSpeed = speed
		-- This would need to be implemented in RobeatsGame
	end
end

function RobeatsGameWrapper:setVolume(musicVolume: number?, hitsoundVolume: number?)
	if self._game and self._game._audio_manager then
		if musicVolume then
			self._game._audio_manager:set_music_volume(musicVolume)
		end
		if hitsoundVolume and self._game._sfx_manager then
			self._game._sfx_manager:set_volume(hitsoundVolume)
		end
	end
end

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
	self.comboChanged:DisconnectAll()
	self.scoreChanged:DisconnectAll()
end

return RobeatsGameWrapper
