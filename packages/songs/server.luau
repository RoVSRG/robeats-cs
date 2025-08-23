local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

local function parseJson(json: string)
	return serde.decode("json", json)
end

local function stringifyJson(data: any)
	return serde.encode("json", data)
end

local Fastify = require("./fastify")

local app = Fastify.new()

app:get("/", function(request)
	return { status = 200, body = "Robeats CS Development Server" }
end)

app:post("/save", function(request)
	local data = parseJson(request.body)

	print(data.hash, data.delta)

	local file = fs.readFile("./packages/songs/dist/" .. data.hash .. ".rbxm")

	if not file then
		return { status = 404, body = "Song not found" }
	end

	local song = roblox.deserializeModel(file)[1]

	print(song:GetAttributes())

	return { status = 200, body = stringifyJson(data.delta) }
end)

app:listen(3001)
