local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local Rating = require(game.ReplicatedStorage.Calculator.Rating)
local Color = require(game.ReplicatedStorage.Shared.Color)
local Time = require(game.ReplicatedStorage.Libraries.Time)

local Transient = require(game.ReplicatedStorage.State.Transient)
local node = script.Parent

local song = Transient.song

local RateSelector = script.Parent.RateSelector

local RAINBOW_MIN = 56

local function refreshSongPanel()
	local selected = song.selected:get()
	local rate = song.rate:get()
	
	local data = SongDatabase:GetSongByKey(selected)
	
	local nameFormatted = string.format("[#%d] %s - %s", data.ID, data.ArtistName or "???", data.SongName or "???")
	node.SongNameInfo.Text = nameFormatted
	
	RateSelector.RateInfo.Text = string.format("Song Rate: %0.2fx", rate / 100)
	
	local difficulty = Rating.getDifficultyMultiplier(rate / 100) * data.Difficulty
	
	-- Max rating (placeholder: maybe based on difficulty * some multiplier?)
	local maxRating = Rating.calculateRating(rate / 100, 100, data.Difficulty)
	node.MaxRating.Text = string.format("Max Rating: %.2f", maxRating)
	node.SongDiffInfo.Text = string.format("Difficulty: %0.2f", difficulty)
	node.SongDiffInfo.Rainbow.Value = Rating.isRainbow(difficulty)
	node.MaxRating.Rainbow.Value = Rating.isRainbow(maxRating)

	if not Rating.isRainbow(difficulty) then
		node.SongDiffInfo.TextColor3 = Color.calculateDifficultyColor(difficulty / RAINBOW_MIN)
	end
	
	if not Rating.isRainbow(maxRating) then
		node.MaxRating.TextColor3 = Color.calculateDifficultyColor(maxRating / RAINBOW_MIN)
	end

	-- Map Length
	node.SongLengthInfo.Text = "Map Length: unknown"
	if data.Length then
		node.SongLengthInfo.Text = string.format("Map Length: %s", Time.formatDuration(data.Length / (rate / 100)))
	end
end

local MAX_RATE = 200
local MIN_RATE = 70

RateSelector.Add.Activated:Connect(function()
	if song.rate:get() >= MAX_RATE then
		return
	end
	
	song.rate:add(5)
end)

RateSelector.Subtract.Activated:Connect(function()
	if song.rate:get() <= MIN_RATE then
		return
	end
	
	song.rate:sub(5)
end)

song.rate:on(refreshSongPanel)
song.selected:on(refreshSongPanel)

--refreshSongPanel(active:get())
--refreshSongPanel(selectedSongKey:get())