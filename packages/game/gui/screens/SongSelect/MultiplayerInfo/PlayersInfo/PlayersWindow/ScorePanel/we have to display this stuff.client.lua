local Game = require(game.ReplicatedStorage.State.Game)
local Transient = require(game.ReplicatedStorage.State.Transient)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local Color = require(game.ReplicatedStorage.Shared.Color)
local Rating = require(game.ReplicatedStorage.Calculator.Rating)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)

local ScorePanel = script.Parent

local function constructHitGraph(song, hits)
	local hit_window = ScorePanel.HitWindow

	hit_window.Objects:ClearAllChildren()
	for _, hit in pairs(hits) do
		local pix = Instance.new("Frame")
		local x = hit.hit_object_time / (song.Length / (Transient.song.rate:get() / 100))
		pix.BackgroundColor3 = NoteResult:result_to_color(hit.judgement)
		pix.BorderSizePixel = 0

		if hit.judgement == 0 then
			pix.Size = UDim2.fromOffset(1, 100)
			pix.Position = UDim2.fromScale(x, 0)
			pix.BackgroundTransparency = 0.55 -- red lines gotta be a little dimmmmmmmmmmmmmmmmmmer
		else
			local y = SPUtil:inverse_lerp(180, -180, hit.time_left)
			pix.Size = UDim2.fromOffset(2, 2)
			pix.Position = UDim2.fromScale(x, y)
		end
		pix.Parent = hit_window.Objects
	end
end

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
	F = "http://www.roblox.com/asset/?id=168702873",
}

Game.results.score:on(function(score)
	local songKey = Transient.song.selected:get()
	local song = SongDatabase:GetSongByKey(songKey)

	ScorePanel.PlayRating.Text = string.format("Rating: %0.2f", score.rating)
	ScorePanel.PlayRating.TextColor3 = Color.calculateDifficultyColor(score.rating)
	
	ScorePanel.PlayRating.Rainbow.Value = Rating.isRainbow(score.rating)

	ScorePanel.Accuracy.Text = string.format("Accuracy: %0.2f [%s]", score.accuracy, score.grade)
	ScorePanel.AvgOffset.Text = string.format("Avg. Offset: %0.1f ms", score.mean)
	ScorePanel.GradeImage.Image = GradeIconMap[score.grade]
	ScorePanel.Spread.RichText = true
	ScorePanel.Score.Text = string.format("Score: %d", score.score)
	ScorePanel.Spread.Text = Color.getSpreadRichText(score.marvelous, score.perfect, score.great, score.good, score.bad, score.miss)
	ScorePanel.UnstableRate.Text = string.format("Unstable Rate: %0.2f", 0)
	ScorePanel.MaxCombo.Text = string.format("Max Combo: %d", score.maxCombo)
	ScorePanel.PlayTitle.Text = song.SongName .. " - " .. song.ArtistName
	ScorePanel.PlayerName.Text = game.Players.LocalPlayer.Name .. "'s Play Stats"
	
	constructHitGraph(song, score.hits)
end)

ScorePanel.Activated:Connect(function()
	Game.results.open:set(false)
end)
