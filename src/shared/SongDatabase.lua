-- SongDatabase Module
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Functions = Remotes:WaitForChild("Functions")

local SongDatabase = {}
SongDatabase.songs = {}          -- Table of all songs loaded client-side
SongDatabase.songByKey = {} :: {[any]: any}      -- Quick lookup by Name or ID
SongDatabase.songByHash = {} :: {[any]: any}      -- Quick lookup by MD5Hash
SongDatabase.pageSize = 100      -- Should match server PAGE_SIZE

SongDatabase.IsLoaded = false

-- This BindableEvent fires every time a new song is added.
SongDatabase.SongAdded = Instance.new("BindableEvent")
SongDatabase.Loaded = Instance.new("BindableEvent")

--[[ 
    SongData structure example:
    {
		Name = folder.Name,
		SongName = folder:GetAttribute("SongName"),
		ArtistName = folder:GetAttribute("ArtistName"),
		CharterName = folder:GetAttribute("CharterName"),
		Description = folder:GetAttribute("Description"),
		Difficulty = folder:GetAttribute("Difficulty"),
		Length = folder:GetAttribute("Length"),
		ObjectCount = folder:GetAttribute("ObjectCount"),
		AudioID = folder:GetAttribute("AudioID"),
		CoverImageAssetId = folder:GetAttribute("CoverImageAssetId"),
		Volume = folder:GetAttribute("Volume"),
		HitSFXGroup = folder:GetAttribute("HitSFXGroup"),
		TimeOffset = folder:GetAttribute("TimeOffset"),
		MD5Hash = folder:GetAttribute("MD5Hash"),
		Color = colorKeys[tostring(i)],
		ID = i,
		FolderName = folder.Name
	}
]]

-- Adds a single song to the database
function SongDatabase:AddSong(songData)
	if not songData or not songData.ID then
		warn("[SongDatabase] Attempted to add invalid song data!")
		return
	end

	-- Prevent duplicates
	if self.songByHash[songData.MD5Hash] then
		return
	end

	table.insert(self.songs, songData)
	self.songByKey[songData.Name] = songData
	self.songByKey[songData.ID] = songData
	self.songByHash[songData.MD5Hash] = songData

	-- Fire event so UI or other systems can respond
	self.SongAdded:Fire(songData)
end

-- Fetch song by name or ID
function SongDatabase:GetSongByKey(key)
	return self.songByKey[key] or self.songByHash[key]
end

function SongDatabase:GetPropertyByKey(key, property, tf)
	local value = SongDatabase:GetSongByKey(key)[property]

	if tf then
		value = tf(value)
	end

	return value
end

-- Search for songs by artist name, file name, or charter name
function SongDatabase:Search(searchTerm)
	if not searchTerm or searchTerm == "" then
		return {}
	end
	
	local results = {}
	local lowerSearchTerm = string.lower(searchTerm)

	local words = string.split(lowerSearchTerm, " ")
	
	for _, songData in ipairs(self.songs) do
		local searchString = string.lower(songData.SongName .. " " .. songData.ArtistName .. " " .. songData.CharterName)

		local allWordsFound = true

		for _, word in ipairs(words) do
			if not string.find(searchString, word, 1, true) then
				allWordsFound = false
				break
			end
		end

		if allWordsFound then
			table.insert(results, songData.ID)
		end
	end
	
	return results
end

local CompressMachine = require(game.ReplicatedStorage.Libraries.CompressMachine)

function SongDatabase:GetHitObjectsForFolderName(name)
	-- 1. Ask server for compressed chart string
	local success, chartB64 = pcall(function()
		return Functions.GetHitObjects:InvokeServer(name)
	end)

	if not success or not chartB64 then
		warn("[SongDatabase] Failed to fetch hitobjects for", name)
		return nil
	end
 
	-- 2. Decode Base64 -> compressed binary
	local compressed = CompressMachine.fromBase64(chartB64)

	-- 3. Decompress -> JSON string
	local jsonString = CompressMachine.Zlib.Decompress(compressed)

	-- 4. Parse JSON into Lua table
	local HttpService = game:GetService("HttpService")
	local hitObjects = HttpService:JSONDecode(jsonString)

	return hitObjects
end


-- Internal helper: Fetch a single page
local function fetchPage(pageIndex)
	local success, result = pcall(function()
		return Functions.GetSongsPage:InvokeServer(pageIndex)
	end)

	if not success then
		warn("[SongDatabase] Failed to fetch page " .. tostring(pageIndex) .. ": ", result)
		return nil
	end

	if typeof(result) == "table" and #result > 0 then
		return result
	else
		return nil -- no more pages
	end
end

-- Public: Load ALL songs by iterating through every page
function SongDatabase:LoadAllSongs()
	local pageIndex = 0

	while true do
		local page = fetchPage(pageIndex)
		if not page then
			break
		end

		for _, songData in ipairs(page) do
			self:AddSong(songData)
		end

		-- Next page
		pageIndex += 1
	end

	SongDatabase.IsLoaded = true
	SongDatabase.Loaded:Fire()

	print(("[SongDatabase] Loaded %d songs total!"):format(#self.songs))
end

return SongDatabase