--[[
	GameStats - Single source of truth for gameplay statistics

	Uses Val-based reactive state that UI components can subscribe to directly.
	The engine calls recordHit() to update stats, and UI auto-updates via Val subscriptions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Val = require(ReplicatedStorage.Libraries.Val)
local NoteResult = require(ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local Grade = require(ReplicatedStorage.RobeatsGameCore.Enums.Grade)
local Rating = require(ReplicatedStorage.Calculator.Rating)
local Transient = require(ReplicatedStorage.State.Transient)
local SongDatabase = require(ReplicatedStorage.SongDatabase)

local GameStats = {}

-- Point values for each judgement
local POINT_VALUES = {
	[NoteResult.Miss] = 0,
	[NoteResult.Bad] = 50,
	[NoteResult.Good] = 100,
	[NoteResult.Great] = 200,
	[NoteResult.Perfect] = 300,
	[NoteResult.Marvelous] = 375,
}

-- Accuracy weights for each judgement
local ACCURACY_WEIGHTS = {
	[NoteResult.Marvelous] = 1.0,
	[NoteResult.Perfect] = 1.0,
	[NoteResult.Great] = 0.75,
	[NoteResult.Good] = 0.37,
	[NoteResult.Bad] = 0.25,
	[NoteResult.Miss] = 0,
}

----------------------------------------------------------------
-- REACTIVE STATE (Val-wrapped)
----------------------------------------------------------------

-- Core stats
GameStats.score = Val.new(0)
GameStats.combo = Val.new(0)
GameStats.maxCombo = Val.new(0)

-- Judgement counts
GameStats.marvelous = Val.new(0)
GameStats.perfect = Val.new(0)
GameStats.great = Val.new(0)
GameStats.good = Val.new(0)
GameStats.bad = Val.new(0)
GameStats.miss = Val.new(0)
GameStats.ghostTaps = Val.new(0)

-- Hit data
GameStats.hits = Val.new({})
GameStats.totalNotes = Val.new(0)

-- Mean timing (for hit deviation display)
local _meanSum = 0
local _meanCount = 0
GameStats.mean = Val.new(0)

----------------------------------------------------------------
-- COMPUTED VALUES (auto-update when dependencies change)
----------------------------------------------------------------

-- Total successful hits (excludes misses)
GameStats.notesHit = Val.calc(function(get)
	return get(GameStats.marvelous)
		+ get(GameStats.perfect)
		+ get(GameStats.great)
		+ get(GameStats.good)
		+ get(GameStats.bad)
end)

-- Accuracy percentage (0-100)
GameStats.accuracy = Val.calc(function(get)
	local total = get(GameStats.notesHit) + get(GameStats.miss)

	if total == 0 then
		return 0
	end

	local weighted = (get(GameStats.marvelous) * ACCURACY_WEIGHTS[NoteResult.Marvelous])
		+ (get(GameStats.perfect) * ACCURACY_WEIGHTS[NoteResult.Perfect])
		+ (get(GameStats.great) * ACCURACY_WEIGHTS[NoteResult.Great])
		+ (get(GameStats.good) * ACCURACY_WEIGHTS[NoteResult.Good])
		+ (get(GameStats.bad) * ACCURACY_WEIGHTS[NoteResult.Bad])

	return (weighted / total) * 100
end)

-- Grade (SS, S, A, B, C, D, F)
GameStats.grade = Val.calc(function(get)
	local acc = get(GameStats.accuracy)
	local _, gradeName = Grade:get_grade_from_accuracy(acc)
	return gradeName or "F"
end)

-- Play rating (based on accuracy, rate, and song difficulty)
GameStats.rating = Val.calc(function(get)
	local acc = get(GameStats.accuracy)
	local rate = Transient.song.rate:get() / 100
	local songKey = Transient.song.selected:get()

	if not songKey then
		return 0
	end

	local difficulty = SongDatabase:GetPropertyByKey(songKey, "Difficulty") or 0
	return Rating.calculateRating(rate, acc, difficulty)
end)

----------------------------------------------------------------
-- ADAPTER METHODS
----------------------------------------------------------------

--[[
	Record a hit result from the engine.

	@param noteResult - The judgement (NoteResult enum)
	@param params - Hit parameters (GhostTap, TimeMiss, etc.)
	@param renderableHit - Optional hit data for timing display
]]
function GameStats.recordHit(
	noteResult: number,
	params: { GhostTap: boolean?, TimeMiss: boolean? }?,
	renderableHit: any?
)
	params = params or {}

	Val.batch(function(set)
		local currentCombo = GameStats.combo:get()

		-- Update judgement counts and combo
		if noteResult == NoteResult.Marvelous then
			set(GameStats.marvelous, GameStats.marvelous:get() + 1)
			set(GameStats.combo, currentCombo + 1)
		elseif noteResult == NoteResult.Perfect then
			set(GameStats.perfect, GameStats.perfect:get() + 1)
			set(GameStats.combo, currentCombo + 1)
		elseif noteResult == NoteResult.Great then
			set(GameStats.great, GameStats.great:get() + 1)
			set(GameStats.combo, currentCombo + 1)
		elseif noteResult == NoteResult.Good then
			set(GameStats.good, GameStats.good:get() + 1)
			-- Good does NOT increment combo
		elseif noteResult == NoteResult.Bad then
			set(GameStats.bad, GameStats.bad:get() + 1)
			set(GameStats.combo, 0) -- Bad breaks combo
		elseif noteResult == NoteResult.Miss then
			if (params :: any).GhostTap then
				set(GameStats.ghostTaps, GameStats.ghostTaps:get() + 1)
			else
				set(GameStats.miss, GameStats.miss:get() + 1)
				set(GameStats.combo, 0) -- Miss breaks combo
			end
		end

		-- Update max combo
		local newCombo = GameStats.combo:get()
		if newCombo > GameStats.maxCombo:get() then
			set(GameStats.maxCombo, newCombo)
		end

		-- Update score
		local points = POINT_VALUES[noteResult] or 0
		set(GameStats.score, GameStats.score:get() + points)

		-- Track hit timing for mean calculation
		if renderableHit then
			local hits = GameStats.hits:get()
			local newHits = table.clone(hits)
			table.insert(newHits, renderableHit)
			set(GameStats.hits, newHits)

			-- Update mean timing
			if renderableHit.judgement ~= NoteResult.Miss and renderableHit.time_left then
				_meanSum += renderableHit.time_left
				_meanCount += 1
				set(GameStats.mean, _meanSum / _meanCount)
			end
		end
	end)
end

--[[
	Reset all stats for a new game.
]]
function GameStats.reset()
	_meanSum = 0
	_meanCount = 0

	Val.batch(function(set)
		set(GameStats.accuracy, 0)
		set(GameStats.score, 0)
		set(GameStats.combo, 0)
		set(GameStats.maxCombo, 0)
		set(GameStats.marvelous, 0)
		set(GameStats.perfect, 0)
		set(GameStats.great, 0)
		set(GameStats.good, 0)
		set(GameStats.bad, 0)
		set(GameStats.miss, 0)
		set(GameStats.ghostTaps, 0)
		set(GameStats.hits, {})
		set(GameStats.totalNotes, 0)
		set(GameStats.mean, 0)
	end)
end

--[[
	Set the total number of notes in the current song.
]]
function GameStats.setTotalNotes(count: number)
	GameStats.totalNotes:set(count)
end

--[[
	Get a snapshot of current stats as a plain table.
	Used for Game.results and score submission.
]]
function GameStats.getResults(): {
	score: number,
	accuracy: number,
	rating: number,
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
	mean: number,
	hits: { any },
}
	return {
		score = GameStats.score:get(),
		accuracy = GameStats.accuracy:get(),
		rating = GameStats.rating:get(),
		combo = GameStats.combo:get(),
		maxCombo = GameStats.maxCombo:get(),
		marvelous = GameStats.marvelous:get(),
		perfect = GameStats.perfect:get(),
		great = GameStats.great:get(),
		good = GameStats.good:get(),
		bad = GameStats.bad:get(),
		miss = GameStats.miss:get(),
		totalNotes = GameStats.totalNotes:get(),
		notesHit = GameStats.notesHit:get(),
		grade = GameStats.grade:get(),
		mean = GameStats.mean:get(),
		hits = GameStats.hits:get(),
	}
end

--[[
	Get end records in the format expected by replays/server.
	Matches the old ScoreManager:get_end_records() format.
]]
function GameStats.getEndRecords(): {
	Score: number,
	Marvelouses: number,
	Perfects: number,
	Greats: number,
	Goods: number,
	Bads: number,
	Misses: number,
	MaxChain: number,
	Chain: number,
	Accuracy: number,
}
	return {
		Score = GameStats.score:get(),
		Marvelouses = GameStats.marvelous:get(),
		Perfects = GameStats.perfect:get(),
		Greats = GameStats.great:get(),
		Goods = GameStats.good:get(),
		Bads = GameStats.bad:get(),
		Misses = GameStats.miss:get(),
		MaxChain = GameStats.maxCombo:get(),
		Chain = GameStats.combo:get(),
		Accuracy = GameStats.accuracy:get(),
	}
end

return GameStats
