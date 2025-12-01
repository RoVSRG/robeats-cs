local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Components.Primitives)
local useVal = require(ReplicatedStorage.hooks.useVal)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local function rowBase(props, children)
	local content = {
		UICorner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
		Padding = e(UI.UIPadding, {
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
		}),
		Layout = e(UI.UIListLayout, {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			ItemLineAlignment = Enum.ItemLineAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	}

	for index, child in ipairs(children) do
		content["Child" .. index] = child
	end

	return e(UI.Frame, {
		Size = UDim2.new(1, 0, 0, props.height or 32),
		BackgroundColor3 = Color3.fromRGB(21, 21, 21),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, content)
end

local function optionLabel(text, size, layoutOrder)
	return e(UI.TextLabel, {
		Text = text,
		Size = size or UDim2.new(0.53, -120, 1, 0),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(230, 230, 230),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = layoutOrder or -1,
	})
end

local function divider(width, height)
	return e("Frame", {
		Size = UDim2.fromOffset(width or 145, height or 32),
		BackgroundTransparency = 1,
	}, {
		Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
	})
end

local function BoolOptionRow(props)
	local value, setValue = useVal(props.val)
	local isHovering, setIsHovering = useState(false)

	local function handleToggle()
		setValue(not value)
	end

	local backgroundColor
	if value then
		backgroundColor = isHovering and Color3.fromRGB(100, 180, 123) or Color3.fromRGB(90, 170, 113)
	else
		backgroundColor = isHovering and Color3.fromRGB(157, 54, 56) or Color3.fromRGB(147, 44, 46)
	end
	local text = value and "TRUE" or "FALSE"

	return rowBase(props, {
		optionLabel(props.label),
		divider(145, 32),
		e(UI.TextButton, {
			Text = text,
			Size = UDim2.fromOffset(83, 24),
			BackgroundColor3 = backgroundColor,
			TextColor3 = Color3.fromRGB(230, 230, 230),
			Font = UI.Theme.fonts.body,
			TextSize = 12,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			[React.Event.MouseButton1Click] = handleToggle,
			[React.Event.MouseEnter] = function()
				setIsHovering(true)
			end,
			[React.Event.MouseLeave] = function()
				setIsHovering(false)
			end,
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
		}),
	})
end

local function IntOptionRow(props)
	local value: number, setValue = useVal(props.val)
	local config = props.config or {}
	local hoverDecrement, setHoverDecrement = useState(false)
	local hoverIncrement, setHoverIncrement = useState(false)

	local increment = config.increment or 1
	local min = config.min or -math.huge
	local max = config.max or math.huge

	local function updateValue(delta)
		local nextValue = value + delta
		if nextValue < min or nextValue > max then
			return
		end
		setValue(math.floor(nextValue))
	end

	return rowBase(props, {
		optionLabel(props.label),
		divider(145, 32),
		e(UI.TextButton, {
			Text = "-",
			Size = UDim2.fromOffset(24, 24),
			BackgroundColor3 = hoverDecrement and Color3.fromRGB(67, 67, 67) or Color3.fromRGB(57, 57, 57),
			TextColor3 = Color3.fromRGB(230, 230, 230),
			Font = UI.Theme.fonts.body,
			TextSize = 14,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			[React.Event.MouseButton1Click] = function()
				updateValue(-increment)
			end,
			[React.Event.MouseEnter] = function()
				setHoverDecrement(true)
			end,
			[React.Event.MouseLeave] = function()
				setHoverDecrement(false)
			end,
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),
		}),
		e(UI.TextLabel, {
			Text = tostring(value),
			Size = UDim2.fromOffset(50, 24),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			TextColor3 = Color3.fromRGB(230, 230, 230),
			Font = UI.Theme.fonts.body,
			TextSize = 12,
			BorderSizePixel = 0,
			LayoutOrder = 2,
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),
		}),
		e(UI.TextButton, {
			Text = "+",
			Size = UDim2.fromOffset(24, 24),
			BackgroundColor3 = hoverIncrement and Color3.fromRGB(67, 67, 67) or Color3.fromRGB(57, 57, 57),
			TextColor3 = Color3.fromRGB(230, 230, 230),
			Font = UI.Theme.fonts.body,
			TextSize = 14,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = 3,
			[React.Event.MouseButton1Click] = function()
				updateValue(increment)
			end,
			[React.Event.MouseEnter] = function()
				setHoverIncrement(true)
			end,
			[React.Event.MouseLeave] = function()
				setHoverIncrement(false)
			end,
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),
		}),
	})
end

local function KeybindOptionRow(props)
	local value, setValue = useVal(props.val)
	local isListening, setIsListening = useState(false)
	local isHovering, setIsHovering = useState(false)

	useEffect(function()
		if not isListening then
			return
		end

		local connection
		connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end

			if input.UserInputType == Enum.UserInputType.Keyboard then
				local keyName = input.KeyCode.Name
				setValue(keyName)
				setIsListening(false)
				connection:Disconnect()
			end
		end)

		return function()
			if connection then
				connection:Disconnect()
			end
		end
	end, { isListening, setValue })

	local displayText
	if isListening then
		displayText = "Press any key..."
	elseif value and value ~= "" then
		displayText = value
	else
		displayText = "NONE"
	end

	local backgroundColor
	if isListening then
		backgroundColor = Color3.fromRGB(255, 167, 36)
	elseif isHovering then
		backgroundColor = Color3.fromRGB(51, 51, 51)
	else
		backgroundColor = Color3.fromRGB(41, 41, 41)
	end

	return rowBase(props, {
		optionLabel(props.label),
		divider(145, 32),
		e(UI.TextButton, {
			Text = displayText,
			Size = UDim2.fromOffset(83, 26),
			BackgroundColor3 = backgroundColor,
			TextColor3 = Color3.fromRGB(230, 230, 230),
			Font = UI.Theme.fonts.body,
			TextSize = 12,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			[React.Event.MouseButton1Click] = function()
				if not isListening then
					setIsListening(true)
				end
			end,
			[React.Event.MouseEnter] = function()
				setIsHovering(true)
			end,
			[React.Event.MouseLeave] = function()
				setIsHovering(false)
			end,
		}, {
			e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),
		}),
	})
end

local function RadioOptionRow(props)
	local value, setValue = useVal(props.val)
	local selection = props.config.selection or {}

	local buttons = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			ItemLineAlignment = Enum.ItemLineAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	}

	for index, option in ipairs(selection) do
		local function RadioButton()
			local isHovering, setIsHovering = useState(false)
			local isActive = tostring(value) == tostring(option)

			local backgroundColor
			if isActive then
				backgroundColor = Color3.fromRGB(255, 167, 36)
			elseif isHovering then
				backgroundColor = Color3.fromRGB(51, 51, 51)
			else
				backgroundColor = Color3.fromRGB(41, 41, 41)
			end

			return e(UI.TextButton, {
				Text = tostring(option),
				Size = UDim2.fromOffset(100, 26),
				BackgroundColor3 = backgroundColor,
				TextColor3 = Color3.fromRGB(230, 230, 230),
				Font = UI.Theme.fonts.body,
				TextSize = 12,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				LayoutOrder = index,
				[React.Event.MouseButton1Click] = function()
					setValue(option)
				end,
				[React.Event.MouseEnter] = function()
					setIsHovering(true)
				end,
				[React.Event.MouseLeave] = function()
					setIsHovering(false)
				end,
			}, {
				e(UI.UICorner, { CornerRadius = UDim.new(0, 6) }),
			})
		end

		buttons["Radio" .. index] = e(RadioButton)
	end

	return rowBase({
		layoutOrder = props.layoutOrder,
		height = props.height or 36,
	}, {
		optionLabel(props.label),
		divider(145, 36),
		e("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(0, 320, 0, 26),
		}, buttons),
	})
end

return {
	BoolOptionRow = BoolOptionRow,
	IntOptionRow = IntOptionRow,
	KeybindOptionRow = KeybindOptionRow,
	RadioOptionRow = RadioOptionRow,
}
