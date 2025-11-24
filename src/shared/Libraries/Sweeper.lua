type Sweeper = {
	Add: <T>(Sweeper, object: T, cleanMethod: string?) -> T,
	Sweep: (Sweeper) -> (),
}

local function inferCleanMethod(object)
	local type = typeof(object)
	if type == "RBXScriptConnection" then
		return "Disconnect"
	elseif type == "table" then
		local mt = getmetatable(object)
		if mt.Disconnect then
			return "Disconnect"
		elseif mt.DisconnectAll then
			return "DisconnectAll"
		end
	elseif type == "Instance" then
		return "Destroy"
	end
end

local Sweeper = {}
function Sweeper:__index(index)
	return Sweeper[index] or self._objects[index]
end

function Sweeper:__newindex(index, object)
	local objects = self._objects
	local cache = self._cache

	if object then
		local cleanMethod = inferCleanMethod(object)
		if not cleanMethod then
			if type(object) == "function" then
				object = { object }
				cleanMethod = 1
			else
				error(`Couldn't infer a clean method from newindex for {object}`)
			end
		end
		cache[object] = cleanMethod
	end

	local obj = objects[index]
	if obj then
		obj[cache[obj]](obj)
		cache[obj] = nil
	end

	objects[index] = object
end

--[==[
    Do NOT set `_objects` or `_cache` as they are already predefined
    ```lua
    local sweeper = require(path/to/Sweeper).new()
    sweeper._objects = someObject
    sweeper._cache = someObject
    ```
--]==]
function Sweeper.new(): Sweeper
	return setmetatable({ _objects = {}, _cache = {} }, Sweeper)
end

function Sweeper:Add<T>(object: T, cleanMethod: string?): T
	cleanMethod = cleanMethod or inferCleanMethod(object)
	if not cleanMethod then
		if type(object) == "function" then
			object = { object }
			cleanMethod = 1
		else
			error(`Couldn't infer a clean method for {object}, provide it manually in the 2nd arg`)
		end
	end
	self._objects[object] = object
	self._cache[object] = cleanMethod
	return object
end

function Sweeper:Sweep()
	local cache = self._cache
	for _, object in self._objects do
		object[cache[object]](object)
	end
	self._cache = {}
	self._objects = {}
end

return Sweeper
