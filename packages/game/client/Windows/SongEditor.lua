local Iris = require(game.ReplicatedStorage.Libraries.Iris)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local Transient = require(game.ReplicatedStorage.State.Transient)

while not SongDatabase.IsLoaded do
	wait()
end

local Development = game.ReplicatedStorage.Remotes.Development

-- Module exposes a persistent window with a controllable open state.
local M = {}

-- Persistent state controlling visibility of the Song Editor window.
local openState = Iris.State(false) -- starts closed until explicitly opened
local songData = Iris.State(nil) -- holds the currently selected song data

Transient.song.selected:on(function(key)
	songData:set(SongDatabase:GetSongByKey(key))
end)

Transient.song.selected:set(Transient.song.selected:get(), true)

function M.open()
	openState:set(true)
end

function M.close()
	openState:set(false)
end

-- Draw the window each Iris cycle; supply custom isOpened state so external triggers can reopen it.
function M.draw()
	local window = Iris.Window({ "Developer Settings" }, { isOpened = openState })
	do
		local data = songData:get()

		if not data then
			Iris.Text({ "No song selected" })
			Iris.End()
			return
		end

		local audioId = Iris.State("")

		Iris.SeparatorText({ "Song Information" })

		Iris.Text({ string.format("Selected: %s", data.FolderName) })
		Iris.Text({ string.format("Audio ID: %s", data.AudioID) })
		Iris.InputText({ "Audio ID" }, { text = audioId })
		Iris.Text({ string.format("Volume: %d%%", data.Volume * 100) })

		if Iris.Button({ "Apply Changes to This Song" }).clicked() then
			Development.SaveSongChanges:FireServer({
				AudioId = audioId:get(),
				Volume = data.Volume,
			})
		end
	end
	Iris.End()
	return window
end

return M
