--[[
	BoolOption Component

	A boolean toggle option with TRUE/FALSE display.
	Green for TRUE, Red for FALSE.

	Props:
		- label: string - Option label
		- valInstance: Val - Val instance to bind to
		- config: table - Option configuration (unused for bool)
		- layoutOrder: number - Layout order
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local useVal = require(ReplicatedStorage.hooks.useVal)
local useValSetter = require(ReplicatedStorage.hooks.useValSetter)

local e = React.createElement

local function BoolOption(props)
	local value = useVal(props.valInstance)
	local setValue = useValSetter(props.valInstance)

	local function handleToggle()
		setValue(not value)
	end

	local backgroundColor = value and Color3.fromRGB(90, 170, 113)  -- Green for TRUE
	                             or Color3.fromRGB(147, 44, 46)    -- Red for FALSE

	local text = value and "TRUE" or "FALSE"

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, {
		Label = e("TextLabel", {
			Text = props.label or "Option",
			Size = UDim2.new(0.5, 0, 1, 0),
			Position = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham,
			TextSize = 16,
		}, {
			Padding = e("UIPadding", { PaddingLeft = UDim.new(0, 10) })
		}),

		Toggle = e("TextButton", {
			Text = text,
			Size = UDim2.fromOffset(100, 30),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = backgroundColor,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			[React.Event.MouseButton1Click] = handleToggle,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) })
		}),
	})
end

return BoolOption
