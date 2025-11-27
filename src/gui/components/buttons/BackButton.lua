--[[
	BackButton Component

	A standardized "Back to Menu" button used across all screens.

	Props:
		- onClick: function - Click handler (defaults to switching to MainMenu)
		- position: UDim2 - Button position (default: bottom-left)
		- text: string - Button text (default: "Back to Menu")
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)
local Button = require(script.Parent.Button)

local e = React.createElement
local useContext = React.useContext

local function BackButton(props)
	local screenContext = useContext(ScreenContext)

	local handleClick = props.onClick or function()
		screenContext.switchScreen("MainMenu")
	end

	return e(Button, {
		text = props.text or "Back to Menu",
		size = UDim2.fromOffset(200, 50),
		position = props.position or UDim2.new(0.02, 0, 0.95, 0),
		anchorPoint = Vector2.new(0, 1),
		onClick = handleClick,
		backgroundColor = Color3.fromRGB(50, 50, 50),
		hoverColor = Color3.fromRGB(70, 70, 70),
		textColor = Color3.fromRGB(255, 255, 255),
		font = Enum.Font.Gotham,
		textSize = 18,
		cornerRadius = UDim.new(0, 8),
	})
end

return BackButton
