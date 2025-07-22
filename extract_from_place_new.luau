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

-- Extract all content from place file
local function extractFromPlace(placeFile: string): boolean
	print("🔄 Extracting content from place file...")
	
	-- Define extractions - pulling FROM the place file TO the filesystem
	local extractions = {
		{ include = "ReplicatedStorage", description = "📦 Extracting ReplicatedStorage → src/shared/" },
		{ include = "ServerScriptService", description = "🖥️ Extracting ServerScriptService → src/server/" },
		{ include = "StarterPlayer.StarterPlayerScripts", description = "👤 Extracting StarterPlayerScripts → src/client/" },
		{ include = "StarterGui.Screens", description = "📱 Extracting StarterGui.Screens → src/gui/screens/" }
	}
	
	-- Run each extraction using rojo upload FROM place file
	local allSuccess = true
	for _, extraction in extractions do
		local success = runCommand("rojo", {
			"upload",
			"--include-non-strict",
			"--include", extraction.include,
			placeFile  -- Pull FROM the place file
		}, extraction.description)
		
		if not success then
			allSuccess = false
		end
	end
	
	print("📝 Note: StarterGui.Dev is for visual editing only and is not extracted")
	print("   This ScreenGui should remain in the place file for GUI design work")
	
	return allSuccess
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
