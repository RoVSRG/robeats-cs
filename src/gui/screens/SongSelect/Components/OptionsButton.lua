local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)

local e = React.createElement
local useState = React.useState

--[[
	OptionsButton - Button to open options menu

	Future implementation will show options UI
]]
local function OptionsButton(props)
	local hover, setHover = useState(false)

	return e(UI.TextButton, {
		Text = "Options",
		Size = props.size or UDim2.fromScale(0.287, 0.055),
		Position = props.position,
		BackgroundColor3 = hover and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(35, 35, 35),
		TextColor3 = Color3.fromRGB(230, 230, 230),
		TextSize = 14,
		Font = UI.Theme.fonts.body,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		[React.Event.MouseButton1Click] = props.onClick or function()
			warn("Options not implemented")
		end,
		[React.Event.MouseEnter] = function()
			setHover(true)
		end,
		[React.Event.MouseLeave] = function()
			setHover(false)
		end,
	}, {
		e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
	})
end

return OptionsButton
