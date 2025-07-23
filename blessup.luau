local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

-- Read the skins.rbxm file
local file = fs.readFile("skins.rbxm")
local skinsModel = roblox.deserializeModel(file)

-- -- Extract each top-level child as a separate rbxm file
for _, child in pairs(skinsModel) do
    local fileName = child.Name .. ".rbxm"
    local filePath = "src/skins/" .. fileName
    
    local skinFile = roblox.serializeModel({ child })
    fs.writeFile(filePath, skinFile)

    print("Extracted:", fileName)
end