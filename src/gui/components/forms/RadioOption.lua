--[[
	RadioOption Component

	A radio button group for single-select options.
	Highlights the selected option in orange.

	Props:
		- label: string - Option label
		- valInstance: Val - Val instance to bind to
		- config: table - Option configuration with selection array
		- layoutOrder: number - Layout order
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local useVal = require(ReplicatedStorage.hooks.useVal)

local e = React.createElement
local useState = React.useState

local function RadioButton(props)
	local isSelected = props.isSelected
	local text = props.text
	local onClick = props.onClick
	local hover, setHover = useState(false)

	local backgroundColor
	if isSelected then
		backgroundColor = Color3.fromRGB(255, 167, 36) -- Orange for selected
	elseif hover then
		backgroundColor = Color3.fromRGB(60, 60, 60)   -- Dark gray for hover
	else
		backgroundColor = Color3.fromRGB(46, 46, 46)   -- Darker gray for normal
	end

	return e("TextButton", {
		Text = text,
		Size = UDim2.fromOffset(80, 30),
		BackgroundColor3 = backgroundColor,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.Gotham,
		TextSize = 14,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		[React.Event.MouseEnter] = function()
			setHover(true)
		end,
		[React.Event.MouseLeave] = function()
			setHover(false)
		end,
		[React.Event.MouseButton1Click] = onClick,
	}, {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) })
	})
end

local function RadioOption(props)
	local value, setValue = useVal(props.valInstance)
	local config: any = props.config or {}

	local selection: {string} = config.selection or {}

	-- Build children for radio buttons
	local children = {
		Label = e("TextLabel", {
			Text = props.label or "Option",
			Size = UDim2.new(0.4, 0, 1, 0),
			Position = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham,
			TextSize = 16,
		}, {
			Padding = e("UIPadding", { PaddingLeft = UDim.new(0, 10) })
		}),

		ButtonContainer = e("Frame", {
			Size = UDim2.new(0.6, 0, 1, 0),
			Position = UDim2.fromScale(0.4, 0),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})
		})
	}

	-- Create radio buttons for each option
	for index, option in ipairs(selection) do
		local radioButton = e(RadioButton, {
			text = option,
			isSelected = (value == option),
			onClick = function()
				setValue(option)
			end,
			layoutOrder = index,
		})

		children.ButtonContainer["Button_" .. index] = radioButton
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, children)
end

return RadioOption
