local roblox = require("@lune/roblox")
local reflectionDB = roblox.getReflectionDatabase()

print(reflectionDB:GetClass("UIGradient").Properties.Transparency.Datatype)