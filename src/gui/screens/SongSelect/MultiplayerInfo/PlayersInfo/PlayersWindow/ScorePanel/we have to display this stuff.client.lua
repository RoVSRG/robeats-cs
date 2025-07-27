local Game = require(game.ReplicatedStorage.State.Game)
local Transient = require(game.ReplicatedStorage.State.Transient)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local Color = require(game.ReplicatedStorage.Shared.Color)
local Rating = require(game.ReplicatedStorage.Calculator.Rating)
local ScorePanel = script.Parent

Game.results.open:on(function(value)
	ScorePanel.Visible = value
end)
Game.results.open:set(Game.results.open:get(), true)

local GradeIconMap = {
	SS = "http://www.roblox.com/asset/?id=5702584062",
	S = "http://www.roblox.com/asset/?id=5702584273",
	A = "http://www.roblox.com/asset/?id=5702584488",
	B = "http://www.roblox.com/asset/?id=5702584846",
	C = "http://www.roblox.com/asset/?id=5702585057",
	D = "http://www.roblox.com/asset/?id=5702585272",
	F = "http://www.roblox.com/asset/?id=168702873"
} 

Game.results.score:on(function(score)
	local songKey = Transient.song.selected:get()
	local song = SongDatabase:GetSongByKey(songKey)
	
	ScorePanel.PlayRating.Text = string.format("Rating: %0.2f", score.rating)
	ScorePanel.PlayRating.TextColor3 = Color.calculateDifficultyColor(score.rating / Rating.getRainbowRating())
	
	ScorePanel.PlayRating.Rainbow.Value = Rating.isRainbow(score.rating)
	
	ScorePanel.Accuracy.Text = string.format("Accuracy: %0.2f [%s]", score.accuracy, score.grade)
	ScorePanel.GradeImage.Image = GradeIconMap[score.grade]
	ScorePanel.Score.Text = string.format("Score: %d", score.score)
	ScorePanel.Spread.Text = string.format("Spread: %d / %d / %d / %d / %d / %d",
		score.marvelous,
		score.perfect,
		score.great,
		score.good,
		score.bad,
		score.miss
	)
	ScorePanel.UnstableRate.Text = string.format("Unstable Rate: %0.2f", 0)
	ScorePanel.MaxCombo.Text = string.format("Max Combo: %d", score.maxCombo)
	ScorePanel.PlayTitle.Text = song.SongName .. " - " .. song.ArtistName
	ScorePanel.PlayerName.Text = game.Players.LocalPlayer.Name .. "'s Play Stats"
end)

ScorePanel.Activated:Connect(function()	
	Game.results.open:set(false)
end)