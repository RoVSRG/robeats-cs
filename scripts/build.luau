--!strict
-- Build script for robeats-cs-scripts
-- Transforms @shared/xxx imports to game.ReplicatedStorage.xxx using Darklua
-- Then builds the place file using Rojo

local process = require("@lune/process")
local fs = require("@lune/fs")

print("🔨 Building robeats-cs-scripts...")

-- Clean dist directory
print("🧹 Cleaning dist directory...")
if fs.isDir("dist") then
	fs.removeDir("dist")
end
fs.writeDir("dist")

-- Transform source code
print("🔄 Transforming @shared/ imports...")

local function transformFile(inputPath, outputPath)
	local content = fs.readFile(inputPath)

	-- Create output directory if needed
	local outputDir = outputPath:match("(.+)/[^/]+$")
	if outputDir and not fs.isDir(outputDir) then
		fs.writeDir(outputDir)
	end

	fs.writeFile(outputPath, content)
end

local function processDirectory(inputDir, outputDir)
	if not fs.isDir(outputDir) then
		fs.writeDir(outputDir)
	end

	for _, entry in fs.readDir(inputDir) do
		local inputPath = inputDir .. "/" .. entry
		local outputPath = outputDir .. "/" .. entry

		if fs.isDir(inputPath) then
			processDirectory(inputPath, outputPath)
		elseif entry:match("%.lua$") or entry:match("%.luau$") then
			transformFile(inputPath, outputPath)
		end
	end
end

processDirectory("src", "dist")

print("✅ Code transformation complete!")

-- Build with Rojo
print("🏗️ Building place file with Rojo...")
local rojo_result = process.exec("rojo", {
	"build",
	"--output",
	"robeats-cs-built.rbxl",
	"build.project.json",
})

if not rojo_result.ok then
	print("❌ Rojo build failed:")
	print(rojo_result.stderr)
	process.exit(1)
end

print("✅ Build complete! Output: robeats-cs-built.rbxl")
print("📦 You can now sync this file to Roblox Studio or upload it to Roblox.")
