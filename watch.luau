--!strict
-- File watcher script to automatically transform files on save
local process = require("@lune/process")
local fs = require("@lune/fs")

-- Import the transformation logic from transform.luau
local function transformFile(inputPath: string, outputPath: string)
	local content = fs.readFile(inputPath)

	-- Transform @shared/xxx imports to game.ReplicatedStorage.xxx
	-- Handle both double and single quotes
	content = content:gsub('require%("@shared/([^"]*)"%)', function(path)
		local dotPath = path:gsub("/", ".")
		return "require(game.ReplicatedStorage." .. dotPath .. ")"
	end)

	content = content:gsub("require%('@shared/([^']*)%'%)", function(path)
		local dotPath = path:gsub("/", ".")
		return "require(game.ReplicatedStorage." .. dotPath .. ")"
	end)

	-- Create output directory if needed
	local outputDir = outputPath:match("(.+)/[^/]+$")
	if outputDir and not fs.isDir(outputDir) then
		fs.writeDir(outputDir)
	end

	fs.writeFile(outputPath, content)
end

local function getModificationTime(path: string): number
	-- Simple implementation - in a real scenario you'd want proper file stat
	-- For now, we'll use file size + current time as a simple heuristic
	if fs.isFile(path) then
		return #fs.readFile(path) + os.time()
	end
	return 0
end

local function scanForChanges(directory: string, lastScan: { [string]: number }): { [string]: number }
	local currentScan = {}

	local function scanDirectory(dir: string, prefix: string)
		for _, entry in fs.readDir(dir) do
			local fullPath = dir .. "/" .. entry
			local relativePath = prefix .. entry

			if fs.isDir(fullPath) then
				scanDirectory(fullPath, relativePath .. "/")
			elseif entry:match("%.lua$") or entry:match("%.luau$") then
				local modTime = getModificationTime(fullPath)
				currentScan[relativePath] = modTime

				-- Check if file has changed
				if not lastScan[relativePath] or lastScan[relativePath] ~= modTime then
					local outputPath = "dist/" .. relativePath
					transformFile(fullPath, outputPath)
					print("🔄 Transformed: " .. relativePath)
				end
			end
		end
	end

	scanDirectory(directory, "")
	return currentScan
end

print("👀 Starting file watcher for src/ directory...")
print("📁 Files will be automatically transformed to dist/ on change")
print("🛑 Press Ctrl+C to stop")

-- Ensure dist directory exists
if not fs.isDir("dist") then
	fs.writeDir("dist")
end

-- Initial scan and transform
print("🔄 Performing initial transformation...")
local lastScan = scanForChanges("src", {})
print("✅ Initial transformation complete")

-- Watch loop
while true do
	-- Wait a bit before scanning again
	process.spawn("sleep", { "1" })

	-- Scan for changes
	lastScan = scanForChanges("src", lastScan)
end
