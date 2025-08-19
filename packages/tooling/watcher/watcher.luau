--!strict
-- File watching utilities for the Studio Watcher
-- Handles monitoring place file changes and triggering sync operations

local fs = require("@lune/fs")
local Sync = require("./sync")

local Watcher = {}

-- Configuration constants
local CHECK_INTERVAL = 1.0
local DEBOUNCE_TIME = 2.0

-- Cross-platform place file detection
local function findPlaceFile(): string?
	local success, entries = pcall(function()
		return fs.readDir(".")
	end)
	
	if not success then
		return nil
	end
	
	for _, entry in entries do
		if entry:match("%.rbxlx?$") and not entry:match("%.lock$") then
			return entry
		end
	end
	return nil
end

-- Get modification time of a file with fallback
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
	
	-- Fallback to file size (less reliable but better than nothing)
	local sizeSuccess, size = pcall(function()
		return #fs.readFile(path)
	end)
	
	return sizeSuccess and size or 0
end

-- Watch loop state
export type WatcherState = {
	placeFile: string,
	previousModTime: number,
	lastChangeTime: number?
}

-- Create initial watcher state
local function createWatcherState(placeFile: string): WatcherState
	return {
		placeFile = placeFile,
		previousModTime = getModificationTime(placeFile),
		lastChangeTime = nil
	}
end

-- Check if file has been modified
local function checkForChanges(state: WatcherState): boolean
	local currentTime = os.clock()
	local modificationTime = getModificationTime(state.placeFile)
	
	if modificationTime > state.previousModTime then
		state.previousModTime = modificationTime
		state.lastChangeTime = currentTime
		print(string.format("📝 Change detected in: %s", state.placeFile))
		return true
	end
	
	return false
end

-- Check if debounce period has elapsed
local function shouldSync(state: WatcherState): boolean
	if not state.lastChangeTime then
		return false
	end
	
	local currentTime = os.clock()
	return (currentTime - state.lastChangeTime) >= DEBOUNCE_TIME
end

-- Process sync and reset change tracking
local function processSyncOperation(state: WatcherState)
	print("🚀 Debounce period elapsed, starting sync...")
	
	local syncResult = Sync.pullGuiFromPlace(state.placeFile)
	
	if syncResult.success then
		print(string.format("✅ Sync completed successfully! Processed %d children", syncResult.childrenProcessed))
		if not syncResult.changesDetected then
			print("📭 No filesystem changes resulted from sync")
		end
	else
		print(string.format("❌ Sync failed: %s", syncResult.error or "Unknown error"))
	end
	
	-- Reset change tracking
	state.lastChangeTime = nil
end

-- Sleep for the check interval
local function sleepInterval()
	local start = os.clock()
	while os.clock() - start < CHECK_INTERVAL do
		-- Busy wait (could be improved with a proper sleep function)
	end
end

-- Print startup banner
local function printStartupBanner(placeFile: string)
	print("=" .. string.rep("=", 50) .. "=")
	print("👀 Studio Place File Watcher")
	print("=" .. string.rep("=", 50) .. "=")
	print("🎮 Watching for changes to .rbxl/.rbxlx files")
	print("📁 Target file: " .. placeFile)
	print("⏱️  Check interval: " .. CHECK_INTERVAL .. "s")
	print("⏳ Debounce time: " .. DEBOUNCE_TIME .. "s")
	print("🛑 Press Ctrl+C to stop")
	print("=" .. string.rep("=", 50) .. "=")
end

-- Start watching for file changes
function Watcher.startWatching(): boolean
	local placeFile = findPlaceFile()
	if not placeFile then
		print("⚠️ No place files found. Make sure you have a .rbxl or .rbxlx file in the project root.")
		return false
	end
	
	printStartupBanner(placeFile)
	
	local state = createWatcherState(placeFile)
	
	while true do
		-- Check for file changes
		local changed = checkForChanges(state)
		
		-- Process sync if debounce period has elapsed
		if shouldSync(state) then
			processSyncOperation(state)
		end
		
		-- Sleep until next check
		sleepInterval()
	end
end

-- Get the currently watched place file (for testing/debugging)
function Watcher.getPlaceFile(): string?
	return findPlaceFile()
end

-- Get modification time for a file (for testing/debugging)
function Watcher.getFileModTime(path: string): number
	return getModificationTime(path)
end

return Watcher