local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)

local e = React.createElement

--[[
	MultiplayerPanel - Placeholder for multiplayer UI

	This is a simplified version. Full implementation would show:
	- Player slots
	- Ready states
	- Host controls
	- etc.
]]
local function MultiplayerPanel(props)
	return e(UI.Frame, {
		Position = props.position,
		Size = props.size,
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BorderSizePixel = 0,
		Visible = false, -- Hidden by default (multiplayer not implemented yet)
	}, {
		Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),

		Label = e(UI.TextLabel, {
			Text = "Multiplayer (Not Implemented)",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(120, 120, 120),
			TextSize = 14,
			Font = UI.Theme.fonts.body,
		}),
	})
end

return MultiplayerPanel
