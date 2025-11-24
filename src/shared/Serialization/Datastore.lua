local dsserializer = {}

local HttpService = game:GetService("HttpService")

local function j(t)
		return HttpService:JSONEncode(t)
end

function dsserializer:generate_type(type, value)
		return {type = type, value = value}
end

function dsserializer:serialize_table(tab)
		local serialized = {}

		for i, v in pairs(tab) do
				if type(v) == "table" then
						serialized[i] = self:serialize_table(v)
				else
						local className = typeof(v)
						local handler = script.Handlers:FindFirstChild(className)
						if handler then
								handler = require(handler)
								serialized[i] = handler:serialize(v)
						else
								serialized[i] = v
						end
				end
		end

		return serialized
end

function dsserializer:deserialize_table(tab)
		local deserialized = {}

		for i, v in pairs(tab) do
				if type(v) == "table" then
						--print(j(v))
						local handler = script.Handlers:FindFirstChild(v._classname or "nil")
						if handler then
								handler = require(handler)
								deserialized[i] = handler:deserialize(v.value)
						else
								deserialized[i] = self:deserialize_table(v)
						end
				else
						deserialized[i] = v
				end
		end

		return deserialized
end

return dsserializer