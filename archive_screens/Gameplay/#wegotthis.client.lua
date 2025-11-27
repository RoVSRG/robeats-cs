local MainGui = game.Players.LocalPlayer.PlayerGui:WaitForChild("Main")
local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local Game = require(game.ReplicatedStorage.State.Game)
local Time = require(game.ReplicatedStorage.Libraries.Time)
local Pfp = require(game.ReplicatedStorage.Shared.Pfp)
local Options = require(game.ReplicatedStorage.State.Options)

local Screen = script.Parent

local _game = nil

Screen.MAWindow.BackButton.MouseButton1Click:Connect(function()
	local game = Game.currentGame:get()

	Game.results.score:set(game:getStats())
	Game.results.open:set(true)

	game:destroy()

	ScreenChief:Switch("SongSelect")
end)

local logHistory = {}

local function onGameCreated()
	local Counters = Screen.MAWindow.Counters
	local CompeteScreen = Screen.CompeteScreen
	local LaneCover = Screen.LaneCover
	local Logs = Screen.LoadingScreen:FindFirstChild("Logs")

	local logTemplate = ScreenChief:GetTemplates("Gameplay"):FindFirstChild("LogItem")

	CompeteScreen.Player1.Visible = true
	CompeteScreen.Player1.Avatar.Image = Pfp.getPfp(game.Players.LocalPlayer.UserId)
	CompeteScreen.Player1.PlayerName.Text = game.Players.LocalPlayer.Name

	MainGui.IgnoreGuiInset = true

	local i = 0

	local function logToLoadingScreen(message: string)
		local log = logTemplate:Clone()
		log.Text = message
		log.Parent = Logs

		table.insert(logHistory, log)

		if #logHistory > 6 then
			local oldestLog = table.remove(logHistory, 1)
			oldestLog:Destroy()
		end

		for i, _ in ipairs(logHistory) do
			log.LayoutOrder = i
		end

		i += 1
	end

	Screen.LoadingScreen.Visible = true

	logToLoadingScreen("Game initializing")
	logToLoadingScreen("Loading audio... If audio is not loaded within 5 seconds, game will start anyway.")

	task.spawn(function()
		for i = 5, 1, -1 do
			logToLoadingScreen("Game starting in " .. i .. "...")
			task.wait(1)
		end
	end)

	local function constructLaneCover()
		if Options.LaneCoverEnabled:get() then
			LaneCover.Size = UDim2.fromScale(1, Options.LaneCoverPct:get() / 100)
			LaneCover.Visible = true
		else
			LaneCover.Visible = false
		end
	end

	local function updateCompeteScreen(score, accuracy, combo)
		CompeteScreen.Player1.Score.Text = string.format("%d | %0.2f%%", score, accuracy)
		CompeteScreen.Player1.Combo.Text = combo .. "x"
	end

	local function updateMAWindow(score)
		Counters.Accuracy.Text = string.format("%0.2f%%", score.accuracy)
		Counters.Marvelous.Text = score.marvelous
		Counters.Perfect.Text = score.perfect
		Counters.Great.Text = score.great
		Counters.Good.Text = score.good
		Counters.Bad.Text = score.bad
		Counters.Miss.Text = score.miss

		local total = score.notesHit + score.miss

		Counters.Marvelous.graph.Size = UDim2.fromScale(score.marvelous / total, 1)
		Counters.Perfect.graph.Size = UDim2.fromScale(score.perfect / total, 1)
		Counters.Great.graph.Size = UDim2.fromScale(score.great / total, 1)
		Counters.Good.graph.Size = UDim2.fromScale(score.good / total, 1)
		Counters.Bad.graph.Size = UDim2.fromScale(score.bad / total, 1)
		Counters.Miss.graph.Size = UDim2.fromScale(score.miss / total, 1)

		updateCompeteScreen(score.score, score.accuracy, score.combo)
	end

	constructLaneCover()
	updateCompeteScreen(0, 0, 0)
	updateMAWindow({
		accuracy = 0,
		marvelous = 0,
		perfect = 0,
		great = 0,
		good = 0,
		bad = 0,
		miss = 0,
		score = 0,
		combo = 0,
		notesHit = 0,
	})

	_game.scoreChanged:Connect(updateMAWindow)

	_game.updated:Connect(function(_, currentTime, songLength, progress)
		Screen.TimeBar.PosBar.Size = UDim2.fromScale(progress, 1)
		Screen.TimeBar.PosText.Text = Time.formatDuration((songLength - currentTime) * 1000)
	end)

	_game.songFinished:Connect(function(score)
		_game:destroy()

		Game.results.score:set(score)
		Game.results.open:set(true)

		MainGui.IgnoreGuiInset = false
		ScreenChief:Switch("SongSelect")
	end)

	_game.loaded:Connect(function()
		Screen.LoadingScreen.Visible = false
	end)
end

Game.currentGame:on(function(value)
	if not value then
		return
	end

	_game = value
	onGameCreated()
end)
