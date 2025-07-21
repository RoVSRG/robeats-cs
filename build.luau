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

-- Transform source code with Darklua
print("🔄 Transforming imports with Darklua...")
local darklua_result = process.spawn("darklua", {
	"process",
	"--config",
	".darklua.json",
	"src",
	"dist",
})

if not darklua_result.ok then
	print("❌ Darklua transformation failed:")
	print(darklua_result.stderr)
	process.exit(1)
end

print("✅ Code transformation complete!")

-- Build with Rojo
print("🏗️ Building place file with Rojo...")
local rojo_result = process.spawn("rojo", {
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
