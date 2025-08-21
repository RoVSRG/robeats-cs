local Iris = require(game.ReplicatedStorage.Libraries.Iris)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local Transient = require(game.ReplicatedStorage.State.Transient)

-- Module exposes a persistent window with a controllable open state.
local M = {}

-- Persistent state controlling visibility of the Song Editor window.
local openState = Iris.State(false) -- starts closed until explicitly opened

function M.open()
	openState:set(true)
end

function M.close()
	openState:set(false)
end

-- Draw the window each Iris cycle; supply custom isOpened state so external triggers can reopen it.
function M.draw()
	local key = Transient.song.selected:get()
	local song = SongDatabase:GetSongByKey(key)

	local window = Iris.Window({ "Developer Settings" }, { isOpened = openState })
	do
		Iris.Text({ string.format("Selected: %s", tostring(key)) })
		if song then
			Iris.Text({ string.format("Title: %s", song.Title or "<unknown>") })
		end
	end
	Iris.End()
	return window
end

return M
