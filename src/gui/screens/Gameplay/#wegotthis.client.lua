local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local Game = require(game.ReplicatedStorage.State.Game)
local Time = require(game.ReplicatedStorage.Libraries.Time)

local Screen = script.Parent

local _game = nil

Screen.MAWindow.BackButton.MouseButton1Click:Connect(function()
	local game = Game.currentGame:get()
	
	game:destroy()
	
	ScreenChief:Switch("SongSelect")
end)

local function onGameCreated()
	local Counters = Screen.MAWindow.Counters
	
	_game.scoreChanged:Connect(function(score)
		Counters.Accuracy.Text = string.format("%0.2f%%", score.accuracy)
		Counters.Marvelous.Text = score.marvelous
		Counters.Perfect.Text = score.perfect
		Counters.Great.Text = score.great
		Counters.Good.Text = score.good
		Counters.Bad.Text = score.bad
		Counters.Miss.Text = score.miss
	end)
	
	_game.updated:Connect(function(_, currentTime, songLength, progress)
		Screen.TimeBar.PosBar.Size = UDim2.fromScale(progress, 1)
		Screen.TimeBar.PosText.Text = Time.formatDuration((songLength - currentTime) * 1000)
	end)
	
	_game.songFinished:Connect(function(score)
		_game:destroy()
		
		Game.results.score:set(score)
		Game.results.open:set(true)
		
		ScreenChief:Switch("SongSelect")
	end)
end

Game.currentGame:on(function(value)
	if not value then
		return
	end
	
	_game = value
	onGameCreated()
end)