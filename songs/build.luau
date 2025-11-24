local process = require("@lune/process")

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local stdio = require("@lune/stdio")
local serde = require("@lune/serde")

local compression = require("./utils/compression").Zlib

local BASE_DIR = "./songs"
local DB_DIR = BASE_DIR .. "/db"

for index, arg in process.args do
	local spl = string.split(arg, "=")

	local flag = spl[1]
	local value = spl[2]

	if flag == "--path" then
		DB_DIR = value
	end

	print("Process argument #" .. tostring(index) .. ": " .. arg)
end

local song_listing = fs.readDir(DB_DIR)

local METADATA_FILE = "metadata.yml"
local HIT_OBJECTS_FILE = "objects.yml"

local function getFullDirectory(song: string, ext: string)
	return DB_DIR .. "/" .. song .. "/" .. ext
end

-- (No longer bundling every song into one Folder model; we'll emit per-song RBXM files)
local songs = roblox.Instance.new("Folder")
songs.Name = "Songs" -- retained for possible future aggregate use, but unused for output now

local DIST_DIR = BASE_DIR .. "/dist"
if not fs.isDir(DIST_DIR) then
	fs.writeDir(DIST_DIR)
end

local function safeFilename(name: string): string
	-- Remove Windows-invalid characters and control chars
	local cleaned = name:gsub('[<>:"/\\|%?%*]', "_")
	cleaned = cleaned:gsub("[%c]", "")
	cleaned = cleaned:gsub("^%s+", ""):gsub("%s+$", "")
	if #cleaned == 0 then
		cleaned = "song"
	end
	return cleaned
end

local function to_base64(data)
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	return (
		((data:gsub(".", function(x)
			local r: any, b: any = "", x:byte()
			for i = 8, 1, -1 do
				r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
			end
			return r
		end) :: string) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
			if #x < 6 then
				return ""
			end
			local c = 0
			for i = 1, 6 do
				c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
			end
			return b:sub(c + 1, c + 1)
		end) .. ({ "", "==", "=" })[#data % 3 + 1]
	)
end

-- Sanitize raw YAML text so it won't panic YAML/JSON parsers
local function sanitizeDirtyYaml(input: string): string
	local output = {}
	local i = 1
	while i <= #input do
		local byte = string.byte(input, i)

		-- Printable ASCII (space through ~) and common YAML control chars
		if byte == 9 or byte == 10 or byte == 13 or (byte >= 32 and byte <= 126) then
			table.insert(output, string.char(byte))
			i += 1
		else
			-- Non-ASCII / weird byte => replace with safe placeholder
			table.insert(output, "?")
			i += 1
		end
	end
	return table.concat(output)
end

local function generateHitObjectData(hitObjects)
	local singles = 0
	local holds = 0

	local length = hitObjects[#hitObjects].Time :: number

	local npsGraph = {}
	local CHUNKS = 50

	-- Initialize chunks with note counts
	local chunkNotes = {}
	for i = 1, CHUNKS do
		chunkNotes[i] = 0
	end

	-- Calculate chunk duration
	local chunkDuration = length / CHUNKS

	for _, hitObject in ipairs(hitObjects) do
		if hitObject.Duration ~= nil then
			holds += 1
		else
			singles += 1
		end

		local time = hitObject.Time :: number

		-- Determine which chunk this note belongs to
		local chunkIndex = math.min(math.ceil(time / chunkDuration), CHUNKS)
		if chunkIndex < 1 then
			chunkIndex = 1
		end

		chunkNotes[chunkIndex] = chunkNotes[chunkIndex] + 1
	end

	-- Convert note counts to NPS (notes per second)
	local chunkDurationSeconds = chunkDuration / 1000 -- Convert from milliseconds to seconds
	for i = 1, CHUNKS do
		npsGraph[i] = chunkNotes[i] / chunkDurationSeconds
	end

	local maxNPS = 0
	for _, count in ipairs(npsGraph) do
		if count > maxNPS then
			maxNPS = count
		end
	end

	local averageNPS = 0
	for _, count in ipairs(npsGraph) do
		averageNPS += count
	end
	averageNPS = averageNPS / #npsGraph

	return npsGraph, maxNPS, averageNPS, singles, holds
end

for index, song in ipairs(song_listing) do
	local suc, err = pcall(function()
		local metadata = serde.decode("yaml", sanitizeDirtyYaml(fs.readFile(getFullDirectory(song, METADATA_FILE))))
		local hitObjects =
			serde.decode("yaml", sanitizeDirtyYaml(fs.readFile(getFullDirectory(song, HIT_OBJECTS_FILE))))

		if not metadata or not hitObjects or #hitObjects == 0 then
			error("Invalid metadata or hit objects for song: " .. song)
		end

		local difficulty = 0
		local length = 0

		if typeof(metadata.Difficulty) == "table" then
			for _, rateMetadata in metadata.Difficulty do
				if rateMetadata.Rate == 100 then
					difficulty = rateMetadata.Overall
					break
				end
			end
		else
			difficulty = metadata.Difficulty
		end

		local lastHitObject = hitObjects[#hitObjects]
		length = lastHitObject.Time + (if lastHitObject.Duration then lastHitObject.Duration else 0)

		stdio.write(string.format("Converting songs (%d/%d)\n", index, #song_listing))

		local songFolder = roblox.Instance.new("Folder")

		-- Basic song information
		songFolder:SetAttribute("ArtistName", metadata.Artist or "Unknown")
		songFolder:SetAttribute("SongName", metadata.Filename or "Unknown")
		songFolder:SetAttribute("CharterName", metadata.Mapper or "Unknown")
		songFolder:SetAttribute("Description", metadata.Description or "")

		-- Audio and visual assets
		songFolder:SetAttribute("AudioID", metadata.AssetId or "rbxassetid://0")
		songFolder:SetAttribute("CoverImageAssetId", metadata.CoverImageAssetId or "rbxassetid://0")

		-- Audio settings
		songFolder:SetAttribute("Volume", metadata.Volume or 1)
		songFolder:SetAttribute("HitSFXGroup", metadata.HitSFXGroup or 0)
		songFolder:SetAttribute("TimeOffset", metadata.TimeOffset or 0)

		-- Chart information
		songFolder:SetAttribute("Difficulty", difficulty or 0)
		songFolder:SetAttribute("Length", length or 0)
		songFolder:SetAttribute("ObjectCount", #hitObjects)
		songFolder:SetAttribute("MD5Hash", metadata.MD5Hash or "")

		local nps, maxNPS, averageNPS, singles, holds = generateHitObjectData(hitObjects)
		songFolder:SetAttribute("NPSGraph", table.concat(nps, ","))
		songFolder:SetAttribute("MaxNPS", maxNPS)
		songFolder:SetAttribute("AverageNPS", averageNPS)
		songFolder:SetAttribute("TotalSingleNotes", singles)
		songFolder:SetAttribute("TotalHoldNotes", holds)

		local encodedNotes = serde.encode("json", hitObjects)

		local chartString = roblox.Instance.new("StringValue")
		chartString.Name = "ChartString"
		local compressed = select(1, compression.Compress(encodedNotes, {}))
		chartString.Value = to_base64(compressed)
		chartString.Parent = songFolder

		-- Serialize this song individually
		local fileBaseName = tostring(metadata.MD5Hash) or "unknown"
		local model_file = roblox.serializeModel({ songFolder }, false)
		fs.writeFile(string.format("%s/%s.rbxm", DIST_DIR, fileBaseName), model_file)
	end)

	if not suc then
		print(err)
	end
end

stdio.write("-[DONE generating individual song RBXM files]-")
