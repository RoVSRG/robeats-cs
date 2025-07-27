local roblox = require("@lune/roblox")
local reflectionDB = roblox.getReflectionDatabase()

local base = reflectionDB:GetClass("GuiObject")
local extended = reflectionDB:GetClass("ImageLabel")

local function getDefaultProperty(name)
    if extended.DefaultProperties[name] ~= nil then
        return extended.DefaultProperties[name]
    end

    if base.DefaultProperties[name] ~= nil then
        return base.DefaultProperties[name]
    end
end

local function getProperty(name)
    if extended.Properties[name] ~= nil then
        return extended.Properties[name]
    end

    if base.Properties[name] ~= nil then
        return base.Properties[name]
    end
end

local function iterateProperties()
    local properties = {}

    for name, property in pairs(extended.Properties) do
        properties[name] = property
    end

    for name, property in pairs(base.Properties) do
        if properties[name] == nil then
            properties[name] = property
        end
    end

    return properties
end

print(getDefaultProperty("Image"))