--!strict
-- Directory cleanup utilities for the Studio Watcher
-- Handles safe removal of orphaned directories with comprehensive logging

local fs = require("@lune/fs")
local Encoding = require("./encoding")
local Paths = require("./paths")

local Cleanup = {}

-- Represents a directory cleanup operation result
export type CleanupResult = {
	deleted: { string },
	skipped: { string },
	errors: { string },
}

-- Create a new cleanup result
local function newCleanupResult(): CleanupResult
	return {
		deleted = {},
		skipped = {},
		errors = {},
	}
end

-- Log a cleanup action with context
local function logCleanupAction(action: string, path: string, reason: string?)
	local message = string.format("🧹 %s: %s", action, path)
	if reason then
		message = message .. " (" .. reason .. ")"
	end
	print(message)
end

-- Build a set of valid filesystem names from instances
local function buildValidNameSet(parentInstance: any): { [string]: any }
	local validNames = {}

	for _, child in parentInstance:GetChildren() do
		local sanitizedName = Encoding.sanitizeFilename(child.Name)
		validNames[sanitizedName] = child

		-- Log the mapping for debugging
		if sanitizedName ~= child.Name then
			print(string.format("📋 Name mapping: '%s' -> '%s'", child.Name, sanitizedName))
		end
	end

	return validNames
end

-- Get all directories in a target path
local function getDirectoriesInPath(targetDir: string): { string }
	local directories = {}

	if not fs.isDir(targetDir) then
		return directories
	end

	local success, entries = pcall(function()
		return fs.readDir(targetDir)
	end)

	if not success then
		logCleanupAction("ERROR", targetDir, "Failed to read directory")
		return directories
	end

	for _, entry in entries do
		local entryPath = targetDir .. "/" .. entry
		if fs.isDir(entryPath) then
			table.insert(directories, entry)
		end
	end

	return directories
end

-- Safely remove a directory with error handling
local function safeRemoveDirectory(dirPath: string, result: CleanupResult): boolean
	local success, error = pcall(function()
		fs.removeDir(dirPath)
	end)

	if success then
		table.insert(result.deleted, dirPath)
		logCleanupAction("DELETED", dirPath, "orphaned directory")
		return true
	else
		table.insert(result.errors, string.format("%s: %s", dirPath, tostring(error)))
		logCleanupAction("ERROR", dirPath, "failed to delete - " .. tostring(error))
		return false
	end
end

-- Clean orphaned directories in a target directory
function Cleanup.cleanOrphanedDirectories(parentInstance: any, targetDir: string): CleanupResult
	local result = newCleanupResult()

	-- Safety check: only operate within the screens directory
	if not Paths.isWithinScreensDir(targetDir) then
		table.insert(result.errors, "Safety check failed: path outside screens directory")
		logCleanupAction("SKIPPED", targetDir, "outside screens directory")
		return result
	end

	-- Check if target directory exists
	if not fs.isDir(targetDir) then
		logCleanupAction("SKIPPED", targetDir, "directory does not exist")
		return result
	end

	-- Build set of valid names from instances
	local validNames = buildValidNameSet(parentInstance)

	-- Get all directories in target path
	local fsDirectories = getDirectoriesInPath(targetDir)

	-- Check each directory
	for _, dirName in fsDirectories do
		if validNames[dirName] then
			-- Directory has a corresponding instance - recurse into it
			local correspondingInstance = validNames[dirName]
			local subdirPath = targetDir .. "/" .. dirName

			-- Recursively clean subdirectories
			local subResult = Cleanup.cleanOrphanedDirectories(correspondingInstance, subdirPath)

			-- Merge sub-results
			for _, deleted in subResult.deleted do
				table.insert(result.deleted, deleted)
			end
			for _, skipped in subResult.skipped do
				table.insert(result.skipped, skipped)
			end
			for _, error in subResult.errors do
				table.insert(result.errors, error)
			end
		else
			-- Directory is orphaned - mark for deletion
			local dirPath = targetDir .. "/" .. dirName
			logCleanupAction("ORPHANED", dirPath, "no corresponding instance")

			-- Attempt to remove the orphaned directory
			safeRemoveDirectory(dirPath, result)
		end
	end

	-- Summary
	if #result.deleted > 0 or #result.skipped > 0 or #result.errors > 0 then
		print(
			string.format(
				"🧹 Cleanup summary - Deleted: %d, Skipped: %d, Errors: %d",
				#result.deleted,
				#result.skipped,
				#result.errors
			)
		)
	end

	return result
end

-- Print detailed cleanup results
function Cleanup.printResults(result: CleanupResult)
	if #result.deleted > 0 then
		print("🗑️ Deleted directories:")
		for _, path in result.deleted do
			print("  " .. path)
		end
	end

	if #result.skipped > 0 then
		print("⏭️ Skipped directories:")
		for _, path in result.skipped do
			print("  " .. path)
		end
	end

	if #result.errors > 0 then
		print("❌ Errors:")
		for _, error in result.errors do
			print("  " .. error)
		end
	end
end

return Cleanup
