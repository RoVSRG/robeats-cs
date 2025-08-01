--!strict
-- Studio Place File Watcher - Auto-pulls GUI changes when Studio saves
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")

local function encodeJson(data: any): string
	return serde.encode("json", data, { pretty = true })
end

local function decodeJson(data: string): string
	return serde.decode("json", data)
end

local CHECK_INTERVAL = 1.0
local DEBOUNCE_TIME = 2.0

local BASE_DIR = "src"
local GUI_DIR = BASE_DIR .. "/gui"
local SCREENS_DIR = GUI_DIR .. "/screens"

-- === Reflection database ===
local reflectionDB = roblox.getReflectionDatabase()

-- Cross-platform place file detection
local function findPlaceFile(): string?
	for _, entry in fs.readDir(".") do
		if entry:match("%.rbxlx?$") and not entry:match("%.lock$") then
			return entry
		end
	end
	return nil
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

	-- fallback
	return #fs.readFile(path)
end

local function extractAssetUriFromImageContent(imageContent: any): string?
    local raw = tostring(imageContent)

    -- Grab ALL Uri=... matches
    local matches = {}
    for uri in raw:gmatch("Uri=([%w%p]+)") do
        table.insert(matches, uri)
    end

    -- No matches? return nil
    if #matches == 0 then return nil end

    -- Take the last match (deepest)
    local lastUri = matches[#matches]

    -- Remove any leftover Content(Uri= wrappers
    while lastUri:match("^Content%(Uri=") do
        lastUri = lastUri:gsub("^Content%(Uri=", "")
    end

    -- Remove trailing ) or >
    lastUri = lastUri:gsub("[)>]+$", "")

    return lastUri
end



-- === Rojo-compatible value serializer ===
local function serializeValue(value: any, datatype: string): any
	if value == nil then
		return nil
	end

	-- Handle specific Roblox types using Rojo's format
	if datatype == "Color3" then
		-- Rojo implicit format: [R, G, B] array
		return { value.R, value.G, value.B }
	elseif datatype == "Vector3" then
		-- Rojo implicit format: [X, Y, Z] array
		return { value.X, value.Y, value.Z }
	elseif datatype == "Vector2" then
		-- Rojo implicit format: [X, Y] array
		return { value.X, value.Y }
	elseif datatype == "UDim2" then
		-- Rojo explicit format: { "UDim2": [[Scale, Offset], [Scale, Offset]] }
		return { UDim2 = { { value.X.Scale, value.X.Offset }, { value.Y.Scale, value.Y.Offset } } }
	elseif datatype == "UDim" then
		-- Rojo explicit format: { "UDim": [Scale, Offset] }
		return { UDim = { value.Scale, value.Offset } }
	elseif datatype == "CFrame" then
		-- Rojo explicit format with position and orientation
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = value:GetComponents()
		return {
			CFrame = {
				position = { x, y, z },
				orientation = {
					{ r00, r01, r02 },
					{ r10, r11, r12 },
					{ r20, r21, r22 }
				}
			}
		}
	elseif datatype == "BrickColor" then
		-- Rojo explicit format: { "BrickColor": Number }
		return { BrickColor = value.Number }
	elseif datatype:match("^Enum%.") then
		-- Rojo explicit format: { "Enum": Value } or implicit format: "Name"
		-- Use explicit format to preserve exact enum value
		return { Enum = value.Value }
	elseif datatype == "NumberRange" then
		-- Rojo explicit format: { "NumberRange": [Min, Max] }
		return { NumberRange = { value.Min, value.Max } }
	elseif datatype == "Rect" then
		-- Rojo explicit format: { "Rect": [[MinX, MinY], [MaxX, MaxY]] }
		return { Rect = { { value.Min.X, value.Min.Y }, { value.Max.X, value.Max.Y } } }
	elseif datatype == "Ray" then
		-- Rojo explicit format: { "Ray": { "origin": [X,Y,Z], "direction": [X,Y,Z] } }
		return {
			Ray = {
				origin = { value.Origin.X, value.Origin.Y, value.Origin.Z },
				direction = { value.Direction.X, value.Direction.Y, value.Direction.Z }
			}
		}
	elseif datatype == "Font" then
		-- Rojo implicit format: { "family": string, "weight": string, "style": string }
		return {
			family = value.Family,
			weight = value.Weight.Name,
			style = value.Style.Name
		}
	elseif datatype == "Tags" then
		-- Rojo implicit format: array of strings
		local tags = {}
		for _, tag in value do
			table.insert(tags, tag)
		end
		return tags
	elseif datatype == "PhysicalProperties" then
		-- Rojo explicit format
		if value == nil then
			return { PhysicalProperties = "Default" }
		else
			return {
				PhysicalProperties = {
					density = value.Density,
					friction = value.Friction,
					elasticity = value.Elasticity,
					frictionWeight = value.FrictionWeight,
					elasticityWeight = value.ElasticityWeight
				}
			}
		end
	elseif datatype == "Content" then
		return extractAssetUriFromImageContent(value)
	elseif datatype == "ColorSequence" then
		-- Rojo explicit format
		local keypoints = {}
		for _, keypoint in value.Keypoints do
			table.insert(keypoints, {
				time = keypoint.Time,
				color = { keypoint.Value.R, keypoint.Value.G, keypoint.Value.B }
			})
		end
		return { ColorSequence = { keypoints = keypoints } }
	elseif datatype == "NumberSequence" then
		print("Serializing NumberSequence with keypoints")

		-- Rojo explicit format
		local keypoints = {}
		for _, keypoint in value.Keypoints do
			table.insert(keypoints, {
				time = keypoint.Time,
				value = keypoint.Value,
				envelope = keypoint.Envelope
			})
		end
		return { NumberSequence = { keypoints = keypoints or {} } }
	elseif type(value) == "string" then
		-- Rojo implicit format for strings
		return value
	elseif type(value) == "number" then
		-- Rojo implicit format for numbers
		return value
	elseif type(value) == "boolean" then
		-- Rojo implicit format for booleans
		return value
	else
		-- Fallback to string representation for unknown types
		return tostring(value)
	end
end

local function getFullPropertySet(className: string)
	local defaults = {}
	local properties = {}

	local currentClass = reflectionDB:GetClass(className)

	while currentClass.Superclass do
		if currentClass.Name == "Instance" then
			break
		end

		for _, prop in currentClass.Properties do
			if not properties[prop.Name] then
				properties[prop.Name] = prop
			end
		end

		for name, value in currentClass.DefaultProperties do
			if not defaults[name] then
				defaults[name] = value
			end
		end

		currentClass = reflectionDB:GetClass(currentClass.Superclass)
	end

	return {
		properties = properties,
		defaultProperties = defaults
	}
end

-- === Rojo-compatible property serializer ===
local function getInstanceProperties(instance: any): { [string]: any }
	local className = instance.ClassName
	local fullClassData = getFullPropertySet(className)
	
	local serializedProps = {}

	for _, prop in fullClassData.properties do
		local readSuccess, value = pcall(function()
			return instance[prop.Name]
		end)
		
		if readSuccess and value ~= nil then
			-- Handle NaN values by treating them as the default
			if type(value) == "number" and value ~= value then -- NaN check
				continue
			end

			local isDefault = tostring(fullClassData.defaultProperties[prop.Name]) == tostring(value)

			if isDefault and not instance:IsA("UIComponent") then
				continue
			end

			serializedProps[prop.Name] = serializeValue(value, prop.Datatype)
		end
	end

	if className == "ScreenGui" then
		serializedProps["Enabled"] = false
	end

	return serializedProps
end

-- === Rojo-compatible instance serialization ===
local function serializeInstanceToJson(instance: any): any
	return {
		["className"] = instance.ClassName,
		["properties"] = getInstanceProperties(instance),
	}
end

-- === Filename sanitization for Windows ===
local function sanitizeFilename(name: string): string
	-- Replace invalid Windows filename characters with underscores
	-- Invalid chars: < > : " | ? * and control characters (0-31)
	local sanitized = name:gsub('[<>:"|?*]', '_')
	
	-- Replace control characters (ASCII 0-31)
	sanitized = sanitized:gsub('[\0-\31]', '_')
	
	-- Remove leading/trailing spaces and dots (Windows restriction)
	sanitized = sanitized:gsub('^[%s%.]+', ''):gsub('[%s%.]+$', '')
	
	-- Ensure it's not empty
	if sanitized == '' then
		sanitized = 'unnamed'
	end
	
	-- Handle reserved Windows names
	local reservedNames = {
		'CON', 'PRN', 'AUX', 'NUL',
		'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
		'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
	}
	
	local upperName = sanitized:upper()
	for _, reserved in reservedNames do
		if upperName == reserved or upperName:match('^' .. reserved .. '%.') then
			sanitized = '_' .. sanitized
			break
		end
	end
	
	return sanitized
end

-- === Recursive export ===
local function exportInstance(instance, targetDir: string)
	local name = sanitizeFilename(instance.Name)
	local instanceDir = targetDir .. "/" .. name
	
	-- Ensure the target directory exists
	if not fs.isDir(instanceDir) then
		fs.writeDir(instanceDir)
	end

	-- Write init.meta.json for the parent itself
	local jsonData = serializeInstanceToJson(instance)
	fs.writeFile(instanceDir .. "/init.meta.json", encodeJson(jsonData))

	-- Process all children
	for _, child in ipairs(instance:GetChildren()) do
		if child:IsA("LocalScript") then
			-- LocalScript becomes .client.lua
			local scriptPath = instanceDir .. "/" .. sanitizeFilename(child.Name) .. ".client.lua"
			if not fs.isFile(scriptPath) then
				local scriptContent = child.Source or ""
				fs.writeFile(scriptPath, scriptContent)
			end
		elseif child:IsA("ModuleScript") then
			-- ModuleScript becomes .lua
			local scriptPath = instanceDir .. "/" .. sanitizeFilename(child.Name) .. ".lua"
			if not fs.isFile(scriptPath) then
				local scriptContent = child.Source or ""
				fs.writeFile(scriptPath, scriptContent)
			end
		elseif child:IsA("Script") then
			-- Script becomes .server.lua
			local scriptPath = instanceDir .. "/" .. sanitizeFilename(child.Name) .. ".server.lua"
			if not fs.isFile(scriptPath) then
				local scriptContent = child.Source or ""
				fs.writeFile(scriptPath, scriptContent)
			end
		else
			-- All other instances become folders with init.meta.json (recursive)
			exportInstance(child, instanceDir)
		end
	end
end

-- === Recursive deletion with __BASEPATH awareness ===
local function scanDeletedWithBasePath(parentInstance, targetDir: string, syncedScreenNames: {[string]: boolean})
	-- Check if target directory exists
	if not fs.isDir(targetDir) then
		return
	end
	
	-- Safety check: only operate within the screens directory
	if not targetDir:find("screens") then
		print("⚠️ Safety check: skipping deletion outside screens directory")
		return
	end
	
	print("🔍 Scanning directory:", targetDir)
	
	-- Get all directories in the target directory
	local filesystemDirs = {}
	for _, entry in fs.readDir(targetDir) do
		local entryPath = targetDir .. "/" .. entry
		if fs.isDir(entryPath) then
			filesystemDirs[entry] = true
			print("📁 Found filesystem directory:", entry)
		end
	end
	
	-- Create a set of sanitized instance names that should exist
	local validInstanceNames = {}
	for _, child in parentInstance:GetChildren() do
		local sanitizedName = sanitizeFilename(child.Name)
		validInstanceNames[sanitizedName] = child
		print("✅ Valid instance found:", child.Name, "->", sanitizedName)
	end
	
	-- Find directories that don't have corresponding instances
	for dirName, _ in filesystemDirs do
		-- Only delete if the directory doesn't have a corresponding instance
		-- AND it wasn't one of the screens we just synced from Dev
		if not validInstanceNames[dirName] and not syncedScreenNames[dirName] then
			local dirPath = targetDir .. "/" .. dirName
			print("🗑️ Deleting orphaned directory:", dirPath)
			fs.removeDir(dirPath)
		elseif validInstanceNames[dirName] then
			print("🔄 Recursively checking subdirectory:", dirName)
			-- Recursively check subdirectories for valid instances
			local correspondingInstance = validInstanceNames[dirName]
			local subdirPath = targetDir .. "/" .. dirName
			-- Recursive call for subdirectories (no syncedScreenNames needed for subdirs)
			scanDeletedWithBasePath(correspondingInstance, subdirPath, {})
		else
			print("🛡️ Preserving synced directory:", dirName)
		end
	end
end

-- === Git diff checking ===
local function displayGitDiffAfterSync()
	print("🔍 Checking git diff after sync...")
	
	-- Show detailed diff statistics
	local gitDiffStat = process.exec("git", {"diff", "--stat", "HEAD", "--", SCREENS_DIR})
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
	end
end

-- === Pull GUI from place file ===
local function pullGuiFromPlace(path: string)
	print("🎯 Studio save detected! Pulling GUI changes...")

	local file = fs.readFile(path)
	if not file then
		error("[StudioWatcher] Failed to read place file: " .. path)
		return
	end

	local game = roblox.deserializePlace(file)
	if not game then
		error("[StudioWatcher] Failed to deserialize place file: " .. path)
		return
	end

	local starterGui = game:GetService("StarterGui")
	local screens = starterGui:FindFirstChild("Screens")
	local dev = starterGui:FindFirstChild("Dev")

	if not screens then
		error("[StudioWatcher] No Screens folder found in StarterGui.")
		return
	end

	print("📦 Pulling GUI changes from Dev ScreenGui...")

	if dev then
		if #dev:GetChildren() == 0 then
			print("⚠️ No GUI elements found in Dev ScreenGui. Please add some to start two-way sync!")
			return
		end

		-- Track which screen names are being synced from Dev
		local syncedScreenNames = {}

		for _, child in dev:GetChildren() do
			-- Check for __BASEPATH attribute
			local basePath = child:GetAttribute("__BASEPATH")
			if not basePath then
				warn("⚠️ Skipping sync for '" .. child.Name .. "' - missing __BASEPATH attribute. Use the Workflow plugin to properly copy from StarterGui.Screens.")
				continue
			end

			-- Parse the base path to determine the target location
			-- Expected format: game.StarterGui.Screens.SomeScreen or similar
			local pathParts = {}
			for part in basePath:gmatch("[^%.]+") do
				table.insert(pathParts, part)
			end

			-- Validate the path structure
			if #pathParts < 4 or pathParts[1] ~= "game" or pathParts[2] ~= "StarterGui" or pathParts[3] ~= "Screens" then
				warn("⚠️ Skipping sync for '" .. child.Name .. "' - invalid __BASEPATH format: " .. basePath .. ". Expected: game.StarterGui.Screens.ScreenName")
				continue
			end

			-- Remove "game", "StarterGui", "Screens" 
			table.remove(pathParts, 1) -- Remove "game"
			table.remove(pathParts, 1) -- Remove "StarterGui" 
			table.remove(pathParts, 1) -- Remove "Screens"

			-- Extract the original instance name from the path (last part)
			local originalInstanceName = pathParts[#pathParts]

			-- Build the target directory from __BASEPATH: BASE_DIR + path except the last part
			local targetPath = SCREENS_DIR
			for i = 1, #pathParts - 1 do -- All parts except the last one (the instance name itself)
				targetPath = targetPath .. "/" .. pathParts[i]
			end

			-- Track the top-level screen name for cleanup
			local topLevelScreenName = pathParts[1]
			syncedScreenNames[topLevelScreenName] = true

			-- Clone the child and keep its original name from the __BASEPATH
			local childClone = child:Clone()
			childClone.Name = originalInstanceName
			
			-- Build the proper hierarchy in screens folder for cleanup tracking
			local currentParent = screens
			for i = 1, #pathParts do
				local partName = pathParts[i]
				local existingChild = currentParent:FindFirstChild(partName)
				
				if i == #pathParts then
					-- This is the final instance, remove any existing one and add the new clone
					if existingChild then
						existingChild:Destroy()
					end
					childClone.Parent = currentParent
					print("📝 Added to screens hierarchy:", childClone:GetFullName())
				else
					-- This is an intermediate folder, create if it doesn't exist
					if not existingChild then
						local folder = Instance.new("Folder")
						folder.Name = partName
						folder.Parent = currentParent
						currentParent = folder
						print("📁 Created intermediate folder:", folder:GetFullName())
					else
						currentParent = existingChild
					end
				end
			end

			print("📦 Exporting instance:", originalInstanceName .. " (from " .. child.Name .. " via __BASEPATH to " .. targetPath .. ")")
			exportInstance(childClone, targetPath)
		end
		
		-- Clean up orphaned directories, but preserve screens that weren't synced from Dev
		print("🧹 Cleaning up orphaned directories...")
		scanDeletedWithBasePath(screens, SCREENS_DIR, syncedScreenNames)
	else
		print("⚠️ No Dev ScreenGui found. Please make a ScreenGui named 'Dev' in StarterGui to start two-way sync!")
		return
	end

	print("✅ GUI changes pulled successfully!")
	
	-- Display git diff after sync
	displayGitDiffAfterSync()
end-- === Watcher loop ===

local function startWatching()
	print("👀 Starting Studio place file watcher...")
	print("🎮 Watching for changes to .rbxl/.rbxlx files")
	print("🛑 Press Ctrl+C to stop")

	local placeFile = findPlaceFile()
	if not placeFile then
		print("⚠️ No place files found. Make sure you have a .rbxl or .rbxlx file in the project root.")
		return
	end

	print("📁 Watching:", placeFile)

	local previousModificationTime = getModificationTime(placeFile)
	local lastChangeTime: number? = nil

	while true do
		local currentTime = os.clock()
		local modificationTime = getModificationTime(placeFile)

		if modificationTime > previousModificationTime then
			previousModificationTime = modificationTime
			lastChangeTime = currentTime
			print("📝 Change detected in:", placeFile)
		end

		if lastChangeTime and (currentTime - lastChangeTime) >= DEBOUNCE_TIME then
			pullGuiFromPlace(placeFile)
			lastChangeTime = nil
		end

		local start = os.clock()
		while os.clock() - start < CHECK_INTERVAL do end
	end
end

-- Entry point
startWatching()
