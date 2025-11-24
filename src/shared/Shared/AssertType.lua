local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)

local AssertType = {}

function AssertType:is_int(val)
	AssertType:is_number(val)
	if math.floor(val) ~= val then
		DebugOut:errf("AssertType:is_int(%s)",tostring(val))
	end
end

function AssertType:is_positive(val)
	AssertType:is_number(val)
	if val < 0 then
		DebugOut:errf("AssertType:is_positive(%s)",tostring(val))
	end
end

function AssertType:is_int_in_range(val, min, max)
	AssertType:is_int(val)
	if val < min or val > max then
		DebugOut:errf("AssertType:is_int_in_range(%s)",tostring(val))
	end
end

function AssertType:is_int_greater_than(val,min)
	AssertType:is_int_in_range(val, min, val)
end

function AssertType:is_number(val)
	if typeof(val) ~= "number" then
		DebugOut:errf("AssertType:is_number(%s)",tostring(val))
	end
end

function AssertType:is_non_nil(val)
	if val == nil then
		DebugOut:errf("AssertType:is_non_nil(%s)",tostring(val))
	end
end

function AssertType:is_string(val)
	if typeof(val) ~= "string" then
		DebugOut:errf("AssertType:is_string(%s)",tostring(val))
	end
end

function AssertType:is_nonempty_string(val)
	AssertType:is_string(val)
	if #val == 0 then
		DebugOut:errf("AssertType:is_nonempty_string(%s)",tostring(val))
	end
end

function AssertType:is_bool(val)
	if typeof(val) ~= "boolean" then
		DebugOut:errf("AssertType:is_bool(%s)",tostring(val))
	end
end

function AssertType:is_table(val)
	if typeof(val) ~= "table" then
		DebugOut:errf("AssertType:is_table(%s)",tostring(val))
	end
end

function AssertType:is_true(val, errmsg)
	if val ~= true then
		if errmsg ~= nil then
			DebugOut:errf("AssertType:is_true(%s)",tostring(errmsg))
		else
			DebugOut:errf("AssertType:is_true(%s)",tostring(val))
		end
	end
end

function AssertType:is_false(val, errmsg)
	if val ~= false then
		if errmsg ~= nil then
			DebugOut:errf("AssertType:is_false(%s)",tostring(errmsg))
		else
			DebugOut:errf("AssertType:is_false(%s)",tostring(val))
		end
	end
end

local _enum_class_to_values = SPDict:new()
function AssertType:test_enum_member(val, enum_class)
	if _enum_class_to_values:contains(enum_class) ~= true then
		local values = SPDict:new()
		for key,value in pairs(enum_class) do
			if typeof(value) == "number" or typeof(value) == "string" then
				values:add(value,key)
			end
		end
		_enum_class_to_values:add(enum_class, values)
	end
	
	local values = _enum_class_to_values:get(enum_class)
	if values:contains(val) ~= true then
		return false
	end
	return true
end

function AssertType:is_enum_member(val, enum_class)
	if AssertType:test_enum_member(val, enum_class) ~= true then
		DebugOut:errf("AssertType:is_enum_member(%s)", tostring(val))
	end
end

function AssertType:is_classname(val, classname)
	AssertType:is_true(val.ClassName == classname)
end

function AssertType:is_function(val, errmsg)
	if typeof(val) ~= "function" then
		if errmsg ~= nil then
			DebugOut:errf("AssertType:is_function(%s)", tostring(errmsg))
		else
			DebugOut:errf("AssertType:is_function(%s)", tostring(val))
		end
	end
end

return AssertType