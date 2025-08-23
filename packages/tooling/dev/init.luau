local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

-- Development metadata editing server (metadata only; hitobjects immutable here)
-- Exposes /save which patches allowed metadata keys for a song identified by MD5Hash.

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

-- Whitelist of metadata keys (YAML -> in-game attribute mapping)
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
	Difficulty = true, -- now editable (single numeric value post-migration)
	-- Difficulty table & MD5Hash are NOT directly editable here.
}

-- Cache mapping MD5 hash -> folder name for fast lookup
local hashIndex = nil :: { [string]: string }?

local function buildHashIndex()
	local index: { [string]: string } = {}
	local dirs = fs.readDir(DB_DIR)
	for _, folder in ipairs(dirs) do
		local metaPath = string.format("%s/%s/%s", DB_DIR, folder, METADATA_FILE)
		if fs.isFile(metaPath) then
			local ok, decoded = pcall(function()
				return serde.decode("yaml", fs.readFile(metaPath))
			end)
			if ok and decoded and type(decoded) == "table" and decoded.MD5Hash then
				index[tostring(decoded.MD5Hash)] = folder
			end
		end
	end
	hashIndex = index
end

local function ensureHashIndex()
	if not hashIndex then
		buildHashIndex()
	end
end

local function resolveHash(hash: string): (string?, string?)
	ensureHashIndex()
	if hashIndex and hashIndex[hash] then
		return hashIndex[hash], nil
	end
	return nil, "Unknown hash"
end

local function patchMetadata(meta: any, delta: any)
	for k, v in pairs(delta) do
		if ALLOWED_KEYS[k] then
			meta[k] = v
		end
	end
end

app:get("/", function(request)
	return { status = 200, body = "Robeats CS Development Server" }
end)

app:post("/save", function(request)
	local bodyOk, data = pcall(function()
		return parseJson(request.body)
	end)

	if not bodyOk or type(data) ~= "table" then
		return { status = 400, body = "Invalid JSON" }
	end

	local hash = tostring(data.hash or "")
	local delta = data.delta or {}

	if hash == "" then
		return { status = 400, body = "Missing hash" }
	end

	local folder, err = resolveHash(hash)
	if not folder then
		return { status = 404, body = err or "Hash not found" }
	end

	local metaPath = string.format("%s/%s/%s", DB_DIR, folder, METADATA_FILE)
	local raw = fs.readFile(metaPath)
	if not raw then
		return { status = 500, body = "Metadata missing" }
	end

	local ok, meta = pcall(function()
		return serde.decode("yaml", raw)
	end)
	if not ok or type(meta) ~= "table" then
		return { status = 500, body = "Metadata decode failed" }
	end

	patchMetadata(meta, delta)

	-- Write back (serialize to YAML). serde's YAML encoder should preserve ordering loosely; no custom ordering for now.
	local writeOk, encoded = pcall(function()
		return serde.encode("yaml", meta)
	end)
	if not writeOk then
		return { status = 500, body = "Encode failed" }
	end

	fs.writeFile(metaPath, encoded)

	-- Also patch the serialized model in /dist so changes persist without full rebuild
	local distModelPath = string.format("%s/%s.rbxm", DIST_DIR, hash)
	if fs.isFile(distModelPath) then
		local modelData = fs.readFile(distModelPath)
		local okModel, modelInstances = pcall(function()
			return roblox.deserializeModel(modelData)
		end)
		if okModel and type(modelInstances) == "table" and modelInstances[1] then
			local folderInstance = modelInstances[1]
			-- Map YAML keys to in-game attribute keys
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
					folderInstance:SetAttribute(attrKey, delta[yamlKey])
				end
			end
			-- Reserialize
			local serialized = roblox.serializeModel({ folderInstance }, false)
			fs.writeFile(distModelPath, serialized)
		end
	end

	-- Rebuild index if MD5Hash changed (unlikely since we don't modify it)
	if meta.MD5Hash ~= hash then
		buildHashIndex()
	end

	return { status = 200, body = stringifyJson({ updated = delta, folder = folder }) }
end)

app:listen(3001)
