local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local useTransient = require(ReplicatedStorage.hooks.useTransient)
local SongDatabase = require(ReplicatedStorage.SongDatabase)
local NpsGraph = require(script.Parent.NpsGraph)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

--[[
	SongInfoPanel - Displays selected song details and NPS graph

	Subscribes to Transient.song.selected
]]
local function SongInfoPanel(props)
	local selectedSongId = useTransient("song.selected")
	local rate = useTransient("song.rate")

	local songData, setSongData = useState(nil)

	-- Update song data when selection changes
	useEffect(function()
		if selectedSongId then
			local data = SongDatabase:GetSongByKey(selectedSongId)
			setSongData(data)
		else
			setSongData(nil)
		end
	end, { selectedSongId })

	-- Calculate stats (adjusted by rate for display)
	local avgNps = songData and (songData.AverageNPS or 0) * (rate / 100) or 0
	local maxNps = songData and (songData.MaxNPS or 0) * (rate / 100) or 0
	local totalNotes = songData and (songData.TotalSingleNotes or 0) or 0
	local totalHolds = songData and (songData.TotalHoldNotes or 0) or 0

	return e(UI.Frame, {
		Size = props.size or UDim2.new(1, 0, 0.34, 0),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BorderSizePixel = 0,
	}, {
		Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
		Padding = e(UI.UIPadding, {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),

		Layout = e(UI.UIListLayout, {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),

		-- Song title
		Title = songData and e(UI.TextLabel, {
			Text = songData.SongName or "No Song Selected",
			Size = UDim2.new(1, 0, 0, 25),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.Theme.fonts.bold,
			LayoutOrder = 1,
		}),

		-- Artist
		Artist = songData and e(UI.TextLabel, {
			Text = "by " .. (songData.ArtistName or "Unknown"),
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.Theme.fonts.body,
			LayoutOrder = 2,
		}),

		-- Charter
		Charter = songData and e(UI.TextLabel, {
			Text = "mapped by " .. (songData.CharterName or "Unknown"),
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(150, 150, 150),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = UI.Theme.fonts.body,
			LayoutOrder = 3,
		}),

		-- Stats container
		Stats = songData and e(UI.Frame, {
			Size = UDim2.new(1, 0, 0, 80),
			BackgroundTransparency = 1,
			LayoutOrder = 4,
		}, {
			Layout = e(UI.UIListLayout, {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 3),
			}),

			AvgNps = e(UI.TextLabel, {
				Text = string.format("Avg. NPS: %.1f", avgNps),
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = UI.Theme.fonts.body,
				LayoutOrder = 1,
			}),

			MaxNps = e(UI.TextLabel, {
				Text = string.format("Max NPS: %.1f", maxNps),
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = UI.Theme.fonts.body,
				LayoutOrder = 2,
			}),

			NotesInfo = e(UI.TextLabel, {
				Text = string.format("Notes: %d (%d holds)", totalNotes + totalHolds, totalHolds),
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = UI.Theme.fonts.body,
				LayoutOrder = 3,
			}),
		}),

		-- NPS Graph
		NpsGraphComponent = songData and e(NpsGraph, {
			size = UDim2.new(1, 0, 0, 80),
			songData = songData,
			rate = rate,
			layoutOrder = 5,
		}),

		-- Placeholder if no song selected
		NoSelection = not songData and e(UI.TextLabel, {
			Text = "Select a song to view details",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(120, 120, 120),
			TextSize = 16,
			Font = UI.Theme.fonts.body,
			LayoutOrder = 1,
		}),
	})
end

return SongInfoPanel
