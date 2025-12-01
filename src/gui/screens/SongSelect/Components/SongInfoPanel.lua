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
	SongInfoPanel - Displays NPS stats and graph for selected song

	Archive structure (middle bottom panel):
	- NpsGraph: Position (0, 0.224), Size (1, 0.527)
	- NotesInfo: Position (0, 0.775), Size (1, 0.08782), Left aligned
	- AverageNpsInfo: Position (0, 0.775), Size (1, 0.08782), Center aligned
	- ReleasesInfo: Position (0, 0.875), Size (1, 0.08782), Left aligned
	- MaxNpsInfo: Position (0, 0.875), Size (1, 0.08782), Center aligned
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
		Size = props.size or UDim2.fromScale(0.28691363, 0.325),
		Position = props.position or UDim2.fromScale(0.35406363, 0.675),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		-- NPS Graph - Position (0, 0.224), Size (1, 0.527)
		NpsGraphComponent = songData and e(NpsGraph, {
			position = UDim2.fromScale(0, 0.224),
			size = UDim2.fromScale(1, 0.527),
			songData = songData,
			rate = rate,
		}),

		-- NotesInfo (left aligned) - Position (0, 0.775), Size (1, 0.08782)
		NotesInfo = songData and e(UI.TextLabel, {
			Text = string.format("Total Notes: %d", totalNotes),
			Position = UDim2.fromScale(0, 0.775),
			Size = UDim2.fromScale(1, 0.08782456),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 16,
			TextStrokeTransparency = 0,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamMedium,
			BorderSizePixel = 0,
		}),

		-- AverageNpsInfo (center aligned) - Position (0, 0.775), Size (1, 0.08782)
		AverageNpsInfo = songData and e(UI.TextLabel, {
			Text = string.format("Avg. Nps: %0.1f", avgNps),
			Position = UDim2.fromScale(0, 0.775),
			Size = UDim2.fromScale(1, 0.08782456),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 16,
			TextStrokeTransparency = 0,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamMedium,
			BorderSizePixel = 0,
		}),

		-- ReleasesInfo (left aligned) - Position (0, 0.875), Size (1, 0.08782)
		ReleasesInfo = songData and e(UI.TextLabel, {
			Text = string.format("Total Holds: %d", totalHolds),
			Position = UDim2.fromScale(0, 0.875),
			Size = UDim2.fromScale(1, 0.08782456),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 16,
			TextStrokeTransparency = 0,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamMedium,
			BorderSizePixel = 0,
		}),

		-- MaxNpsInfo (center aligned) - Position (0, 0.875), Size (1, 0.08782)
		MaxNpsInfo = songData and e(UI.TextLabel, {
			Text = string.format("Max Nps: %0.1f", maxNps),
			Position = UDim2.fromScale(0, 0.875),
			Size = UDim2.fromScale(1, 0.08782456),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 16,
			TextStrokeTransparency = 0,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamMedium,
			BorderSizePixel = 0,
		}),

		-- Placeholder if no song selected
		NoSelection = not songData and e(UI.TextLabel, {
			Text = "Select a song",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(120, 120, 120),
			TextSize = 14,
			Font = Enum.Font.GothamMedium,
		}),
	})
end

return SongInfoPanel
