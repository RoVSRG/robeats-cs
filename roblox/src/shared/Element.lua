-- just a cute lil utility class for creating Instances on the fly

local Element = {}

function Element.new(className: string, properties: any, children: { [any]: Instance }?)
	local instance = Instance.new(className)

	if properties then
		for key, value in pairs(properties) do
			instance[key] = value
		end
	end

	-- if children is a table, assume it's a list of children to add
	if children and type(children) == "table" then
		for _, child in pairs(children) do
			child.Parent = instance
		end
	end

	return instance
end

return Element
