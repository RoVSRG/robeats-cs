local EnumHandler = require(script.Parent.Parent.System.EnumHandler)
local EnumItemHandler = EnumHandler:new()

function EnumItemHandler:serialize(item)
		return self:new_object("EnumItem", {name = item.Name, enum_type = tostring(item.EnumType), value = item.Value})
end

function EnumItemHandler:deserialize(item)
		-- IF IM WRONG ABOUT THIS, AND SOMETHING BREAKS BECAUSE I WAS STUPID AND DONT KNOW HOW ENUMS WORK PLEASE FEEL FREE TO CORRECT ME
		local type = item.enum_type
		local value = item.value

		for i, v in pairs(Enum:GetEnums()) do
				if tostring(v) == type then
						for _, enumItem in pairs(v:GetEnumItems()) do
								if enumItem.Value == value then
										return enumItem
								end
						end
				end
		end
end

return EnumItemHandler