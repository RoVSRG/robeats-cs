--!strict
-- Extract from Place File Script (Lune)
-- Extracts all content from a place file according to the Rojo project structure

local process = require("@lune/process")
local fs = require("@lune/fs")

print("🏗️ Robeats Place File Extractor")
print(string.rep("=", 50))

-- Find the place file
local function findPlaceFile(): string?
	for _, entry in fs.readDir(".") do
		if entry:match("%.rbxlx?$") and not entry:match("%.lock$") then
			print("📁 Found place file: " .. entry)
			return entry
		end
	end
	return nil
end

-- Run a command and return success status
local function runCommand(command: string, args: {string}, description: string): boolean
	print(description)
	local result = process.spawn(command, args, {
		stdio = "inherit"
	})
	
	if result.ok then
		print("✅ Success")
		return true
	else
		print("⚠️ Failed with exit code: " .. tostring(result.code))
		if result.stderr and #result.stderr > 0 then
			print("Error: " .. result.stderr)
		end
		return false
	end
end

-- Write a script or module to the filesystem
local function writeScript(instance: any, basePath: string, name: string)
	local fullPath = basePath .. "/" .. name
	
	if instance.ClassName == "ModuleScript" then
		fullPath = fullPath .. ".lua"
		fs.writeFile(fullPath, instance.Source)
		print("📄 Extracted: " .. name .. ".lua")
	elseif instance.ClassName == "Script" then
		fullPath = fullPath .. ".server.lua"
		fs.writeFile(fullPath, instance.Source)
		print("📄 Extracted: " .. name .. ".server.lua")
	elseif instance.ClassName == "LocalScript" then
		fullPath = fullPath .. ".client.lua"
		fs.writeFile(fullPath, instance.Source)
		print("📄 Extracted: " .. name .. ".client.lua")
	end
end

-- Recursively extract instances from a container
local function extractInstances(container: any, basePath: string)
	for _, child in container:GetChildren() do
		if child.ClassName == "ModuleScript" or child.ClassName == "Script" or child.ClassName == "LocalScript" then
			writeScript(child, basePath, child.Name)
		elseif child.ClassName == "Folder" then
			-- Create folder and recurse
			local folderPath = basePath .. "/" .. child.Name
			if not fs.isDir(folderPath) then
				fs.writeDir(folderPath)
				print("� Created folder: " .. child.Name)
			end
			extractInstances(child, folderPath)
		else
			-- For other instances (like ScreenGuis), save as .json if they have properties worth preserving
			if child.ClassName == "ScreenGui" or child.ClassName == "Frame" or child.ClassName == "TextLabel" then
				local jsonPath = basePath .. "/" .. child.Name .. ".json"
				-- Create a basic JSON representation of the instance
				local instanceData = {
					ClassName = child.ClassName,
					Name = child.Name,
					-- Add other important properties as needed
				}
				fs.writeFile(jsonPath, game:GetService("HttpService"):JSONEncode(instanceData))
				print("📄 Extracted: " .. child.Name .. ".json")
			end
			
			-- Recurse into children regardless of type
			extractInstances(child, basePath)
		end
	end
end

-- Extract all content from place file
local function extractFromPlace(placeFileName: string): boolean
	print("🔄 Extracting content from place file...")
	
	-- Read the place file
	local placeContent = fs.readFile(placeFileName)
	local game = roblox.deserializePlace(placeContent)
	
	local success = true
	
	-- Extract ReplicatedStorage to src/shared
	print("📦 Extracting ReplicatedStorage → src/shared/")
	if game:FindFirstChild("ReplicatedStorage") then
		extractInstances(game.ReplicatedStorage, "src/shared")
	else
		print("⚠️ No ReplicatedStorage found in place file")
		success = false
	end
	
	-- Extract ServerScriptService to src/server
	print("🖥️ Extracting ServerScriptService → src/server/")
	if game:FindFirstChild("ServerScriptService") then
		extractInstances(game.ServerScriptService, "src/server")
	else
		print("⚠️ No ServerScriptService found in place file")
		success = false
	end
	
	-- Extract StarterPlayerScripts to src/client
	print("👤 Extracting StarterPlayerScripts → src/client/")
	local starterPlayer = game:FindFirstChild("StarterPlayer")
	if starterPlayer and starterPlayer:FindFirstChild("StarterPlayerScripts") then
		extractInstances(starterPlayer.StarterPlayerScripts, "src/client")
	else
		print("⚠️ No StarterPlayer.StarterPlayerScripts found in place file")
		success = false
	end
	
	-- Extract StarterGui.Screens to src/gui/screens
	print("📱 Extracting StarterGui.Screens → src/gui/screens/")
	local starterGui = game:FindFirstChild("StarterGui")
	if starterGui and starterGui:FindFirstChild("Screens") then
		extractInstances(starterGui.Screens, "src/gui/screens")
	else
		print("⚠️ No StarterGui.Screens found in place file")
		success = false
	end
	
	print("📝 Note: StarterGui.Dev is for visual editing only and is not extracted")
	print("   This ScreenGui should remain in the place file for GUI design work")
	
	return success
end

-- Create any missing directories
local function ensureDirectories()
	local dirs = {
		"src/shared",
		"src/server", 
		"src/client",
		"src/gui/screens"
	}
	
	for _, dir in dirs do
		if not fs.isDir(dir) then
			fs.writeDir(dir)
			print("📁 Created directory: " .. dir)
		end
	end
end

-- Main extraction function
local function main()
	-- Check prerequisites
	if not fs.isFile("default.project.json") then
		print("❌ default.project.json not found!")
		print("Make sure you're in the project root directory.")
		return
	end
	
	-- Find place file
	local placeFile = findPlaceFile()
	if not placeFile then
		print("❌ No place file found!")
		print("Place a .rbxl or .rbxlx file in the project root and try again.")
		return
	end
	
	-- Ensure directories exist
	ensureDirectories()
	
	-- Extract content
	local success = extractFromPlace(placeFile)
	
	if success then
		print("")
		print("✨ Extraction complete!")
		print("")
		print("📋 Next steps:")
		print("   1. Start the two-way sync: lune run scripts/sync-launcher.luau")
		print("   2. Edit scripts in VS Code (auto-syncs to Studio)")
		print("   3. Edit GUI in Studio's StarterGui.Dev and StarterGui.Screens") 
		print("   4. Save place file to auto-sync GUI changes back to repo")
		print("")
		print("🎯 Your project is now fully populated and ready for development!")
	else
		print("❌ Some extractions failed. Check the errors above.")
		print("You may need to manually verify the extracted content.")
	end
end

-- Run the extraction
main()
