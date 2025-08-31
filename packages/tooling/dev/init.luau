local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

-- Simple development metadata editing server
-- POST /save { hash: string, delta: {<whitelisted keys>} }
-- Directly operates on songs/dist/<hash>.rbxm and its YAML metadata (searching DB each request).

local function parseJson(json: string)
	return serde.decode("json", json)
end
local function stringifyJson(data: any)
	return serde.encode("json", data)
end

local Fastify = require("@self/fastify")
local app = Fastify.new()

local BASE_DIR = "./packages/songs"
local DB_DIR = BASE_DIR .. "/db"
local METADATA_FILE = "metadata.yml"
local DIST_DIR = BASE_DIR .. "/dist"

-- Simple logger with timestamps + level
local function now()
	return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function log(level: string, msg: string, ...)
	local ok, formatted = pcall(string.format, msg, ...)
	if not ok then
		formatted = msg .. " (format error)"
	end
	print(string.format("[%s][tooling-dev][%s] %s", now(), level, formatted))
end

-- Whitelist of metadata keys allowed to mutate
local ALLOWED_KEYS = {
	Artist = true,
	AssetId = true,
	CoverImageAssetId = true,
	Description = true,
	Filename = true,
	HitSFXGroup = true,
	Mapper = true,
	NotePrebufferTime = true,
	TimeOffset = true,
	Volume = true,
	Difficulty = true,
}

local function patchMetadata(meta: any, delta: any)
	for k, v in pairs(delta) do
		if ALLOWED_KEYS[k] then
			log("DEBUG", "Patch metadata key %s => %s", k, tostring(v))
			meta[k] = v
		end
	end
end

-- Pre-computed hash index for metadata hash -> folder
local hashIndex = {} :: { [string]: string }
local indexing = false

local function buildHashIndex(force: boolean?)
	if indexing then
		return -- prevent re-entrancy
	end
	indexing = true
	hashIndex = {}
	local dirs = fs.readDir(DB_DIR)
	local count = 0
	for _, folder in ipairs(dirs) do
		local metaPath = string.format("%s/%s/%s", DB_DIR, folder, METADATA_FILE)
		if fs.isFile(metaPath) then
			local ok, decoded = pcall(function()
				return serde.decode("yaml", fs.readFile(metaPath))
			end)
			if ok and type(decoded) == "table" and decoded.MD5Hash then
				hashIndex[tostring(decoded.MD5Hash)] = folder
				count += 1
			else
				if not ok then
					log("WARN", "Failed decoding metadata for folder %s", folder)
				end
			end
		end
	end
	log("INFO", "Hash index built with %d entries", count)
	indexing = false
end

-- Build at startup
buildHashIndex()

local function resolveFolder(hash: string): string?
	local folder = hashIndex[hash]
	if folder then
		return folder
	end
	-- Fallback: rebuild index once if missing
	log("DEBUG", "Hash %s not in index; rebuilding index", hash)
	buildHashIndex(true)
	return hashIndex[hash]
end

app:get("/reindex", function()
	buildHashIndex(true)
	return { status = 200, body = "Reindexed" }
end)

app:get("/", function()
	return { status = 200, body = "Robeats CS Development Server" }
end)

app:post("/save", function(request)
	log("INFO", "Incoming /save request, raw length=%d", #(request.body or ""))
	local okBody, data = pcall(function()
		return parseJson(request.body)
	end)
	if not okBody or type(data) ~= "table" then
		log("WARN", "Invalid JSON body: %s", tostring(data))
		return { status = 400, body = "Invalid JSON" }
	end

	local hash = tostring(data.hash or "")
	local delta = data.delta or {}
	if hash == "" then
		log("WARN", "Missing hash in request")
		return { status = 400, body = "Missing hash" }
	end
	log(
		"DEBUG",
		"Processing hash=%s; delta keys=%d",
		hash,
		(function()
			local c = 0
			for k, _ in pairs(delta) do
				c += 1
			end
			return c
		end)()
	)

	local distModelPath = string.format("%s/%s.rbxm", DIST_DIR, hash)
	if not fs.isFile(distModelPath) then
		log("WARN", "Model file missing for hash=%s path=%s", hash, distModelPath)
		return { status = 404, body = "Model file not found for hash" }
	end
	log("DEBUG", "Model file located: %s", distModelPath)

	local folder = resolveFolder(hash)
	if not folder then
		log("WARN", "Could not resolve folder for hash=%s after reindex", hash)
		return { status = 404, body = "Metadata folder not found for hash" }
	end
	log("DEBUG", "Resolved folder %s for hash=%s", folder, hash)

	local metaPath = string.format("%s/%s/%s", DB_DIR, folder, METADATA_FILE)
	local raw = fs.readFile(metaPath)
	if not raw then
		log("ERROR", "Metadata file unreadable: %s", metaPath)
		return { status = 500, body = "Metadata file unreadable" }
	end

	local okMeta, meta = pcall(function()
		return serde.decode("yaml", raw)
	end)
	if not okMeta or type(meta) ~= "table" then
		log("ERROR", "Metadata decode failed for %s", metaPath)
		return { status = 500, body = "Metadata decode failed" }
	end
	log("DEBUG", "Loaded metadata for %s", folder)

	patchMetadata(meta, delta)
	local okEncode, encoded = pcall(function()
		return serde.encode("yaml", meta)
	end)
	if not okEncode then
		log("ERROR", "Metadata encode failed for %s", metaPath)
		return { status = 500, body = "Metadata encode failed" }
	end
	fs.writeFile(metaPath, encoded)
	log("INFO", "Metadata written %s (size=%d)", metaPath, #encoded)

	-- Update model attributes
	local modelData = fs.readFile(distModelPath)
	if not modelData then
		log("ERROR", "Failed reading model file %s", distModelPath)
		return { status = 500, body = "Failed reading model" }
	end
	local okModel, modelInstances = pcall(function()
		return roblox.deserializeModel(modelData)
	end)
	if not okModel or type(modelInstances) ~= "table" or not modelInstances[1] then
		log("ERROR", "Model deserialize failed hash=%s", hash)
		return { status = 500, body = "Model deserialize failed" }
	end

	local folderInstance = modelInstances[1]
	local attrMap = {
		Artist = "ArtistName",
		Filename = "SongName",
		Mapper = "CharterName",
		Description = "Description",
		AssetId = "AudioID",
		CoverImageAssetId = "CoverImageAssetId",
		Volume = "Volume",
		HitSFXGroup = "HitSFXGroup",
		TimeOffset = "TimeOffset",
		Difficulty = "Difficulty",
	}
	for yamlKey, attrKey in pairs(attrMap) do
		if delta[yamlKey] ~= nil then
			log("DEBUG", "Set attribute %s = %s", attrKey, tostring(delta[yamlKey]))
			folderInstance:SetAttribute(attrKey, delta[yamlKey])
		end
	end

	local serialized = roblox.serializeModel({ folderInstance }, false)
	fs.writeFile(distModelPath, serialized)
	log("INFO", "Model updated %s (size=%d)", distModelPath, #serialized)

	return { status = 200, body = stringifyJson({ updated = delta, folder = folder }) }
end)

app:listen(3001)
