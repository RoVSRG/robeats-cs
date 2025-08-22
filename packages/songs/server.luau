local Fastify = require("./fastify")

local app = Fastify.new()

app:get("/path", function(request)
	return { status = 200, body = "Hello, World!" }
end)

app:listen(3001)
