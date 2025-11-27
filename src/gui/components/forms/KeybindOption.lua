--[[
	KeybindOption Component

	A keybind capture option that listens for keyboard input.
	Highlights orange when listening for input.

	Props:
		- label: string - Option label
		- valInstance: Val - Val instance to bind to
		- config: table - Option configuration (unused for keybind)
		- layoutOrder: number - Layout order
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local useVal = require(ReplicatedStorage.hooks.useVal)
local useValSetter = require(ReplicatedStorage.hooks.useValSetter)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function KeybindOption(props)
	local value = useVal(props.valInstance)
	local setValue = useValSetter(props.valInstance)
	local isListening, setIsListening = useState(false)

	local displayText
	if isListening then
		displayText = "Press any key..."
	elseif value and value ~= "" then
		displayText = value
	else
		displayText = "NONE"
	end

	local backgroundColor = isListening and Color3.fromRGB(255, 167, 36)  -- Orange when listening
	                                     or Color3.fromRGB(46, 46, 46)     -- Dark gray normally

	-- Set up input listener when listening is enabled
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

		-- Cleanup
		return function()
			if connection then
				connection:Disconnect()
			end
		end
	end, { isListening })

	local function handleClick()
		if not isListening then
			setIsListening(true)
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

		KeyDisplay = e("TextButton", {
			Text = displayText,
			Size = UDim2.fromOffset(150, 30),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = backgroundColor,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.Gotham,
			TextSize = 16,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			[React.Event.MouseButton1Click] = handleClick,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) })
		}),
	})
end

return KeybindOption
