local roblox = require("@lune/roblox")
local reflectionDB = roblox.getReflectionDatabase()

local Reflection = {}

function Reflection.getFullPropertySet(className: string)
	local defaults = {}
	local properties = {}

	local currentClass = reflectionDB:GetClass(className)

	if not currentClass then
		return {
			properties = properties,
			defaultProperties = defaults,
		}
	end

	while currentClass.Superclass do
		if currentClass.Name == "Instance" then
			break
		end

		for _, prop in currentClass.Properties do
			if not properties[prop.Name] then
				properties[prop.Name] = prop
			end
		end

		for name, value in currentClass.DefaultProperties do
			if not defaults[name] then
				defaults[name] = value
			end
		end

		currentClass = reflectionDB:GetClass(currentClass.Superclass)
	end

	return {
		properties = properties,
		defaultProperties = defaults,
	}
end

return Reflection
