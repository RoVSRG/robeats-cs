local Fastify = require("./fastify")

local app = Fastify.new()

app:get("/", function(request)
	return { status = 200, body = "Robeats CS Development Server" }
end)

app:listen(3001)
