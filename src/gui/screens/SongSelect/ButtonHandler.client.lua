local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local Transient = require(game.ReplicatedStorage.State.Transient)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local RobeatsGameWrapper = require(game.ReplicatedStorage.Modules.RobeatsGameWrapper)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)

local Transient = require(game.ReplicatedStorage.State.Transient)
local Game = require(game.ReplicatedStorage.State.Game)

local selectedSongKey = Transient.selectedSongKey

local Screen = script.Parent

Screen.BackButton.MouseButton1Click:Connect(function()
	ScreenChief:Switch("MainMenu")
end)

Screen.PlayButton.MouseButton1Click:Connect(function()
	ScreenChief:Switch("Gameplay")

	--local key = selectedSongKey:get()
	
	local _game = RobeatsGameWrapper.new()
	Game.currentGame:set(_game)
	
	_game:loadSong({
		songKey = Transient.song.selected:get()
	})
	_game:start()
end)

SPUtil:attach_sound(Screen.PlayButton, "Select")