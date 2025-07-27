local roblox = require("@lune/roblox")
local reflectionDB = roblox.getReflectionDatabase()

local base = reflectionDB:GetClass("GuiObject")
local extended = reflectionDB:GetClass("ImageLabel")

local class = {
    Properties = {},
    DefaultProperties = {}
}

for name, prop in extended.Properties do
    class.Properties[name] = prop
end

for name, prop in extended.DefaultProperties do
    class.DefaultProperties[name] = prop
end

for name, prop in base.Properties do
    if class.Properties[name] == nil then
        class.Properties[name] = prop
    end
end

for name, prop in base.DefaultProperties do
    if class.DefaultProperties[name] == nil then
        class.DefaultProperties[name] = prop
    end
end

print(class)