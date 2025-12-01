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
		Position = props.position or UDim2.fromScale(0.08039248, 1.0300233),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, {
		Layout = e(UI.UIListLayout, {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
		}),

		-- Top caution stripe (tiled image)
		TopCaution = e(UI.ImageLabel, {
			Size = UDim2.new(1, 0, 0, 10),
			Image = "rbxassetid://449399728",
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.new(0, 10, 1, 0),
			BorderSizePixel = 0,
			LayoutOrder = 0,
		}),

		-- Disclaimer text
		Disclaimer = e(UI.TextLabel, {
			Text = "UNRANKED: Your Overall Difficulty must be set to 8 in Options for your score to submit to leaderboards.",
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(240, 53, 53),
			TextSize = 13,
			Font = Enum.Font.GothamBold,
			BorderSizePixel = 0,
			LayoutOrder = 1,
		}),

		-- Bottom caution stripe (tiled image)
		BottomCaution = e(UI.ImageLabel, {
			Size = UDim2.new(1, 0, 0, 10),
			Image = "rbxassetid://449399728",
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.new(0, 10, 1, 0),
			BorderSizePixel = 0,
			LayoutOrder = 2,
		}),
	})
end

return UnrankedDisclaimer
