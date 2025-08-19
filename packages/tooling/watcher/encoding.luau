local Encoding = {}

function Encoding.serializeValue(value: any, datatype: string): any
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
					{ r20, r21, r22 },
				},
			},
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
				direction = { value.Direction.X, value.Direction.Y, value.Direction.Z },
			},
		}
	elseif datatype == "Font" then
		-- Rojo implicit format: { "family": string, "weight": string, "style": string }
		return {
			family = value.Family,
			weight = value.Weight.Name,
			style = value.Style.Name,
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
					elasticityWeight = value.ElasticityWeight,
				},
			}
		end
	elseif datatype == "Content" then
		return Encoding.extractAssetUriFromImageContent(value)
	elseif datatype == "ColorSequence" then
		-- Rojo explicit format
		local keypoints = {}
		for _, keypoint in value.Keypoints do
			table.insert(keypoints, {
				time = keypoint.Time,
				color = { keypoint.Value.R, keypoint.Value.G, keypoint.Value.B },
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
				envelope = keypoint.Envelope,
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

function Encoding.extractAssetUriFromImageContent(imageContent: any): string?
	local raw = tostring(imageContent)

	-- Grab ALL Uri=... matches
	local matches = {}
	for uri in raw:gmatch("Uri=([%w%p]+)") do
		table.insert(matches, uri)
	end

	-- No matches? return nil
	if #matches == 0 then
		return nil
	end

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

function Encoding.sanitizeFilename(name: string): string
	-- Replace invalid Windows filename characters with underscores
	-- Invalid chars: < > : " | ? * and control characters (0-31)
	local sanitized = name:gsub('[<>:"|?*]', "_")

	-- Replace control characters (ASCII 0-31)
	sanitized = sanitized:gsub("[\0-\31]", "_")

	-- Remove leading/trailing spaces and dots (Windows restriction)
	sanitized = sanitized:gsub("^[%s%.]+", ""):gsub("[%s%.]+$", "")

	-- Ensure it's not empty
	if sanitized == "" then
		sanitized = "unnamed"
	end

	-- Handle reserved Windows names
	local reservedNames = {
		"CON",
		"PRN",
		"AUX",
		"NUL",
		"COM1",
		"COM2",
		"COM3",
		"COM4",
		"COM5",
		"COM6",
		"COM7",
		"COM8",
		"COM9",
		"LPT1",
		"LPT2",
		"LPT3",
		"LPT4",
		"LPT5",
		"LPT6",
		"LPT7",
		"LPT8",
		"LPT9",
	}

	local upperName = sanitized:upper()
	for _, reserved in reservedNames do
		if upperName == reserved or upperName:match("^" .. reserved .. "%.") then
			sanitized = "_" .. sanitized
			break
		end
	end

	return sanitized
end

return Encoding
