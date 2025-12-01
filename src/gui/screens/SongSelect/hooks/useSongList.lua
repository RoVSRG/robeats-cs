local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local SongDatabase = require(ReplicatedStorage.SongDatabase)
local Color = require(ReplicatedStorage.Shared.Color)

local useState = React.useState
local useEffect = React.useEffect
local useMemo = React.useMemo

--[[
	useSongList - Song filtering, sorting, and coloring logic

	Args:
		searchTerm: string - Search term (already debounced)
		sortMode: string - Sort mode ("Default", "Difficulty (Desc)", etc.)
		colorMode: string - Color mode ("Default", "Difficulty")

	Returns:
		songs: table - Filtered, sorted, and colored song list
]]
local function useSongList(searchTerm, sortMode, colorMode)
	-- Subscribe to SongDatabase updates
	local allSongs, setAllSongs = useState(SongDatabase.songs or {})

	useEffect(function()
		-- Initial load
		setAllSongs(SongDatabase.songs or {})

		-- Subscribe to new songs being added
		local connection = SongDatabase.SongAdded.Event:Connect(function()
			setAllSongs(SongDatabase.songs or {})
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	-- Filter songs based on search term (memoized)
	local filteredSongs = useMemo(function()
		if searchTerm == "" or not searchTerm then
			return allSongs
		end

		-- Use SongDatabase:Search which does multi-word AND search
		local results = SongDatabase:Search(searchTerm)
		local filtered = {}

		for _, song in allSongs do
			if table.find(results, song.ID) then
				table.insert(filtered, song)
			end
		end

		return filtered
	end, { allSongs, searchTerm })

	-- Sort songs (memoized)
	local sortedSongs = useMemo(function()
		local songs = table.clone(filteredSongs)

		if sortMode == "Default" then
			-- Default order (by ID)
			table.sort(songs, function(a, b)
				return a.ID < b.ID
			end)
		elseif sortMode == "Difficulty (Desc)" then
			table.sort(songs, function(a, b)
				return (a.Difficulty or 0) > (b.Difficulty or 0)
			end)
		elseif sortMode == "Difficulty (Asc)" then
			table.sort(songs, function(a, b)
				return (a.Difficulty or 0) < (b.Difficulty or 0)
			end)
		elseif sortMode == "Title (Asc)" then
			table.sort(songs, function(a, b)
				return (a.SongName or "") < (b.SongName or "")
			end)
		elseif sortMode == "Title (Desc)" then
			table.sort(songs, function(a, b)
				return (a.SongName or "") > (b.SongName or "")
			end)
		elseif sortMode == "Artist (Asc)" then
			table.sort(songs, function(a, b)
				return (a.ArtistName or "") < (b.ArtistName or "")
			end)
		elseif sortMode == "Artist (Desc)" then
			table.sort(songs, function(a, b)
				return (a.ArtistName or "") > (b.ArtistName or "")
			end)
		end

		return songs
	end, { filteredSongs, sortMode })

	-- Apply colors (memoized)
	local songsWithColors = useMemo(function()
		local songs = {}

		for _, song in sortedSongs do
			local songCopy = table.clone(song)

			if colorMode == "Difficulty" then
				-- Calculate color based on difficulty
				songCopy.Color = Color.calculateDifficultyColor(song.Difficulty or 0)
			else
				-- Default: Use song's original color from database
				songCopy.Color = song.Color
			end

			table.insert(songs, songCopy)
		end

		return songs
	end, { sortedSongs, colorMode })

	return songsWithColors
end

return useSongList
