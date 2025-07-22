-- SongDatabase Module
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Functions = Remotes:WaitForChild("Functions")

local SongDatabase = {}
SongDatabase.songs = {}          -- Table of all songs loaded client-side
SongDatabase.songByKey = {}      -- Quick lookup by Name or ID
SongDatabase.pageSize = 100      -- Should match server PAGE_SIZE

-- This BindableEvent fires every time a new song is added.
SongDatabase.SongAdded = Instance.new("BindableEvent")

--[[ 
    SongData structure example:
    {
        Name = "[1035] Petit Rabbits - Daydream Cafe",
        SongName = "Daydream Cafe",
        ArtistName = "Petit Rabbits",
        Difficulty = 45.72,
        Length = 89407,
        Color = Color3.new(r,g,b),
        ID = 1035
    }
]]

-- Adds a single song to the database
function SongDatabase:AddSong(songData)
	if not songData or not songData.ID then
		warn("[SongDatabase] Attempted to add invalid song data!")
		return
	end

	-- Prevent duplicates
	if self.songByKey[songData.Name] then
		return
	end

	table.insert(self.songs, songData)
	self.songByKey[songData.Name] = songData
	self.songByKey[songData.ID] = songData

	-- Fire event so UI or other systems can respond
	self.SongAdded:Fire(songData)
end

-- Fetch song by name or ID
function SongDatabase:GetSongByKey(key)
	return self.songByKey[key]
end

function SongDatabase:GetPropertyByKey(key, property)
	return SongDatabase:GetSongByKey(key)[property]
end

local Functions = game.ReplicatedStorage.Remotes.Functions
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

	print(("[SongDatabase] Loaded %d songs total!"):format(#self.songs))
end

return SongDatabase