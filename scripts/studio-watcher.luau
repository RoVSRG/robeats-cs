--!strict
-- Studio Place File Watcher - Auto-pulls GUI changes when Studio saves
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local function encodeJson(data: any): string
	return serde.encode("json", data, { pretty = true })
end

local function decodeJson(data: string): string
	return serde.decode("json", data)
end

local CHECK_INTERVAL = 1.0
local DEBOUNCE_TIME = 2.0

local BASE_DIR = "src"
local GUI_DIR = BASE_DIR .. "/gui/TEST"
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
		-- Rojo explicit format
		local keypoints = {}
		for _, keypoint in value.Keypoints do
			table.insert(keypoints, {
				time = keypoint.Time,
				value = keypoint.Value,
				envelope = keypoint.Envelope
			})
		end
		return { NumberSequence = { keypoints = keypoints } }
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

-- === Rojo-compatible property serializer ===
local function getInstanceProperties(instance: any): { [string]: any }
	local className = instance.ClassName
	local class = reflectionDB:GetClass(className)

	if not class then
		warn("[Serializer] No reflection info for class:", className)
		return {}
	end

	local serializedProps = {}

	for _, prop in class.Properties do
		-- Filter: must be readable and not deprecated
		local success, value = pcall(function()
			return instance[prop.Name]
		end)

		if success and value ~= nil then
			-- Use Rojo's property format - direct value assignment
			serializedProps[prop.Name] = serializeValue(value, prop.Datatype)
		end
	end

	return serializedProps
end

-- === Rojo-compatible instance serialization ===
local function serializeInstanceToJson(instance: any): any
	return {
		["$className"] = instance.ClassName,
		["$properties"] = getInstanceProperties(instance),
	}
end

-- === Recursive export ===
local function exportInstance(instance: any, targetDir: string)
	fs.writeDir(targetDir)

	-- If it's a script, dump its source
	if instance:IsA("LocalScript") then
		local scriptPath = targetDir .. "/" .. instance.Name .. ".client.lua"
		fs.writeFile(scriptPath, instance.Source)
		print("💾 Saved script:", scriptPath)
		return
	elseif instance:IsA("ModuleScript") then
		local scriptPath = targetDir .. "/" .. instance.Name .. ".lua"
		fs.writeFile(scriptPath, instance.Source)
		print("💾 Saved module:", scriptPath)
		return
	elseif instance:IsA("Script") then
		local scriptPath = targetDir .. "/" .. instance.Name .. ".server.lua"
		fs.writeFile(scriptPath, instance.Source)
		print("💾 Saved server script:", scriptPath)
		return
	end

	-- Otherwise, dump as model.json
	local modelPath = targetDir .. "/" .. instance.Name .. ".model.json"
	local jsonData = serializeInstanceToJson(instance)
	fs.writeFile(modelPath, encodeJson(jsonData))
	print("💾 Saved UI model:", modelPath)

	-- Subfolder for children
	local childDir = targetDir .. "/" .. instance.Name
	fs.writeDir(childDir)

	-- Recurse children
	for _, child in ipairs(instance:GetChildren()) do
		exportInstance(child, childDir)
	end
end

-- === Pull GUI from place file ===
local function pullGuiFromPlace(path: string)
	print("🎯 Studio save detected! Pulling GUI changes...")

	local file = fs.readFile(path)
	if not file then
		error("[StudioWatcher] Failed to read place file:", path)
		return
	end

	local game = roblox.deserializePlace(file)
	if not game then
		error("[StudioWatcher] Failed to deserialize place file:", path)
		return
	end

	local starterGui = game:GetService("StarterGui")
	local screens = starterGui:FindFirstChild("Screens")
	local dev = starterGui:FindFirstChild("Dev")

	if not screens then
		error("[StudioWatcher] No Screens folder found in StarterGui.")
		return
	end

	print("📦 Pulling GUI changes from place file...")

	for _, screen in screens:GetChildren() do
		exportInstance(screen, SCREENS_DIR)
	end

	if dev then
		for _, child in dev:GetChildren() do
			local devDir = SCREENS_DIR .. "/Dev"
			exportInstance(child, devDir)
		end
	end

	print("✅ GUI changes pulled successfully!")
end

-- === Watcher loop ===
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
