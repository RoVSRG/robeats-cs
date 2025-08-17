local EnumHandler = {}

function EnumHandler:new()
		local self = {}
		function self:serialize() return {} end
		function self:deserialize() return {} end
		function self:new_object(name, value) return {_classname = name, value = value} end
		return self
end
		
return EnumHandler