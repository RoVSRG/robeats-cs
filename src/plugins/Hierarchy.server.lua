-- Plugin: GUI Hierarchy Exporter with Full Properties
-- Purpose: Export hierarchy with ClassName, Name, and key visual/layout properties
-- Optional: Send to local clipboard server (Express + clipboardy)

local Selection = game:GetService("Selection")
local HttpService = game:GetService("HttpService")
local Toolbar = plugin:CreateToolbar("Export Tools")
local Button = Toolbar:CreateButton("ExportGUIHierarchy", "Export selected GUI hierarchy", "rbxassetid://4458901886")

local function serializeValue(v)
	if typeof(v) == "UDim2" or typeof(v) == "Vector2" then
		return tostring(v)
	elseif typeof(v) == "Color3" then
		return string.format("Color3.fromRGB(%d, %d, %d)", v.R * 255, v.G * 255, v.B * 255)
	elseif typeof(v) == "boolean" then
		if v then
			return tostring(v)
		end
	elseif typeof(v) == "string" then
		return string.format("\"%s\"", v)
	else
		return tostring(v)
	end
end

local function extractProperties(instance)
	local properties = {}
	local relevant = {
		"Size", "Position", "AnchorPoint", "Text", "TextScaled",
		"Font", "TextColor3", "BackgroundColor3", "ZIndex", "LayoutOrder",
		"Visible", "Image", "TextSize", "CornerRadius", "Padding",
		"FillDirection", "SortOrder", "HorizontalAlignment", "HorizontalFlex",
		"ItemLineAlignment", "VerticalAlignment", "VerticalFlex", "AutomaticSize",
		"TextXAlignment", "TextYAlignment", "ClipsDescendants", "AutomaticCanvasSize", "CanvasSize",
		"ScrollBarThickness", "TextWrapped", "RichText", "Active", "Selectable",
		"AspectRatio", "MinSize", "MaxSize", "TextTruncate", "TextTransparency"
	}
	
	for _, prop in relevant do
		local ok, val = pcall(function()
			return instance[prop]
		end)
		
		if ok and val ~= nil then
			local str = serializeValue(val)
			if str then
				table.insert(properties, string.format("%s = %s", prop, str))
			end
		end
	end
	
	return properties
end

local function extractAttributes(instance)
	local attributes = {}
	
	for key, val in pairs(instance:GetAttributes()) do
		local str = serializeValue(val)
		if str then
			table.insert(attributes, string.format("[%q] = %s", key, str))
		end
	end
	
	return attributes
end

local function getIndent(depth)
	return string.rep("    ", depth)
end

local function exportInstanceTree(instance, depth)
	local indent = getIndent(depth)
	local lines = {}

	table.insert(lines, string.format("%s[%s] %s", indent, instance.ClassName, instance.Name))
	
	for _, propLine in ipairs(extractProperties(instance)) do
		table.insert(lines, getIndent(depth + 1) .. propLine)
	end

	local attributes = extractAttributes(instance)
	if #attributes > 0 then
		table.insert(lines, getIndent(depth + 1) .. "Attributes = {")
		for _, attributeLine in ipairs(attributes) do
			table.insert(lines, getIndent(depth + 2) .. attributeLine)
		end
		table.insert(lines, getIndent(depth + 1) .. "}")
	end

	for _, child in ipairs(instance:GetChildren()) do
		local childStr = exportInstanceTree(child, depth + 1)
		table.insert(lines, childStr)
	end

	return table.concat(lines, "\n")
end


local function exportToClipboard(payload)
	local success, response = pcall(function()
		return HttpService:PostAsync(
			"http://localhost:3000/copy",
			HttpService:JSONEncode({ text = payload }),
			Enum.HttpContentType.ApplicationJson
		)
	end)

	if success then
		print("Copied to clipboard via HTTP.")
	else
		warn("Failed to send to clipboard:", response)
	end
end

local function runExport()
	local selection = Selection:Get()
	if #selection == 0 then
		warn("Select a GUI object first.")
		return
	end

	local root = selection[1]
	local result = exportInstanceTree(root, 0)
	print("\nExported Hierarchy:\n" .. result)
	exportToClipboard(result)
end

Button.Click:Connect(runExport)