local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)

local e = React.createElement
local useMemo = React.useMemo

-- Max NPS for scaling (from archive)
local MAX_NPS = 35

--[[
	getNpsGraphColor - Color function from archive exactly

	Gradient based on NPS value:
	- 0-7: Blue tones
	- 7-14: Blue-cyan
	- 14-21: Purple-pink
	- 21-28: Pink-orange
	- 28-35: Orange-red
	- 35-42: Dark red
	- 42+: Very dark red
]]
local function getNpsGraphColor(num)
	local x = 0
	if num < 7 then
		x = num / 7
		return Color3.new(0.1 + x * 0.1, 0.1 + x * 0.1, 0.8 + x * 0.2)
	elseif num < 14 then
		x = (num - 7) / 7
		return Color3.new(0.2 + 0.4 * x, 0.2 + 0.2 * x, 1.0)
	elseif num < 21 then
		x = (num - 14) / 7
		return Color3.new(0.6 + 0.4 * x, 0.4 - 0.2 * x, 1.0 - 0.3 * x)
	elseif num < 28 then
		x = (num - 21) / 7
		return Color3.new(1.0, 0.2 + 0.2 * x, 0.7 - 0.5 * x)
	elseif num < 35 then
		x = (num - 28) / 7
		return Color3.new(1.0, 0.4 - 0.3 * x, 0.2 - 0.15 * x)
	elseif num < 42 then
		x = (num - 35) / 7
		return Color3.new(1.0 - 0.3 * x, 0.1 - x * 0.1, 0.05 - 0.05 * x)
	else
		return Color3.new(0.7, 0.0, 0.0)
	end
end

--[[
	NpsGraph - Visualizes NPS (Notes Per Second) over time

	Matches archive_screens/SongSelect/SongInfo exactly:
	- Uses NPSGraph string data from song (comma-separated values)
	- Each bar: Size = (1/slices, slice/MAX_NPS), colored by getNpsGraphColor
	- GraphContainer with UIListLayout (Horizontal, Bottom aligned)
]]
local function NpsGraph(props)
	local songData = props.songData
	local rate = props.rate or 100

	-- Parse NPS data from song's NPSGraph field (comma-separated string)
	local npsData = useMemo(function()
		if not songData or not songData.NPSGraph then
			return nil
		end

		local dataString = songData.NPSGraph
		local points = string.split(dataString, ",")
		local data = {}

		for i, point in ipairs(points) do
			local num = tonumber(point)
			if num then
				data[i] = num
			end
		end

		return #data > 0 and data or nil
	end, { songData })

	-- Generate bar elements matching archive exactly
	local bars = {}
	if npsData then
		local slices = #npsData

		for i, slice in ipairs(npsData) do
			-- Apply rate adjustment
			local adjustedSlice = slice * rate / 100

			bars["Bar" .. i] = e("Frame", {
				Size = UDim2.fromScale(1 / slices, adjustedSlice / MAX_NPS),
				BackgroundColor3 = getNpsGraphColor(adjustedSlice),
				BorderSizePixel = 0,
				LayoutOrder = i,
			})
		end
	end

	return e(UI.Frame, {
		Size = props.size or UDim2.fromScale(1, 0.527),
		Position = props.position or UDim2.fromScale(0, 0.224),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, {
		Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),

		-- GraphContainer - Position (0, 0.00121), Size (1, 0.9991)
		GraphContainer = e(UI.Frame, {
			Position = UDim2.fromScale(0, 0.00121),
			Size = UDim2.fromScale(1, 0.9991),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			-- UIListLayout: Horizontal, Center, Bottom, LayoutOrder sort, no padding
			Layout = e(UI.UIListLayout, {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 0),
			}),

			-- Dynamic bars
			Bars = React.createElement(React.Fragment, nil, bars),
		}),

		-- LineLabels - horizontal marker lines at NPS thresholds (ZIndex 0)
		LineLabels = e(UI.Frame, {
			Position = UDim2.fromScale(0, 0.00121),
			Size = UDim2.fromScale(1, 0.9991),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 0,
		}, {
			-- Part1: 7 NPS line (position 1 - 7/35 = 0.8)
			Part1 = e("Frame", {
				Position = UDim2.fromScale(0, 0.7939),
				Size = UDim2.fromScale(1, 0.01124),
				BackgroundColor3 = Color3.new(0.2, 0.2, 1), -- Blue
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				ZIndex = 0,
			}),

			-- Part2: 14 NPS line (position 1 - 14/35 = 0.6)
			Part2 = e("Frame", {
				Position = UDim2.fromScale(0, 0.5917),
				Size = UDim2.fromScale(1, 0.01124),
				BackgroundColor3 = Color3.new(0.6, 0.2, 1), -- Purple
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				ZIndex = 0,
			}),

			-- Part3: 21 NPS line (position 1 - 21/35 = 0.4)
			Part3 = e("Frame", {
				Position = UDim2.fromScale(0, 0.3895),
				Size = UDim2.fromScale(1, 0.01124),
				BackgroundColor3 = Color3.new(1, 0.098, 1), -- Pink
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				ZIndex = 0,
			}),

			-- Part4: 28 NPS line (position 1 - 28/35 = 0.2)
			Part4 = e("Frame", {
				Position = UDim2.fromScale(0, 0.1873),
				Size = UDim2.fromScale(1, 0.01124),
				BackgroundColor3 = Color3.new(1, 0.2, 0.098), -- Orange-red
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				ZIndex = 0,
			}),
		}),

		-- TextLabels - NPS threshold labels (ZIndex 2)
		TextLabels = e(UI.Frame, {
			Position = UDim2.fromScale(0, 0.00121),
			Size = UDim2.fromScale(1, 0.9991),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, {
			-- Label for 7 NPS
			Part1 = e(UI.TextLabel, {
				Position = UDim2.fromScale(0.0213, 0.7939),
				Size = UDim2.fromScale(0.2, 0),
				Text = "7",
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextStrokeTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.GothamMedium,
				ZIndex = 2,
			}),

			-- Label for 14 NPS
			Part2 = e(UI.TextLabel, {
				Position = UDim2.fromScale(0.0213, 0.5917),
				Size = UDim2.fromScale(0.2, 0),
				Text = "14",
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextStrokeTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.GothamMedium,
				ZIndex = 2,
			}),

			-- Label for 21 NPS
			Part3 = e(UI.TextLabel, {
				Position = UDim2.fromScale(0.0213, 0.3895),
				Size = UDim2.fromScale(0.2, 0),
				Text = "21",
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextStrokeTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.GothamMedium,
				ZIndex = 2,
			}),

			-- Label for 28 NPS
			Part4 = e(UI.TextLabel, {
				Position = UDim2.fromScale(0.0213, 0.1873),
				Size = UDim2.fromScale(0.2, 0),
				Text = "28",
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextStrokeTransparency = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.GothamMedium,
				ZIndex = 2,
			}),
		}),

		-- No data placeholder
		NoData = not npsData and e(UI.TextLabel, {
			Text = "No NPS data",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(120, 120, 120),
			TextSize = 12,
			Font = Enum.Font.GothamMedium,
		}),
	})
end

return NpsGraph
