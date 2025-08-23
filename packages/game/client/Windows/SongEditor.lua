local Iris = require(game.ReplicatedStorage.Libraries.Iris)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local Transient = require(game.ReplicatedStorage.State.Transient)

while not SongDatabase.IsLoaded do
	wait()
end

local Development = game.ReplicatedStorage.Remotes.Development

-- Module exposes a persistent window with a controllable open state.
local SongEditor = {}

-- Persistent state controlling visibility of the Song Editor window.
local openState = Iris.State(false) -- starts closed until explicitly opened
local songData = Iris.State(nil) -- holds the currently selected song data
local fieldStates = Iris.State(nil) -- table of Iris.State per editable field
local lastSongHash = Iris.State(nil) -- track last loaded song to refresh fields

local EDITABLE_FIELDS = {
	{ key = "ArtistName", attr = "Artist" }, -- in-game attribute -> YAML key mapping comment
	{ key = "SongName", attr = "Filename" },
	{ key = "CharterName", attr = "Mapper" },
	{ key = "Description", attr = "Description" },
	{ key = "AudioID", attr = "AssetId" },
	{ key = "CoverImageAssetId", attr = "CoverImageAssetId" },
	{ key = "Volume", attr = "Volume", kind = "number", min = 0, max = 2, step = 0.01 },
	{ key = "HitSFXGroup", attr = "HitSFXGroup", kind = "number", min = 0, max = 10, step = 1 },
	{ key = "TimeOffset", attr = "TimeOffset", kind = "number", min = -1000, max = 1000, step = 10 },
}

local function initFieldStates(song)
	local map = {}
	for _, def in ipairs(EDITABLE_FIELDS) do
		local v = song[def.key]
		map[def.key] = Iris.State(v)
	end
	return map
end

Transient.song.selected:on(function(key)
	local s = SongDatabase:GetSongByKey(key)
	songData:set(s)
	-- Defer field state refresh to draw() so we can detect changes centrally.
end)

Transient.song.selected:set(Transient.song.selected:get(), true)

function SongEditor.open()
	openState:set(true)
end

function SongEditor.close()
	openState:set(false)
end

function SongEditor.draw()
	local window = Iris.Window({ "Song Metadata Editor" }, { isOpened = openState })
	do
		local data = songData:get()

		if not data then
			Iris.Text({ "No song selected" })
			Iris.End()
			return
		end

		-- Refresh field states if song changed
		local currentHash = data.MD5Hash
		local fs = fieldStates:get()
		if not fs then
			fieldStates:set(initFieldStates(data))
			fs = fieldStates:get()
			lastSongHash:set(currentHash)
		elseif lastSongHash:get() ~= currentHash then
			-- Update existing states' values so widgets reflect new song
			for _, def in ipairs(EDITABLE_FIELDS) do
				local key = def.key
				local stateObj = fs[key]
				if stateObj then
					stateObj:set(data[key])
				end
			end
			lastSongHash:set(currentHash)
		end

		Iris.SeparatorText({ "Editable Metadata" })
		for _, def in ipairs(EDITABLE_FIELDS) do
			if def.kind == "number" then
				-- Iris SliderNum args: { Text, Increment, Min, Max, Format? }
				local format
				if def.key == "Volume" then
					format = "%.2f"
				elseif def.key == "TimeOffset" then
					format = "%d ms"
				elseif def.key == "HitSFXGroup" then
					format = "%d"
				end
				Iris.SliderNum({ def.key, def.step or 1, def.min, def.max, format }, { number = fs[def.key] })
			else
				Iris.InputText({ def.key }, { text = fs[def.key] })
			end
		end

		Iris.SeparatorText({ "Derived (read-only)" })
		Iris.Text({ ("Difficulty: %s"):format(tostring(data.Difficulty)) })
		Iris.Text({ ("Length: %sms"):format(tostring(data.Length)) })
		Iris.Text({ ("ObjectCount: %s"):format(tostring(data.ObjectCount)) })
		Iris.Text({ ("Singles: %s Holds: %s"):format(tostring(data.TotalSingleNotes), tostring(data.TotalHoldNotes)) })
		Iris.Text({ ("MaxNPS: %s AvgNPS: %s"):format(tostring(data.MaxNPS), tostring(data.AverageNPS)) })
		Iris.Text({ ("MD5Hash: %s"):format(tostring(data.MD5Hash)) })

		-- Build delta against live songData
		local delta = {}
		for _, def in ipairs(EDITABLE_FIELDS) do
			local key = def.key
			local newVal = fs[key]:get()
			local oldVal = data[key]
			if newVal ~= oldVal then
				delta[def.attr] = newVal -- send YAML field name
			end
		end

		local hasChanges = next(delta) ~= nil
		if not hasChanges then
			Iris.Text({ "No pending changes" })
		end

		if
			Iris.Button(
				{ hasChanges and "Apply Metadata Changes" or "Apply Metadata Changes (none)" },
				{ isDisabled = not hasChanges }
			).clicked()
		then
			Development.SaveSongChanges:FireServer(data.MD5Hash, delta)
			-- Optimistic local apply (translate back attr->attribute names stored in data)
			for _, def in ipairs(EDITABLE_FIELDS) do
				local attrName = def.key
				local yamlName = def.attr
				if delta[yamlName] ~= nil then
					data[attrName] = fs[attrName]:get()
				end
			end
		end
	end
	Iris.End()
	return window
end

return SongEditor
