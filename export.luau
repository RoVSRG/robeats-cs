--!strict
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

-- === CONFIG ===
local PLACE_PATH = "robeats-cs.rbxl" -- path to your place file
local OUTPUT_DIR = "src" -- base folder for extracted scripts

-- === UTILS ===

-- Returns relative path inside a service (e.g. "UI/MainMenu/Init.lua")
local function getRelativePath(root: Instance, scriptInst: Instance)
    local parts = {}
    local current = scriptInst.Parent
    while current and current ~= root do
        table.insert(parts, 1, current.Name)
        current = current.Parent
    end
    return table.concat(parts, "/") .. "/" .. scriptInst.Name .. ".lua"
end

-- Save a script to the appropriate target folder
local function saveScript(targetDir: string, relPath: string, source: string)
    local fullPath = fs.join(targetDir, relPath)
    local folder = fullPath:match("(.+)/[^/]+$") -- strip filename
    if not fs.isDir(folder) then
        fs.mkdir(folder, true)
    end
    fs.writeFile(fullPath, source)
    print("[Extracted]", fullPath)
end

-- Process a container service (ReplicatedStorage, StarterPlayerScripts, etc.)
local function processContainer(service: Instance, targetDir: string)
    for _, descendant in service:GetDescendants() do
        if descendant:IsA("ModuleScript") or descendant:IsA("LocalScript") or descendant:IsA("Script") then
            local relPath = getRelativePath(service, descendant)
            saveScript(targetDir, relPath, descendant.Source)
        end
    end
end

-- === MAIN ===

print("[*] Checking if place file exists:", PLACE_PATH)
if not fs.isFile(PLACE_PATH) then
    print("[!] Place file not found:", PLACE_PATH)
    print("[!] Please ensure the place file exists and try again.")
    return
end

print("[*] Loading place:", PLACE_PATH)
local placeFile = fs.readFile(PLACE_PATH)

print("[*] Attempting to deserialize place file...")
local success, place = pcall(roblox.deserializePlace, placeFile)
if not success then
    print("[!] Failed to deserialize place file:", place)
    print("[!] This may be due to:")
    print("    - Place file format incompatibility")
    print("    - Corrupted place file")
    print("    - Unsupported Roblox features in the place")
    return
end

print("[✓] Place file loaded successfully!")

-- Get services
local replicatedStorage = place:FindFirstChild("ReplicatedStorage")
local starterPlayer = place:FindFirstChild("StarterPlayer")
local serverScriptService = place:FindFirstChild("ServerScriptService")

-- Paths for each group
local sharedDir = fs.join(OUTPUT_DIR, "shared")
local clientDir = fs.join(OUTPUT_DIR, "client")
local serverDir = fs.join(OUTPUT_DIR, "server")

-- Process ReplicatedStorage → src/shared
if replicatedStorage then
    print("[*] Extracting ReplicatedStorage scripts ->", sharedDir)
    processContainer(replicatedStorage, sharedDir)
else
    print("[!] No ReplicatedStorage found")
end

-- Process StarterPlayerScripts → src/client
if starterPlayer then
    local starterPlayerScripts = starterPlayer:FindFirstChild("StarterPlayerScripts")
    if starterPlayerScripts then
        print("[*] Extracting StarterPlayerScripts ->", clientDir)
        processContainer(starterPlayerScripts, clientDir)
    else
        print("[!] No StarterPlayerScripts found")
    end
else
    print("[!] No StarterPlayer found")
end

-- Process ServerScriptService → src/server
if serverScriptService then
    print("[*] Extracting ServerScriptService scripts ->", serverDir)
    processContainer(serverScriptService, serverDir)
else
    print("[!] No ServerScriptService found")
end

print("[✓] Extraction complete!")