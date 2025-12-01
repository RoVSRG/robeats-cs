--[[
	IntOption Component

	An integer option with increment/decrement buttons.
	Automatically integrates with Val state management via useVal hook.

	Props:
		- label: string - Option label
		- valInstance: Val - Val instance to bind to
		- config: table - Option configuration with increment, min, max
		- layoutOrder: number - Layout order
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local useVal = require(ReplicatedStorage.hooks.useVal)

local e = React.createElement

local function IntOption(props)
	local value: number, setValue = useVal(props.valInstance)
	local config: any = props.config or {}

	local increment: number = config.increment or 1
	local min: number = config.min or -math.huge
	local max: number = config.max or math.huge

	local function handleDecrement()
		local newValue = value - increment
		if newValue >= min then
			setValue(newValue)
		end
	end

	local function handleIncrement()
		local newValue = value + increment
		if newValue <= max then
			setValue(newValue)
		end
	end

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

		DecrementButton = e("TextButton", {
			Text = "-",
			Size = UDim2.fromOffset(40, 30),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 20,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			[React.Event.MouseButton1Click] = handleDecrement,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) })
		}),

		ValueDisplay = e("TextLabel", {
			Text = tostring(value),
			Size = UDim2.fromOffset(80, 30),
			Position = UDim2.new(0.5, 50, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.Gotham,
			TextSize = 16,
			BorderSizePixel = 0,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) })
		}),

		IncrementButton = e("TextButton", {
			Text = "+",
			Size = UDim2.fromOffset(40, 30),
			Position = UDim2.new(0.5, 140, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 20,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			[React.Event.MouseButton1Click] = handleIncrement,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) })
		}),
	})
end

return IntOption
