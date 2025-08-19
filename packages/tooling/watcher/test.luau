--!strict
-- Basic validation tests for the refactored watcher modules

local Paths = require("./paths")
local Encoding = require("./encoding") 
local Watcher = require("./watcher")

-- Test suite
local function runTests()
	print("🧪 Running basic validation tests...")
	
	-- Test path parsing
	print("\n📍 Testing path parsing:")
	local pathParts = Paths.parseRobloxPath("game.StarterGui.Screens.MainMenu")
	print("✅ Parsed path parts:", table.concat(pathParts, ", "))
	assert(pathParts[1] == "game", "Expected 'game' as first part")
	assert(pathParts[4] == "MainMenu", "Expected 'MainMenu' as fourth part")
	
	-- Test base path validation
	print("\n🔍 Testing base path validation:")
	local isValid, error = Paths.validateBasePath("game.StarterGui.Screens.MainMenu")
	assert(isValid, "Valid path should pass validation")
	print("✅ Valid path validation passed")
	
	local isInvalid, invalidError = Paths.validateBasePath("invalid.path")
	assert(not isInvalid, "Invalid path should fail validation")
	print("✅ Invalid path validation passed:", invalidError)
	
	-- Test relative path extraction
	print("\n📂 Testing relative path extraction:")
	local relativePath, pathError = Paths.extractRelativePath("game.StarterGui.Screens.MainMenu.SubMenu")
	assert(not pathError, "Should not have error for valid path")
	assert(relativePath == "MainMenu/SubMenu", "Relative path should be MainMenu/SubMenu, got: " .. tostring(relativePath))
	print("✅ Relative path extraction passed:", relativePath)
	
	-- Test filename sanitization
	print("\n🧹 Testing filename sanitization:")
	local sanitized = Encoding.sanitizeFilename("My<Script>Name")
	assert(sanitized == "My_Script_Name", "Should replace invalid characters with underscores")
	print("✅ Filename sanitization passed:", sanitized)
	
	-- Test place file detection
	print("\n🔎 Testing place file detection:")
	local placeFile = Watcher.getPlaceFile()
	if placeFile then
		print("✅ Found place file:", placeFile)
	else
		print("⚠️ No place file found (this might be expected if no .rbxl/.rbxlx files exist)")
	end
	
	print("\n🎉 All basic validation tests completed!")
	return true
end

-- Run the tests
local success, error = pcall(runTests)

if success then
	print("✅ Test suite completed successfully")
else
	print("❌ Test suite failed:", error)
	os.exit(1)
end