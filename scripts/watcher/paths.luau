--!strict
-- Path parsing and validation utilities for the Studio Watcher

local Paths = {}

-- Constants
Paths.BASE_DIR = "roblox/src"
Paths.GUI_DIR = Paths.BASE_DIR .. "/gui"
Paths.SCREENS_DIR = Paths.GUI_DIR .. "/screens"

-- Parse a Roblox-style dotted path (e.g., "game.StarterGui.Screens.MainMenu")
function Paths.parseRobloxPath(path: string, up: number?): { string }
	local pathParts = {}
	
	for part in path:gmatch("[^%.]+") do
		table.insert(pathParts, part)
	end
	
	if up and up > 0 then
		for i = 1, up do
			table.remove(pathParts)
		end
	end
	
	return pathParts
end

-- Validate that a __BASEPATH follows the expected format
function Paths.validateBasePath(basePath: string): (boolean, string?)
	local pathParts = Paths.parseRobloxPath(basePath)
	
	if #pathParts < 3 then
		return false, "Path too short - expected at least game.StarterGui.Screens"
	end
	
	if pathParts[1] ~= "game" then
		return false, "Path must start with 'game'"
	end
	
	if pathParts[2] ~= "StarterGui" then
		return false, "Path must include 'StarterGui' as second component"
	end
	
	if pathParts[3] ~= "Screens" then
		return false, "Path must include 'Screens' as third component"
	end
	
	return true, nil
end

-- Extract the relative path from a __BASEPATH (removes game.StarterGui.Screens prefix)
function Paths.extractRelativePath(basePath: string): (string?, string?)
	local isValid, error = Paths.validateBasePath(basePath)
	if not isValid then
		return nil, error
	end
	
	local pathParts = Paths.parseRobloxPath(basePath)
	
	-- Remove "game", "StarterGui", "Screens"
	table.remove(pathParts, 1)
	table.remove(pathParts, 1) 
	table.remove(pathParts, 1)
	
	return table.concat(pathParts, "/"), nil
end

-- Build the full target directory path from a relative path
function Paths.buildTargetPath(relativePath: string?): string
	if not relativePath or relativePath == "" then
		return Paths.SCREENS_DIR
	end
	return Paths.SCREENS_DIR .. "/" .. relativePath
end

-- Check if a path is within the screens directory (safety check)
function Paths.isWithinScreensDir(targetDir: string): boolean
	return targetDir:find("screens", 1, true) ~= nil
end

-- Build instance directory path
function Paths.buildInstancePath(targetDir: string, instanceName: string): string
	return targetDir .. "/" .. instanceName
end

return Paths