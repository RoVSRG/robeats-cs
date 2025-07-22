--!strict
-- Studio Place File Watcher - Auto-pulls GUI changes when Studio saves
local process = require("@lune/process")
local fs = require("@lune/fs")

local CHECK_INTERVAL = 1.0 -- Check every second
local DEBOUNCE_TIME = 2.0 -- Wait 2 seconds after last change before pulling

-- Cross-platform place file detection
local function findPlaceFiles(): { string }
	local files = {}
	for _, entry in fs.readDir(".") do
		if entry:match("%.rbxlx?$") and not entry:match("%.lock$") then
			table.insert(files, entry)
		end
	end
	return files
end

-- Get modification time of a file
local function getModificationTime(path: string): number
	if not fs.isFile(path) then
		return 0
	end
	
	local success, result = pcall(function()
		return fs.metadata(path).modifiedAt
	end)
	
	if success and result then
		return result
	end
	
	-- Fallback to file size
	return #fs.readFile(path)
end

-- Run Rojo sourcemap generation and GUI pull
local function pullGuiFromStudio()
	print("🎯 Studio save detected! Pulling GUI changes...")
	
	-- First, generate sourcemap to ensure Rojo knows the current state
	print("📋 Generating sourcemap...")
	local sourcemapResult = process.spawn("rojo", {
		"sourcemap",
		"default.project.json",
		"--output", "sourcemap.json"
	})
	
	if not sourcemapResult.ok then
		print("❌ Failed to generate sourcemap:")
		print(sourcemapResult.stderr)
		return false
	end
	
	-- Pull Dev ScreenGui changes (where you visually edit)
	print("⬇️ Pulling StarterGui.Dev changes...")
	local devPullResult = process.spawn("rojo", {
		"upload",
		"--include-non-strict", 
		"--include", "StarterGui.Dev",
		"default.project.json"
	})
	
	if not devPullResult.ok then
		print("❌ Failed to pull Dev changes:")
		print(devPullResult.stderr)
		return false
	end
	
	-- Pull Screens Folder changes (the runtime screens)
	print("⬇️ Pulling StarterGui.Screens changes...")
	local screensPullResult = process.spawn("rojo", {
		"upload",
		"--include-non-strict",
		"--include", "StarterGui.Screens", 
		"default.project.json"
	})
	
	if screensPullResult.ok then
		print("✅ GUI changes pulled successfully!")
		print("   📱 Dev ScreenGui → Available for visual editing")
		print("   📂 Screens Folder → src/gui/screens/")
		
		-- Optional: Auto-commit the changes
		local gitResult = process.spawn("git", {
			"add", "src/gui/"
		})
		
		if gitResult.ok then
			local commitResult = process.spawn("git", {
				"commit", "-m", "Auto-sync GUI from Studio (Dev + Screens)", "--allow-empty"
			})
			if commitResult.ok then
				print("📝 Changes auto-committed to Git")
			end
		end
		
		return true
	else
		print("❌ Failed to pull Screens changes:")
		print(screensPullResult.stderr)
		return false
	end
end

-- Main watcher loop
local function startWatching()
	print("👀 Starting Studio place file watcher...")
	print("🎮 Watching for changes to .rbxl/.rbxlx files")
	print("🛑 Press Ctrl+C to stop")
	
	local placeFiles = findPlaceFiles()
	if #placeFiles == 0 then
		print("⚠️ No place files found. Make sure you have a .rbxl or .rbxlx file in the project root.")
		return
	end
	
	for _, file in placeFiles do
		print("📁 Watching: " .. file)
	end
	
	local lastModTimes: { [string]: number } = {}
	local lastChangeTime = 0
	
	-- Initialize modification times
	for _, file in placeFiles do
		lastModTimes[file] = getModificationTime(file)
	end
	
	while true do
		-- Check for file changes
		local currentTime = os.clock()
		
		for _, file in placeFiles do
			local currentModTime = getModificationTime(file)
			if currentModTime > lastModTimes[file] then
				lastModTimes[file] = currentModTime
				lastChangeTime = currentTime
				print("📝 Change detected in: " .. file)
			end
		end
		
		-- If we have changes and enough time has passed (debounce), pull
		if lastChangeTime > 0 and (currentTime - lastChangeTime) >= DEBOUNCE_TIME then
			pullGuiFromStudio()
			lastChangeTime = 0 -- Reset
		end
		
		-- Sleep before next check
		local start = os.clock()
		while os.clock() - start < CHECK_INTERVAL do
			-- Busy wait
		end
	end
end

-- Entry point
startWatching()
