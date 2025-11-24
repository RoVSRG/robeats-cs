local EnumHandler = require(script.Parent.Parent.System.EnumHandler)
local Color3Handler = EnumHandler:new()

function Color3Handler:serialize(item)
		return self:new_object("Color3", {R = item.R, G = item.G, B = item.B})
		
end

function Color3Handler:deserialize(item)
		return Color3.new(item.R, item.G, item.B)
end

return Color3Handler