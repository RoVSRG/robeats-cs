local Iris = require(game.ReplicatedStorage.Libraries.Iris)

local SongDatabase = require(game.ReplicatedStorage.SongDatabase)

local Transient = require(game.ReplicatedStorage.State.Transient)

local function songEditor()
	local key = Transient.song.selected:get()
	local song = SongDatabase:GetSongByKey(key)

	Iris.Window({ "Developer Settings" })
	do
		Iris.Text({ song.Title })
	end
	Iris.End()
end

return songEditor
