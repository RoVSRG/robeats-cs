--!strict
-- Roblox Place File Script Exporter
-- Extracts scripts from a Roblox place file and organizes them according to the project structure.
-- Also transforms game.ReplicatedStorage calls to use @shared/... require syntax.
-- Supports blacklisting folders to exclude from extraction.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

-- === CONFIG ===
local PLACE_PATH = "robeats-cs.rbxl" -- path to your place file
local OUTPUT_DIR = "src" -- base folder for extracted scripts

-- Folders to exclude from extraction (case-sensitive)
local BLACKLISTED_FOLDERS = {
    "Design",
    "Remotes", 
    "Serialization",
    "Skins",
    "Templates",
    "Libraries"
}

-- === UTILS ===

-- Check if a path contains any blacklisted folders
local function isPathBlacklisted(instance: Instance, root: Instance): boolean
    local current: Instance? = instance
    while current and current ~= root do
        for _, blacklistedName in BLACKLISTED_FOLDERS do
            if current.Name == blacklistedName then
                return true
            end
        end
        current = current.Parent
    end
    return false
end

-- Transform game.ReplicatedStorage calls to @shared/ syntax within require()
local function transformSource(source: string): string
    -- Only transform game.ReplicatedStorage.xxx within require() calls
    -- Pattern: require(game.ReplicatedStorage.xxx) -> require("@shared/xxx")
    source = source:gsub('require%(game%.ReplicatedStorage%.([%w_.]+)%)', function(path)
        -- Convert dots to forward slashes for the require path
        local requirePath = path:gsub("%.", "/")
        return 'require("@shared/' .. requirePath .. '")'
    end)
    
    return source
end

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
    -- Transform the source code to replace game.ReplicatedStorage calls
    local transformedSource = transformSource(source)
    
    -- Log if any transformations were made
    if transformedSource ~= source then
        print("[Transformed]", relPath, "- replaced game.ReplicatedStorage calls with @shared/... syntax")
    end
    
    local fullPath = targetDir .. "/" .. relPath
    local folder = fullPath:match("(.+)/[^/]+$") -- strip filename
    if not fs.isDir(folder) then
        fs.writeDir(folder)
    end
    fs.writeFile(fullPath, transformedSource)
    print("[Extracted]", fullPath)
end

-- Process a container service (ReplicatedStorage, StarterPlayerScripts, etc.)
local function processContainer(service: Instance, targetDir: string)
    for _, descendant in service:GetDescendants() do
        if descendant:IsA("ModuleScript") or descendant:IsA("LocalScript") or descendant:IsA("Script") then
            -- Check if this script is in a blacklisted folder
            if not isPathBlacklisted(descendant, service) then
                local relPath = getRelativePath(service, descendant)
                saveScript(targetDir, relPath, descendant.Source)
            else
                local relPath = getRelativePath(service, descendant)
                print("[Skipped]", relPath, "- in blacklisted folder")
            end
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
local sharedDir = OUTPUT_DIR .. "/shared"
local clientDir = OUTPUT_DIR .. "/client"
local serverDir = OUTPUT_DIR .. "/server"

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