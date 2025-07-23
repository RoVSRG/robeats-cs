--!strict
-- Studio Place File Watcher - Auto-pulls GUI changes when Studio saves
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local CHECK_INTERVAL = 1.0 -- Check every second
local DEBOUNCE_TIME = 2.0 -- Wait 2 seconds after last change before pulling

-- Cross-platform place file detection
local function findPlaceFile(): string?
	local file

	for _, entry in fs.readDir(".") do
		if entry:match("%.rbxlx?$") and not entry:match("%.lock$") then
			file = entry
			break
		end
	end

	return file
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

-- Custom implementation of FindFirstChildWhichIsA for Lune Roblox instances
local function findFirstChildWhichIsA(parent: any, className: string): any?
	for _, child in parent:GetChildren() do
		if child.ClassName == className then
			return child
		end
	end
	return nil
end

local BASE_DIR = "src"
local GUI_DIR = BASE_DIR .. "/gui"
local SCREENS_DIR = GUI_DIR .. "/screens"

-- Run Rojo sourcemap generation and GUI pull
local function pullGuiFromPlace(path: string)
	print("🎯 Studio save detected! Pulling GUI changes...")

	local file = fs.readFile(path)
	if not file then
		error("[StudioWatcher] Failed to read place file:", path)
		return
	end

	local game = roblox.deserializePlace(file)
	if not game then
		error("[StudioWatcher] Failed to deserialize place file:", path)
		return
	end

	local starterGui = game:GetService("StarterGui")
	local screens = starterGui:FindFirstChild("Screens")
	local dev = starterGui:FindFirstChild("Dev")

	if not screens then
		error("[StudioWatcher] No Screens folder found in StarterGui.")
		return
	end

	if not dev then
		warn("[StudioWatcher] No Dev folder found in StarterGui. Moving on...")
		return
	end

	print("📦 Pulling GUI changes from place file...")

	for _, screen in screens:GetChildren() do
		if screen.ClassName == "Frame" then
			local fileName = screen.Name .. ".rbxm"
			local screenPath = SCREENS_DIR .. "/" .. fileName
			
			-- Serialize and save the screen
			local serializedModel = roblox.serializeModel({screen})
			fs.writeFile(screenPath, serializedModel)

			print("💾 Saved: " .. fileName)
		end
	end

	if dev then
		local screen = findFirstChildWhichIsA(dev, "Frame")

		if screen then
			local fileName = screen.Name .. ".rbxm"
			local screenPath = SCREENS_DIR .. "/" .. fileName
	
			local serializedModel = roblox.serializeModel({screen})
			fs.writeFile(screenPath, serializedModel)
		end
	end

	print("✅ GUI changes pulled successfully!")
end

-- Main watcher loop
local function startWatching()
	print("👀 Starting Studio place file watcher...")
	print("🎮 Watching for changes to .rbxl/.rbxlx files")
	print("🛑 Press Ctrl+C to stop")

	local placeFile = findPlaceFile()
	if not placeFile then
		print("⚠️ No place files found. Make sure you have a .rbxl or .rbxlx file in the project root.")
		return
	end

	print("📁 Watching: " .. placeFile)

	local previousModificationTime: number = getModificationTime(placeFile)
	local lastChangeTime: number? = nil

	while true do
		-- Check for file changes
		local currentTime = os.clock()

		local modificationTime = getModificationTime(placeFile)
		if modificationTime > previousModificationTime then
			previousModificationTime = modificationTime
			lastChangeTime = currentTime
			print("📝 Change detected in: " .. placeFile)
		end
		
		-- If we have changes and enough time has passed (debounce), pull
		if lastChangeTime and (currentTime - lastChangeTime) >= DEBOUNCE_TIME then
			pullGuiFromPlace(placeFile)
			lastChangeTime = nil -- Reset after pulling
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
