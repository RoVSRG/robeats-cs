local net = require("@lune/net")

type RouteConfig = {
	method: string,
	path: string,
	callback: (request: any) -> any,
}

local Fastify = {}

Fastify.routes = {}

function Fastify.new()
	local self = setmetatable({}, { __index = Fastify })
	return self
end

local function _register(self: any, config: RouteConfig)
	table.insert(self.routes, {
		method = config.method,
		path = config.path,
		callback = config.callback,
	})
end

function Fastify:get(path: string, callback: (request: any) -> any)
	_register(self, {
		method = "get",
		path = path,
		callback = callback,
	})
end

function Fastify:post(path: string, callback: (request: any) -> any)
	_register(self, {
		method = "post",
		path = path,
		callback = callback,
	})
end

function Fastify:put(path: string, callback: (request: any) -> any)
	_register(self, {
		method = "put",
		path = path,
		callback = callback,
	})
end

function Fastify:delete(path: string, callback: (request: any) -> any)
	_register(self, {
		method = "delete",
		path = path,
		callback = callback,
	})
end

function Fastify:handleRequest(request: net.ServeRequest)
	for _, route in ipairs(self.routes) do
		if route.method == request.method and route.path == request.path then
			return route.callback(request)
		end
	end

	return { status = 404, body = "Not Found" }
end

function Fastify:listen(port: number)
	net.serve(port, function(request: net.ServeRequest)
		return self:handleRequest(request)
	end)
end

return Fastify
