--!strict
-- GUI synchronization utilities for the Studio Watcher
-- Handles pulling GUI changes from Roblox place files

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local Encoding = require("./encoding")
local Paths = require("./paths")
local Export = require("./export")
local Cleanup = require("./cleanup")

local Sync = {}

export type SyncResult = {
	success: boolean,
	error: string?,
	childrenProcessed: number,
	changesDetected: boolean,
}

-- Display git diff statistics after sync
local function displayGitDiffAfterSync()
	print("🔍 Checking git diff after sync...")

	local gitDiffStat = process.exec("git", { "diff", "--stat", "HEAD", "--", Paths.SCREENS_DIR })
	if gitDiffStat.ok and #gitDiffStat.stdout > 0 then
		print("📊 Changes summary:")

		-- Split output into lines and count them
		local lines = {}
		for line in gitDiffStat.stdout:gmatch("[^\r\n]+") do
			table.insert(lines, line)
		end

		-- Show first 10 entries
		local maxEntries = 10
		for i = 1, math.min(maxEntries, #lines) do
			print(lines[i])
		end

		-- Show count of remaining entries if there are more
		if #lines > maxEntries then
			local remaining = #lines - maxEntries
			print(string.format("... and %d more changes", remaining))
		end

		return true
	else
		print("📭 No changes detected")
		return false
	end
end

-- Validate and process a child instance from Dev container
local function processDevChild(child: any, basePath: string): boolean
	local relativePath, pathError = Paths.extractRelativePath(basePath)
	if pathError then
		print(string.format("❌ Invalid __BASEPATH for %s: %s", child.Name, pathError))
		return false
	end

	local childName = Encoding.sanitizeFilename(child.Name)
	local targetPath = Paths.buildTargetPath(relativePath)

	print(string.format("🔄 Processing child: %s", child.Name))
	print(string.format("📍 Target path: %s", targetPath))

	-- Clone the child and keep its original name from the __BASEPATH
	local childClone = child:Clone()
	childClone.Name = childName

	-- Export the instance
	local exportSuccess = Export.exportInstance(childClone, targetPath)
	if not exportSuccess then
		print(string.format("❌ Failed to export %s", childName))
		return false
	end

	-- Clean up orphaned directories
	print("🧹 Cleaning up orphaned directories...")
	local instancePath = Paths.buildInstancePath(targetPath, childName)
	local cleanupResult = Cleanup.cleanOrphanedDirectories(child, instancePath)

	if #cleanupResult.errors > 0 then
		print(string.format("⚠️ Cleanup had %d errors for %s", #cleanupResult.errors, childName))
		Cleanup.printResults(cleanupResult)
	end

	return true
end

-- Pull GUI changes from Dev container
function Sync.pullFromDevContainer(dev: any): SyncResult
	local result: SyncResult = {
		success = false,
		error = nil,
		childrenProcessed = 0,
		changesDetected = false,
	}

	if #dev:GetChildren() == 0 then
		result.error = "No GUI elements found in Dev ScreenGui. Please add some to start two-way sync!"
		return result
	end

	local basePath = dev:GetAttribute("__BASEPATH")
	if not basePath then
		result.error =
			"Dev container missing __BASEPATH attribute. Use the Workflow plugin to properly copy from StarterGui.Screens."
		return result
	end

	-- Validate the base path format
	local isValidPath, pathError = Paths.validateBasePath(basePath)
	if not isValidPath then
		result.error = string.format(
			"Invalid __BASEPATH format: %s. Expected: game.StarterGui.Screens.xxx (%s)",
			basePath,
			pathError
		)
		return result
	end

	print(string.format("📦 Processing %d children from Dev container", #dev:GetChildren()))

	-- Process each child
	for _, child in dev:GetChildren() do
		local childSuccess = processDevChild(child, basePath)
		if childSuccess then
			result.childrenProcessed = result.childrenProcessed + 1
		else
			print(string.format("⚠️ Failed to process child: %s", child.Name))
		end
	end

	if result.childrenProcessed > 0 then
		result.success = true
		result.changesDetected = displayGitDiffAfterSync()
		print(string.format("✅ Successfully processed %d children", result.childrenProcessed))
	else
		result.error = "No children were successfully processed"
	end

	return result
end

-- Pull GUI changes from place file
function Sync.pullGuiFromPlace(placePath: string): SyncResult
	local result: SyncResult = {
		success = false,
		error = nil,
		childrenProcessed = 0,
		changesDetected = false,
	}

	print("🎯 Studio save detected! Pulling GUI changes...")

	-- Read place file
	local fileSuccess, file = pcall(function()
		return fs.readFile(placePath)
	end)

	if not fileSuccess or not file then
		result.error = string.format("Failed to read place file: %s", placePath)
		return result
	end

	-- Deserialize place file
	local gameSuccess, game = pcall(function()
		return roblox.deserializePlace(file)
	end)

	if not gameSuccess or not game then
		result.error = string.format("Failed to deserialize place file: %s", placePath)
		return result
	end

	-- Find required services and containers
	local starterGui = game:GetService("StarterGui")
	local screens = starterGui:FindFirstChild("Screens")
	local dev = starterGui:FindFirstChild("Dev")

	if not screens then
		result.error = "No Screens folder found in StarterGui"
		return result
	end

	if not dev then
		result.error =
			"No Dev ScreenGui found. Please make a ScreenGui named 'Dev' in StarterGui to start two-way sync!"
		return result
	end

	print("📦 Pulling GUI changes from Dev ScreenGui...")
	return Sync.pullFromDevContainer(dev)
end

return Sync
