--!strict
-- Instance export utilities for the Studio Watcher
-- Handles serialization of Roblox instances to filesystem

local fs = require("@lune/fs")
local serde = require("@lune/serde")
local Encoding = require("./encoding")
local Reflection = require("./reflection")

local Export = {}

-- Encode data to JSON with pretty formatting
local function encodeJson(data: any): string
	return serde.encode("json", data, { pretty = true })
end

-- Get instance properties for serialization
local function getInstanceProperties(instance: any, forcedProps: { [string]: boolean }?): { [string]: any }
	local className = instance.ClassName
	local fullClassData = Reflection.getFullPropertySet(className)
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
			local forceWrite = forcedProps ~= nil and forcedProps[prop.Name] == true

			-- Skip default-valued properties unless:
			-- 1) this is a UIComponent (we keep all), or
			-- 2) the property previously existed in meta and needs to be written to force Studio to sync back to default
			if isDefault and not instance:IsA("UIComponent") and not forceWrite then
				continue
			end

			serializedProps[prop.Name] = Encoding.serializeValue(value, prop.Datatype)
		end
	end

	-- Handle tags
	local tags = {}
	for _, tag in instance:GetTags() do
		table.insert(tags, tag)
	end

	if #tags > 0 then
		serializedProps["Tags"] = tags
	end

	-- Special handling for ScreenGui
	if className == "ScreenGui" then
		serializedProps["Enabled"] = false
	end

	return serializedProps
end

-- Serialize instance to JSON format
local function serializeInstanceToJson(instance: any, forcedProps: { [string]: boolean }?): any
	return {
		["className"] = instance.ClassName,
		["properties"] = getInstanceProperties(instance, forcedProps),
	}
end

-- Get existing properties from meta file for forced property writing
local function getForcedPropsFromMeta(metaPath: string): { [string]: boolean }
	local forcedProps: { [string]: boolean } = {}

	if not fs.isFile(metaPath) then
		return forcedProps
	end

	local success, content = pcall(function()
		return fs.readFile(metaPath)
	end)

	if not success or not content or #content == 0 then
		return forcedProps
	end

	local decodeSuccess, decoded = pcall(function()
		return serde.decode("json", content)
	end)

	if decodeSuccess and decoded and type(decoded.properties) == "table" then
		for key, _ in pairs(decoded.properties) do
			forcedProps[key] = true
		end
	end

	return forcedProps
end

-- Write script file with proper extension
local function writeScriptFile(child: any, instanceDir: string)
	local scriptName = Encoding.sanitizeFilename(child.Name)
	local extension = ""

	if child:IsA("LocalScript") then
		extension = ".client.lua"
	elseif child:IsA("ModuleScript") then
		extension = ".lua"
	elseif child:IsA("Script") then
		extension = ".server.lua"
	else
		return false -- Not a script type
	end

	local scriptPath = instanceDir .. "/" .. scriptName .. extension

	-- Only write if file doesn't exist (don't overwrite existing scripts)
	if not fs.isFile(scriptPath) then
		local scriptContent = child.Source or ""
		local success, error = pcall(function()
			fs.writeFile(scriptPath, scriptContent)
		end)

		if success then
			print(string.format("📝 Created script: %s", scriptPath))
		else
			print(string.format("❌ Failed to write script %s: %s", scriptPath, tostring(error)))
		end
	end

	return true
end

-- Ensure directory exists
local function ensureDirectory(path: string): boolean
	if fs.isDir(path) then
		return true
	end

	local success, error = pcall(function()
		fs.writeDir(path)
	end)

	if success then
		print(string.format("📁 Created directory: %s", path))
		return true
	else
		print(string.format("❌ Failed to create directory %s: %s", path, tostring(error)))
		return false
	end
end

-- Write meta file for instance
local function writeMetaFile(instance: any, instanceDir: string): boolean
	local metaPath = instanceDir .. "/init.meta.json"
	local forcedProps = getForcedPropsFromMeta(metaPath)
	local jsonData = serializeInstanceToJson(instance, forcedProps)

	local success, error = pcall(function()
		fs.writeFile(metaPath, encodeJson(jsonData))
	end)

	if success then
		return true
	else
		print(string.format("❌ Failed to write meta file %s: %s", metaPath, tostring(error)))
		return false
	end
end

-- Export a single instance recursively
function Export.exportInstance(instance: any, targetDir: string): boolean
	local name = Encoding.sanitizeFilename(instance.Name)
	local instanceDir = targetDir .. "/" .. name

	-- Ensure the target directory exists
	if not ensureDirectory(instanceDir) then
		return false
	end

	-- Write init.meta.json for the parent itself
	if not writeMetaFile(instance, instanceDir) then
		return false
	end

	-- Check for naming conflicts among children before processing
	local nameConflicts = {}
	local seenNames = {}

	for _, child in ipairs(instance:GetChildren()) do
		local sanitizedName = Encoding.sanitizeFilename(child.Name)

		if seenNames[sanitizedName] then
			-- Conflict detected
			if not nameConflicts[sanitizedName] then
				nameConflicts[sanitizedName] = { seenNames[sanitizedName] }
			end
			table.insert(nameConflicts[sanitizedName], child)
		else
			seenNames[sanitizedName] = child
		end
	end

	-- If conflicts exist, report them and abort to prevent filesystem corruption
	if next(nameConflicts) then
		print(string.format("🚨 NAMING CONFLICTS DETECTED in %s:", instance.Name))
		for conflictName, conflictingInstances in pairs(nameConflicts) do
			print(string.format("  ⚠️ Multiple instances with sanitized name '%s':", conflictName))
			for _, conflictInstance in conflictingInstances do
				print(string.format("    - %s (%s)", conflictInstance.Name, conflictInstance.ClassName))
			end
		end
		print("🛑 ABORTING export and cleanup to prevent filesystem corruption!")
		print("🔧 Please rename conflicting instances in Studio and try again.")
		return false
	end

	-- Process all children (no conflicts detected)
	local childCount = 0
	for _, child in ipairs(instance:GetChildren()) do
		childCount = childCount + 1

		if child:IsA("LocalScript") or child:IsA("ModuleScript") or child:IsA("Script") then
			-- Scripts become .lua files
			writeScriptFile(child, instanceDir)
		else
			-- All other instances become folders with init.meta.json (recursive)
			Export.exportInstance(child, instanceDir)
		end
	end

	return true
end

return Export
