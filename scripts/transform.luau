--!strict
-- Transform script to convert @shared/ imports to game.ReplicatedStorage
local fs = require("@lune/fs")

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

local function processDirectory(inputDir: string, outputDir: string)
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
			print("  Transformed: " .. entry)
		end
	end
end

print("🔄 Transforming source files...")
processDirectory("src", "dist")
print("✅ Transformation complete!")
