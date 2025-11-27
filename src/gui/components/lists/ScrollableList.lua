--[[
	ScrollableList Component

	A scrollable list with automatic canvas sizing and UIListLayout.

	Props:
		- items: table - Array of items to render
		- renderItem: function(item, index) -> ReactElement - Function to render each item
		- size: UDim2 - List size (default: UDim2.fromScale(1, 1))
		- position: UDim2 - List position
		- backgroundColor: Color3 - Background color (default: Color3.fromRGB(26, 26, 26))
		- backgroundTransparency: number - Background transparency (default: 0)
		- padding: UDim - Padding between items (default: UDim.new(0, 5))
		- itemHeight: number - Height of each item in pixels (default: 45)
		- scrollBarThickness: number - Scroll bar thickness (default: 6)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

local function ScrollableList(props)
	local items = props.items or {}
	local renderItem = props.renderItem

	if not renderItem then
		warn("[ScrollableList] renderItem prop is required")
		return nil
	end

	local itemHeight = props.itemHeight or 45
	local padding = props.padding or UDim.new(0, 5)
	local paddingValue = padding.Offset

	-- Calculate canvas size based on number of items
	local totalHeight = (#items * itemHeight) + ((#items - 1) * paddingValue)

	-- Build children table
	local children = {
		Layout = e("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = padding,
		}),
	}

	-- Render each item
	for index, item in ipairs(items) do
		children["Item_" .. index] = renderItem(item, index)
	end

	return e("ScrollingFrame", {
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		BackgroundTransparency = props.backgroundTransparency or 0,
		BackgroundColor3 = props.backgroundColor or Color3.fromRGB(26, 26, 26),
		BorderSizePixel = 0,
		ScrollBarThickness = props.scrollBarThickness or 6,
		ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60),
		CanvasSize = UDim2.new(0, 0, 0, totalHeight),
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		LayoutOrder = props.layoutOrder,
	}, children)
end

return ScrollableList
