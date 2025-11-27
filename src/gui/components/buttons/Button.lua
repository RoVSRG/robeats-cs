--[[
	Button Component

	A base button component with hover states and customizable styling.

	Props:
		- text: string - Button text
		- onClick: function - Click handler
		- size: UDim2 - Button size (default: UDim2.fromOffset(120, 40))
		- position: UDim2 - Button position
		- anchorPoint: Vector2 - Anchor point
		- backgroundColor: Color3 - Background color (default: Color3.fromRGB(50, 50, 50))
		- hoverColor: Color3 - Hover background color (default: Color3.fromRGB(70, 70, 70))
		- textColor: Color3 - Text color (default: Color3.fromRGB(255, 255, 255))
		- font: Enum.Font - Font (default: Enum.Font.Gotham)
		- textSize: number - Text size (default: 18)
		- disabled: boolean - Whether button is disabled
		- cornerRadius: UDim - Corner radius (default: UDim.new(0, 8))
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement
local useState = React.useState

local function Button(props)
	local hover, setHover = useState(false)

	local isDisabled = props.disabled or false

	-- Colors
	local normalBg = props.backgroundColor or Color3.fromRGB(50, 50, 50)
	local hoverBg = props.hoverColor or Color3.fromRGB(70, 70, 70)
	local disabledBg = Color3.fromRGB(30, 30, 30)

	local backgroundColor = isDisabled and disabledBg
	                      or (hover and hoverBg)
	                      or normalBg

	local textColor = isDisabled and Color3.fromRGB(128, 128, 128)
	                or props.textColor or Color3.fromRGB(255, 255, 255)

	return e("TextButton", {
		Text = props.text or "Button",
		Size = props.size or UDim2.fromOffset(120, 40),
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		BackgroundColor3 = backgroundColor,
		TextColor3 = textColor,
		Font = props.font or Enum.Font.Gotham,
		TextSize = props.textSize or 18,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,

		[React.Event.MouseEnter] = function()
			if not isDisabled then
				setHover(true)
			end
		end,

		[React.Event.MouseLeave] = function()
			setHover(false)
		end,

		[React.Event.MouseButton1Click] = function()
			if not isDisabled and props.onClick then
				props.onClick()
			end
		end,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = props.cornerRadius or UDim.new(0, 8)
		}),
	})
end

return Button
