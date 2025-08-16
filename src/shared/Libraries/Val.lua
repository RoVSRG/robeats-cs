--!strict
--!optimize 2
-- Val by TumbleWede (https://tumblewede.github.io/Val/)
--[=[
	@class Val
]=]
local Val = {}
Val.__index = Val
Val.__iter = function(self)
	local function iterator(_, key)
		repeat
			local value
			key, value = next(self, key)
			if key == "_value" or key == "_listeners" or key == "_dependents" or key == "_disconnects" or key == "set" or key == "_eval" then continue end
			return key, value
		until key == nil

		return nil, nil
	end

	return iterator, self
end

--[=[
	@type Val<T> @metatable {_value: T, _listeners: {(T, T, boolean) -> ()}, _dependents: {Val<any>}, _disconnects: {[Val<any>]: () -> ()}?, _eval<U>: (((Val<U>) -> U) -> T)?, [any]: any}
	@within Val
	Here are the internals of a Val object! You really don't have to understand any of this to know how to use Val,
	but it's here in case you need to do some hacky operations.
	```lua
	local Val = require(path.to.Val)
	local num: Val.Val<number> = Val.new(3.141)
	```
]=]
export type Val<T> = typeof(setmetatable({} :: {
	_value: T,
	_listeners: {(T, T, boolean) -> ()},
	_dependents: {any}, -- Type checker gets mad when I try to say Val<any>
	_disconnects: {[any]: () -> ()}?,
	_eval: (((any) -> any) -> T)?,
	[any]: any
}, Val))

--[=[
	@type T<T> Val<T>
	@within Val
	An alias for `Val<T>` so you can write `Val.T<T>` instead of `Val.Val<T>` in external scripts
	```lua
	local Val = require(path.to.Val)
	local num: Val.T<number> = Val.new(2.718)
	```
]=]
export type T<T> = Val<T>

-- Memory safety stuff
local function trueClosure() return true end
local function voidClosure() return function() end end
local function bad<T>(self: Val<T>, key: any): any?
	if key == "isdead" then return trueClosure end
	if key == "die" then return voidClosure end -- Don't punish client for wanting to make sure the value is dead
	error("Attempt to use Val object that has been destroyed.")
	return voidClosure
end
local function badSet()
	error("Attempt to call Val:set() on a computed Val object.")
end
local badMT = {__index = bad, __newindex = bad}

--[=[
	Constructs a new state
	```lua
	local num = Val.new(20)
	local str = Val.new("Hello, World!")
	local bool = Val.new(true)
	```
]=]
function Val.new<T>(value: T): Val<T>
	return setmetatable({
		_value = value,
		_listeners = {},
		_dependents = {}
	}, Val)
end

--[=[
	@within Val
	@method set
	Sets the value of the state
	@param value T -- the new value of the state
	@param forceSet boolean? -- forces the method to execute anyway in case the old value is the same as the new value
	@return Val
	```lua
	local num = Val.new(10)
	num:set(20)
	local str = Val.new("Foo")
	str:set("Bar")
	```
]=]
function Val.set<T>(self: Val<T>, value: T, forceSet: boolean?): Val<T>
	if value ~= self._value or forceSet then
		local old = self._value
		self._value = value

		for _, callback in ipairs(self._listeners) do
			callback(value, old, false)
		end
	end

	return self
end

--[=[
	@within Val
	@method get
	@return T -- the value of the state
	```lua
	local num = Val.new(10)
	print(num:get()) -- 10
	```
]=]
function Val.get<T>(self: Val<T>): T
	return self._value
end

--[=[
	@within Val
	@method add
	Increases state by `value`
	
	@param value any
	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(5)
	num:add(2) -- 5+2 -> 7
	```
]=]
function Val.add<T>(self: Val<T>, value: any, forceSet: boolean?): Val<T>
	self:set(self._value + value, forceSet)
	return self
end

--[=[
	@within Val
	@method sub
	Decreases state by `value`

	@param value any
	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(5)
	num:sub(2) -- 5-2 -> 3
	```
]=]
function Val.sub<T>(self: Val<T>, value: any, forceSet: boolean?): Val<T>
	self:set(self._value - value, forceSet)
	return self
end

--[=[
	@within Val
	@method mul
	Multiplies state by `value`

	@param value any
	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(5)
	num:mul(2) -- 5*2 -> 10
	```
]=]
function Val.mul<T>(self: Val<T>, value: any, forceSet: boolean?): Val<T>
	self:set(self._value * value, forceSet)
	return self
end

--[=[
	@within Val
	@method div
	Divides state by `value`

	@param value any
	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(5)
	num:div(2) -- 5/2 -> 2.5
	```
]=]
function Val.div<T>(self: Val<T>, value: any, forceSet: boolean?): Val<T>
	self:set(self._value / value, forceSet)
	return self
end

--[=[
	@within Val
	@method idiv
	Floor divides state by `value`

	@param value any
	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(5)
	num:idiv(2) -- 2 remainder 1 -> 2
	```
]=]
function Val.idiv<T>(self: Val<T>, value: any, forceSet: boolean?): Val<T>
	self:set(self._value // value, forceSet)
	return self
end

--[=[
	@within Val
	@method mod
	Applies the modulus of state by `value`

	@param value any
	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(5)
	num:mod(2) -- 2 remainder 1 -> 1
	```
]=]
function Val.mod<T>(self: Val<T>, value: any, forceSet: boolean?): Val<T>
	self:set(self._value % value, forceSet)
	return self
end

--[=[
	@within Val
	@method pow
	Exponentiates state by `value`

	@param value any
	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(5)
	num:pow(2) -- 5^2 -> 25
	```
]=]
function Val.pow<T>(self: Val<T>, value: any, forceSet: boolean?): Val<T>
	self:set(self._value ^ value, forceSet)
	return self
end

--[=[
	@within Val
	@method cat
	Concatenates state by `value`

	@param value any
	@param forceSet boolean?
	@return Val
	```lua
	local str = Val.new("Hello, ")
	str:cat("World!") -- "Hello, " .. "World!" -> "Hello, World!"
	```
]=]
function Val.cat<T>(self: Val<T>, value: any, forceSet: boolean?): Val<T>
	self:set(self._value .. value, forceSet)
	return self
end

--[=[
	@within Val
	@method flip
	Toggles the state's value (value = not value)

	Using this method on a non-boolean state will convert it into a boolean state

	@return Val
	```lua
	local bool = Val.new(true)
	bool:flip() -- false
	bool:flip():flip():flip() -- true -> false -> true
	```
]=]
function Val.flip<T>(self: Val<T>): Val<T>
	self:set(not self._value)
	return self
end

--[=[
	@within Val
	@method min
	Updates state to the smallest value

	Does not support force set

	@param x number
	@param ... number
	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(5)
	num:min(3) -- 3 < 5 -> 3
	num:min(2, 4, 6) -- 2 < 4 < 5 < 6 -> 2
	```
]=]
function Val.min<T>(self: Val<T>, x: number, ...: number): Val<T>
	self:set(math.min(self._value :: any, x, ...))
	return self
end

--[=[
	@within Val
	@method max
	Updates state to the largest value

	Does not support force set

	@param min number
	@param max number
	@return Val
	```lua
	local num = Val.new(5)
	num:max(3) -- 3 < 5 -> 5
	num:max(2, 4, 6) -- 2 < 4 < 5 < 6 -> 6
	```
]=]
function Val.max<T>(self: Val<T>, x: number, ...: number): Val<T>
	self:set(math.max(self._value :: any, x, ...))
	return self
end

--[=[
	@within Val
	@method clamp
	Clamps state between `min` and `max`

	@param x number
	@param ... number
	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(3)
	num:clamp(4, 6) -- 3 < [4, 6] -> 4
	num:clamp(-2, 2) -- 4 < [-2, 2] -> 2
	```
]=]
function Val.clamp<T>(self: Val<T>, min: number, max: number, forceSet: boolean?): Val<T>
	self:set(math.clamp(self._value :: any, min, max), forceSet)
	return self
end

--[=[
	@within Val
	@method abs
	Sets state to its absolute value

	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(3)
	num:abs() -- 3
	num:set(-4)
	num:abs() -- 4
	```
]=]
function Val.abs<T>(self: Val<T>, forceSet: boolean?): Val<T>
	self:set(math.abs(self._value :: any), forceSet)
	return self
end

--[=[
	@within Val
	@method floor
	Rounds down state to the nearest integer

	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(3)
	num:floor() -- 3
	num:set(3.3)
	num:floor() -- 3
	num:set(3.7)
	num:floor() -- 3
	```
]=]
function Val.floor<T>(self: Val<T>, forceSet: boolean?): Val<T>
	self:set(math.floor(self._value :: any), forceSet)
	return self
end

--[=[
	@within Val
	@method ceil
	Rounds up state to the nearest integer

	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(3)
	num:ceil() -- 3
	num:set(3.3)
	num:ceil() -- 4
	num:set(3.7)
	num:ceil() -- 4
	```
]=]
function Val.ceil<T>(self: Val<T>, forceSet: boolean?): Val<T>
	self:set(math.ceil(self._value :: any), forceSet)
	return self
end

--[=[
	@within Val
	@method round
	Rounds state to the nearest integer

	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(3)
	num:round() -- 3
	num:set(3.3)
	num:round() -- 3
	num:set(3.7)
	num:round() -- 4
	```
]=]
function Val.round<T>(self: Val<T>, forceSet: boolean?): Val<T>
	self:set(math.round(self._value :: any), forceSet)
	return self
end

--[=[
	@within Val
	@method snap
	Rounds state to the nearest `unit`

	@param unit number
	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(3.3)
	num:snap(0.5) -- 3.5
	num:set(5.137)
	num:snap(0.01) -- 5.14
	num:set(1.25)
	num:set(2) -- 2
	```
]=]
function Val.snap<T>(self: Val<T>, unit: number, forceSet: boolean?): Val<T>
	self:set(math.round(self._value :: any / unit) * unit, forceSet)
	return self
end

--[=[
	@within Val
	@method lerp
	Interpolates state to `b` based on the factor `t`

	@param b number -- The ending value
	@param t number -- The interpolation factor, typically between 0 and 1
	@param forceSet boolean?
	@return Val
	```lua
	local num = Val.new(3)
	num:lerp(4, 0.5) -- 50% from 3 to 4 -> 3.5
	num:lerp(5, 1) -- 100% from 3.5 to 5 -> 5
	num:lerp(10, 0.4) -- 40% from 5 to 10 -> 7
	```
]=]
function Val.lerp<T>(self: Val<T>, b: number, t: number, forceSet: boolean?): Val<T>
	self:set(math.lerp(self._value :: any, b, t), forceSet)
	return self
end

--[=[
	@within Val
	@method eq
	Checks if the state's value is equal to the value of `other`

	Equivalent to state:get() == other:get()
	@param other Val
	@return boolean
	```lua
	local a = Val.new(10)
	local b = Val.new(10)
	local c = Val.new(20)
	print(a:eq(b)) -- true
	print(a:eq(c)) -- false
	```
]=]
function Val.eq<T, U>(self: Val<T>, other: Val<U>): boolean
	return self._value == other._value
end

--[=[
	@within Val
	@method lt
	Checks if the state's value is less than the value of `other`

	Equivalent to state:get() < other:get()
	@param other Val
	@return boolean
	```lua
	local a = Val.new(20)
	local b = Val.new(30)
	local c = Val.new(10)
	local d = Val.new(20)
	print(a:lt(b)) -- true
	print(a:lt(c)) -- false
	print(a:lt(d)) -- false
	```
]=]
function Val.lt<T, U>(self: Val<T>, other: Val<U>): boolean
	return (self._value :: any) < other._value
end

--[=[
	@within Val
	@method le
	Checks if the state's value is less than or equal to the value of `other`

	Equivalent to state:get() < other:get()
	@param other Val
	@return boolean
	```lua
	local a = Val.new(20)
	local b = Val.new(30)
	local c = Val.new(10)
	local d = Val.new(20)
	print(a:le(b)) -- true
	print(a:le(c)) -- false
	print(a:le(d)) -- true
	```
]=]
function Val.le<T, U>(self: Val<T>, other: Val<U>): boolean
	return (self._value :: any) <= other._value
end

--[=[
	@within Val
	@method gt
	Checks if the state's value is greater than the value of `other`

	Equivalent to state:get() > other:get()
	@param other Val
	@return boolean
	```lua
	local a = Val.new(20)
	local b = Val.new(30)
	local c = Val.new(10)
	local d = Val.new(20)
	print(a:gt(b)) -- false
	print(a:gt(c)) -- true
	print(a:gt(d)) -- false
	```
]=]
function Val.gt<T, U>(self: Val<T>, other: Val<U>): boolean
	return (self._value :: any) > other._value
end

--[=[
	@within Val
	@method ge
	Checks if the state's value is greater than or equal to the value of `other`

	Equivalent to state:get() > other:get()
	@param other Val
	@return boolean
	```lua
	local a = Val.new(20)
	local b = Val.new(30)
	local c = Val.new(10)
	local d = Val.new(20)
	print(a:ge(b)) -- false
	print(a:ge(c)) -- true
	print(a:ge(d)) -- true
	```
]=]
function Val.ge<T, U>(self: Val<T>, other: Val<U>): boolean
	return (self._value :: any) >= other._value
end

--[=[
	@within Val
	@method on
	Subscribes a callback to be called every time the state's value changes
	@param callback (newValue: T, oldValue?: T, wasCalledImmediately?: boolean) -> ()
	@param callImmediately boolean?
	@return disconnect: () -> () -- calling this function will unsubscribe the callback from the state
	```lua
	local num = Val.new(10)
	local disconnect = num:on(function(newValue)
		print("num set to:", newValue)
	end)
	num:set(0) -- num set to: 0
	num:set(20) -- num set to: 20
	disconnect()
	num:set(10) -- no output

	local num = Val.new(10)
	local disconnect = num:on(function(newValue, oldValue, wasCalledImmediately)
		print("was", oldValue, "- now", newValue, "-", wasCalledImmediately)
	end, true) -- was 10 - now 10 - true
	num:set(0) -- was 10 now 0 false
	```
]=]
function Val.on<T>(self: Val<T>, callback: (T, T, boolean) -> (), callImmediately: boolean?): (() -> ())
	table.insert(self._listeners, callback)

	if callImmediately then
		callback(self._value, self._value, true)
	end

	return function()
		if Val.isdead(self) then return end -- In case the state was destroyed
		local index = table.find(self._listeners, callback)
		if index == nil then return end -- You just never know...
		table.remove(self._listeners, index)
	end
end

--[=[
	@within Val
	@method die
	Destroys the state
	@param shallow boolean? -- if true, any states stored inside the current state will be dereferenced rather than destroyed along with the current state
	```lua
	local num = Val.new(10)
	num:set(20)
	num:die()
	num:set(0) -- error

	local bool = Val.new(true)
	bool = bool:die() :: any -- sets bool to nil to ensure that it will be garbage collected

	local foo = Val.new("foo")
	foo.bar = Val.new("bar")
	foo:die() -- also destroys foo.bar

	local yep = Val.new(true)
	local nope = Val.new(false)
	yep.sike = nope
	yep:die(true) -- nope is still alive
	```
]=]
function Val.die<T>(self: Val<T>, shallow: boolean?): nil
	if Val.isdead(self) then return end -- State is already dead (may happen due to coupled states causing memory shenanigans)

	for index = #self._dependents, 1, -1 do
		Val.die(self._dependents[index])
		table.remove(self._dependents, index)
	end
	self._dependents = nil :: any

	table.clear(self._listeners)
	self._listeners = nil :: any

	if self._disconnects then
		for state, unsub in self._disconnects do
			unsub()
			table.remove(state._dependents, table.find(state._dependents, self))
			self._disconnects[state] = nil
		end
	end

	self._disconnects = nil
	self["set"] = nil

	-- Destroy value (if it is a state)
	if not shallow then
		local value = self._value :: any
		if value then
			if getmetatable(value :: any) == Val then -- Destroy value if it is a state
				value:die()
			elseif typeof(value) == "table" then -- Destroy state elements if value is a table
				for key, state in value do
					local mt = getmetatable(state :: any)
					if mt ~= Val and mt ~= badMT then continue end
					value[key] = state:die()
				end
			end
		end
	end
	self._value = nil :: any

	-- Destroy custom fields
	for key, value in self :: any do
		if value and getmetatable(value) == Val and not shallow then -- Deep destroy
			value:die()
		end

		self[key] = nil
	end

	setmetatable(self :: any, badMT)
	return nil
end


--[=[
	@within Val
	@method Destroy
	An alias for `Val:die()` for better compatibility with cleanup libraries like [Janitor](https://howmanysmall.github.io/Janitor/)
]=]
Val.Destroy = Val.die

--[=[
	@within Val
	@method isdead
	Note: `Val.isdead(state)` behaves differently from `state:isdead()` to provide the same output, only if the state is dead

	`Val.isdead(state)` checks the metatable of the state while state:isdead() calls a metamethod to return true
	@return boolean -- whether or not the state is dead
	```lua
	local x = Val.new(true)
	print(x:isdead()) -- false
	print(Val.isdead(x)) -- false
	x:die()
	print(x:isdead()) -- true
	print(Val.isdead(x)) -- true
	print(x:get()) -- error
	```
]=]
function Val.isdead<T>(self: Val<T>): boolean
	return getmetatable(self) :: any == badMT
end

--[=[
	Creates a computed state that automatically updates with its referenced states
	@param eval (get: (Val<any>) -> any) -> T -- a callback function that should return a new value derived from its dependent states

	get (Val<T>) -> T -- inside the eval function, call get(state) instead of state:get() so dependent states are detected
	
	Note: If a dependent state is destroyed, then so will the computed
	@return Val -- an immutable state (Val:set() is disabled to enforce reactivity)
	```lua
	local length = Val.new(10)
	local area = Val.calc(function(get)
		local side = get(length)
		return side * side
	end)
	print(area:get()) -- 10 * 10 -> 100
	length:set(20)
	print(area:get()) -- 20 * 20 -> 400
	```
]=]
function Val.calc<T>(eval: ((Val<any>) -> any) -> T): Val<T>
	local dependencies: {Val<any>} = {}

	local function get<U>(self: Val<U>)
		if not table.find(dependencies, self) then
			table.insert(dependencies, self)
		end

		return self._value
	end

	local self = setmetatable({
		_value = eval(get),
		_listeners = {},
		_dependents = {},
		_disconnects = {},
		_eval = eval,
		set = badSet -- Enforce read-only behavior
	}, Val)

	for _, state in ipairs(dependencies) do
		table.insert(state._dependents, self)
		self._disconnects[state] = state:on(function()
			Val.set(self, self._eval(Val.get))
		end)
	end

	return self
end

--[=[
	Batches a sequence of set calls so that observers are only called after all states are fully set
	@param fn (set) -> T -- a callback function where all the set calls should take place
	
	set (Val<T>) -> T -- inside fn, call set(state) instead of state:set() so that the state change is batched instead of instant
	```lua
	local w = Val.new(6)
	local h = Val.new(5)
	local area = Val.calc(function(get)
		return get(w) * get(h)
	end)
	area:on(function(new)
		print("The area is", new)
	end)

	w:set(8) -- The area is 40
	h:set(3) -- The area is 24

	Val.batch(function(set)
		set(w, 6) -- no output
		set(h, 5) -- no output
	end) -- The area is 30
	```
]=]
function Val.batch(fn: ((Val<any>, any) -> ()) -> ())
	local oldValues: {[Val<any>]: any} = {}

	local function set<T>(self: Val<T>, value: T)
		if oldValues[self] == nil then
			oldValues[self] = self._value
		end

		self._value = value
	end
	fn(set)

	for state, old in oldValues do
		local new = state._value
		for _, callback in ipairs(state._listeners) do
			callback(old, new, false)
		end
	end
end

--[=[
	Creates a state with no value, where `values` are stored as fields directly inside the state itself rather than in its value.

	When the scope state dies, all of its contents die with it unless a true is passed into the first optional parameter (state:die(true))

	Any value inside the scope table that isn't a Val object will be dereferenced rather than destroyed when the scope dies

	If iterating through a scope, always use either generic iteration (for i, v in state do) or ipairs to avoid iterating through built-in keys.
	```lua
	-- Scope dictionary example
	local rect = Val.scope {
		pos = Val.new(Vector2.new(6, 3)),
		size = Val.new(Vector2.new(4, 2))
	}
	print(rect:get()) -- nil
	rect:die() -- pos and size also die
	-- Equivalent to:
	local rect = Val.none()
	rect.pos = Val.new(Vector2.new(6, 3))
	rect.size = Val.new(Vector2.new(4, 2))
	print(rect:get()) -- nil
	rect:die() -- pos and size also die

	-- Scope array example
	local waypoints = Val.scope {
		Val.new(Vector3.new(2, 6, -3)),
		Val.new(Vector3.new(9, -4, 8)),
		Val.new(Vector3.new(-5, 8, 2)),
		Val.new(Vector3.new(-7, 2, -1)),
	}
	
	for i, v in ipairs(waypoints) do
		print(v:get().Magnitude)
	end

	waypoints:die() -- kills all the Vector3 states inside the scope
	```
]=]
function Val.scope(values: {[any]: any}?): Val<nil>
	local self = Val.new(nil)
	if values == nil then return self end

	for key, value in values do
		self[key] = value
	end

	return self
end

--[=[
	Creates a state with no value, essentially creating a scope manually.

	Equivalent to Val.new(nil)
	@return Val<nil> -- a state with no value
	```lua
	local rect = Val.none()
	rect.size = Val.new(Vector2.new(2, 5))
	rect.pos = Val.new(Vector2.new(9, -5))
	rect:die() -- also destroys size and pos
	```
]=]
function Val.none(): Val<nil>
	return Val.new(nil)
end

--[=[
	@within Val
	@method asOption
	Adds option metadata to a Val instance for automatic UI generation
	@param config {type: string, displayName: string, category: string, increment: number?, selection: {string}?}
	@return Val
	```lua
	local speed = Val.new(23):asOption({
		type = "int",
		displayName = "Note Speed",
		category = "General",
		increment = 1
	})
	```
]=]
function Val.asOption<T>(self: Val<T>, config: {type: string, displayName: string, category: string, increment: number?, selection: {string}?}): Val<T>
	self._optionConfig = config
	return self
end

--[=[
	@within Val
	@method copy
	Creates a copy of the state

	The cloned state will not be connected to any callbacks. This also means that a cloned states will not be connected to any computeds.

	This method only creates a shallow copy, so states embedded inside the clone will be the same states as the original in memory.

	Computeds will use the same states as the original
	@return Val
	```lua
	local a = Val.new(0)
	a:on(function(value)
		print("set to", value)
	end)
	local b = a:copy()
	print(a == b) -- false
	print(a:eq(b)) -- true
	a:set(1) -- set to 1
	b:set(2) -- no output
	print(a:get(), b:get()) -- 1, 2
	```
]=]
function Val.copy<T>(self: Val<T>): Val<T>
	local clone = setmetatable({
		_value = self._value,
		_listeners = {},
		_dependents = {},
		_eval = self._eval,
		set = self.set
	}, Val)

	-- Restore computed behavior if applicable
	if self._disconnects and clone._eval then
		clone._disconnects = {}
		for state in pairs(self._disconnects) do
			table.insert(state._dependents, clone)
			clone._disconnects[state] = state:on(function()
				Val.set(clone, clone._eval(Val.get))
			end)
		end
	end

	-- Restore keys from self
	for key, value in self do
		clone[key] = value
	end

	return clone
end

return Val