local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)

local e = React.createElement

-- Sort mode options matching archive
local SORT_MODES = {
	"Default",
	"Difficulty (Desc)",
	"Difficulty (Asc)",
	"Title (Asc)",
	"Title (Desc)",
	"Artist (Asc)",
	"Artist (Desc)",
}

-- Color mode options matching archive
local COLOR_MODES = {
	"Default",
	"Difficulty",
}

--[[
	FilterControls - Sort and Color mode toggle buttons

	Props:
		sortMode: string - Current sort mode
		colorMode: string - Current color mode
		onSortChange: function(newMode) - Callback when sort mode changes
		onColorChange: function(newMode) - Callback when color mode changes
		size: UDim2 - Size (optional)
		position: UDim2 - Position (optional)
]]
local function FilterControls(props)
	local sortMode = props.sortMode or "Default"
	local colorMode = props.colorMode or "Default"

	local function handleSortClick()
		-- Cycle through sort modes
		local currentIndex = table.find(SORT_MODES, sortMode) or 1
		local nextIndex = (currentIndex % #SORT_MODES) + 1
		local nextMode = SORT_MODES[nextIndex]

		if props.onSortChange then
			props.onSortChange(nextMode)
		end
	end

	local function handleColorClick()
		-- Cycle through color modes
		local currentIndex = table.find(COLOR_MODES, colorMode) or 1
		local nextIndex = (currentIndex % #COLOR_MODES) + 1
		local nextMode = COLOR_MODES[nextIndex]

		if props.onColorChange then
			props.onColorChange(nextMode)
		end
	end

	return e(UI.Frame, {
		Size = props.size or UDim2.new(1, 0, 0, 40),
		Position = props.position or UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
	}, {
		Layout = e(UI.UIListLayout, {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),

		-- Sort button
		SortButton = e(UI.TextButton, {
			Text = "Sort: " .. sortMode,
			Size = UDim2.new(0.49, -3, 1, 0),
			BackgroundColor3 = Color3.fromRGB(57, 57, 57),
			TextColor3 = Color3.fromRGB(230, 230, 230),
			TextSize = 14,
			Font = UI.Theme.fonts.body,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			[React.Event.MouseButton1Click] = handleSortClick,
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),
		}),

		-- Color button
		ColorButton = e(UI.TextButton, {
			Text = "Color: " .. colorMode,
			Size = UDim2.new(0.49, -3, 1, 0),
			BackgroundColor3 = Color3.fromRGB(57, 57, 57),
			TextColor3 = Color3.fromRGB(230, 230, 230),
			TextSize = 14,
			Font = UI.Theme.fonts.body,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = 2,
			[React.Event.MouseButton1Click] = handleColorClick,
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),
		}),
	})
end

return FilterControls
