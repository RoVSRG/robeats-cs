local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)

local e = React.createElement

--[[
	UnrankedDisclaimer - Warning banner for unranked songs

	Shows yellow/black caution stripes with "UNRANKED" text
]]
local function UnrankedDisclaimer(props)
	return e(UI.Frame, {
		Size = props.size or UDim2.fromOffset(705, 40),
		Position = props.position,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BorderSizePixel = 0,
		Visible = props.visible ~= false,
	}, {
		Layout = e(UI.UIListLayout, {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
		}),

		-- Top caution stripe
		TopCaution = e(UI.Frame, {
			Size = UDim2.new(1, 0, 0, 10),
			BackgroundColor3 = Color3.fromRGB(255, 200, 0),
			BorderSizePixel = 0,
			LayoutOrder = 1,
		}),

		-- Disclaimer text
		Disclaimer = e(UI.TextLabel, {
			Text = "⚠ UNRANKED SONG ⚠",
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundColor3 = Color3.fromRGB(255, 200, 0),
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 14,
			Font = UI.Theme.fonts.bold,
			BorderSizePixel = 0,
			LayoutOrder = 2,
		}),

		-- Bottom caution stripe
		BottomCaution = e(UI.Frame, {
			Size = UDim2.new(1, 0, 0, 10),
			BackgroundColor3 = Color3.fromRGB(255, 200, 0),
			BorderSizePixel = 0,
			LayoutOrder = 3,
		}),
	})
end

return UnrankedDisclaimer
