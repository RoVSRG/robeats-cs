local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Components.Primitives)
local useOptionCategory = require(ReplicatedStorage.hooks.useOptionCategory)
local OptionRows = require(script.Parent.OptionRows)

local e = React.createElement

local renderers = {
	int = OptionRows.IntOptionRow,
	bool = OptionRows.BoolOptionRow,
	keybind = OptionRows.KeybindOptionRow,
	radio = OptionRows.RadioOptionRow,
}

local function renderOption(entry)
	local Component = renderers[entry.config.type]
	if not Component then
		return nil
	end

	return e(Component, {
		key = entry.key,
		label = entry.config.displayName or entry.key,
		val = entry.val,
		config = entry.config,
		layoutOrder = entry.config.layoutOrder,
	})
end

local function OptionList(props)
	local options = useOptionCategory(props.category)

	local optionElements = {}

	local listLayout = e(UI.UIListLayout, {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
	})

	for _, entry in ipairs(options) do
		local optionElement = renderOption(entry)
		if optionElement then
			table.insert(optionElements, optionElement)
		end
	end

	if #options == 0 then
		table.insert(optionElements, e(UI.TextLabel, {
			Text = "No options available",
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			Font = UI.Theme.fonts.body,
			TextSize = 14,
			LayoutOrder = 1,
		}))
	end

	local children = {
		Padding = e(UI.UIPadding, {
			PaddingRight = UDim.new(0, 15),
			PaddingBottom = UDim.new(0, 10),
		}),
		ListLayout = listLayout,
	}

	for index, element in ipairs(optionElements) do
		children[index] = element
	end

	return e("ScrollingFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = props.position or UDim2.new(0.5, 0, 0.533, 0),
		Size = props.size or UDim2.new(1, 0, 0.933, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
	}, children)
end

return OptionList
