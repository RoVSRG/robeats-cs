local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)

local e = React.createElement
local useMemo = React.useMemo

--[[
	NpsGraph - Visualizes NPS (Notes Per Second) over time

	Shows a bar graph of NPS distribution throughout the song
]]
local function NpsGraph(props)
	local songData = props.songData
	local rate = props.rate or 100

	-- Generate NPS data for visualization
	local npsData = useMemo(function()
		if not songData then
			return nil
		end

		-- Check if song has timeline data (preferred)
		if songData.NPSTimeline and #songData.NPSTimeline > 0 then
			-- Apply rate adjustment to timeline
			local timeline = {}
			for i, nps in ipairs(songData.NPSTimeline) do
				timeline[i] = nps * (rate / 100)
			end
			return timeline
		end

		-- Fallback: Generate approximate 4-segment timeline from avg/max
		local avg = (songData.AverageNPS or 0) * (rate / 100)
		local max = (songData.MaxNPS or 0) * (rate / 100)

		return {
			avg * 0.8, -- Intro
			avg * 1.1, -- Build
			max * 0.9, -- Peak
			avg * 0.7, -- Outro
		}
	end, { songData, rate })

	-- Calculate max NPS for scaling
	local maxNps = useMemo(function()
		if not npsData then
			return 0
		end

		local max = 0
		for _, nps in ipairs(npsData) do
			if nps > max then
				max = nps
			end
		end
		return max
	end, { npsData })

	-- Helper: Get color for NPS value (gradient based on intensity)
	local function getNpsColor(nps, max)
		if max == 0 then
			return Color3.fromRGB(100, 100, 100)
		end

		local intensity = nps / max

		if intensity < 0.25 then
			-- Low NPS: Blue
			return Color3.fromRGB(62, 130, 255)
		elseif intensity < 0.5 then
			-- Medium-low NPS: Cyan
			return Color3.fromRGB(62, 200, 255)
		elseif intensity < 0.75 then
			-- Medium-high NPS: Green
			return Color3.fromRGB(80, 200, 120)
		else
			-- High NPS: Yellow/Orange
			return Color3.fromRGB(255, 200, 50)
		end
	end

	-- Generate bar elements
	local bars = {}
	if npsData then
		for i, nps in ipairs(npsData) do
			local heightScale = maxNps > 0 and (nps / maxNps) or 0
			bars["Bar" .. i] = e(UI.Frame, {
				Size = UDim2.new(1 / #npsData, -2, heightScale, 0),
				BackgroundColor3 = getNpsColor(nps, maxNps),
				BorderSizePixel = 0,
				LayoutOrder = i,
			})
		end
	end

	return e(UI.Frame, {
		Size = props.size or UDim2.new(1, 0, 0, 100),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		Padding = e(UI.UIPadding, {
			PaddingTop = UDim.new(0, 5),
			PaddingBottom = UDim.new(0, 5),
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
		}),

		-- Graph container with bars
		GraphContainer = e(UI.Frame, {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 1,
		}, {
			Layout = e(UI.UIListLayout, {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),

			-- Dynamic bars
			Bars = React.createElement(React.Fragment, nil, bars),
		}),

		-- Guide lines overlay
		LineLabels = e(UI.Frame, {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, {
			Layout = e(UI.UIListLayout, {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0.33, 0),
			}),

			-- 75% line
			Line1 = e(UI.Frame, {
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),
				BorderSizePixel = 0,
				LayoutOrder = 1,
			}),

			-- 50% line
			Line2 = e(UI.Frame, {
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),
				BorderSizePixel = 0,
				LayoutOrder = 2,
			}),

			-- 25% line
			Line3 = e(UI.Frame, {
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),
				BorderSizePixel = 0,
				LayoutOrder = 3,
			}),
		}),

		-- Max NPS label overlay
		MaxLabel = maxNps > 0 and e(UI.TextLabel, {
			Text = string.format("%.1f NPS", maxNps),
			Size = UDim2.new(0, 60, 0, 15),
			Position = UDim2.new(1, -65, 0, 5),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Right,
			Font = UI.Theme.fonts.body,
			ZIndex = 3,
		}),

		-- No data placeholder
		NoData = not npsData and e(UI.TextLabel, {
			Text = "No NPS data",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(120, 120, 120),
			TextSize = 12,
			Font = UI.Theme.fonts.body,
		}),
	})
end

return NpsGraph
