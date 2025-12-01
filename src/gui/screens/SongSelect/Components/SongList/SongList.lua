local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local VirtualList = require(script.Parent.VirtualList)
local SongButton = require(script.Parent.SongButton)

-- Fix paths: go up from SongList -> SongList/ -> Components/ -> SongSelect/ -> hooks/
local SongSelectFolder = script.Parent.Parent.Parent
local useDebounce = require(SongSelectFolder.hooks.useDebounce)
local useSongList = require(SongSelectFolder.hooks.useSongList)

local e = React.createElement
local useState = React.useState
local useCallback = React.useCallback

-- Sort mode labels
local SORT_LABELS = {
	Default = "Sort by: Release Date",
	Difficulty = "Sort by: Difficulty",
	Artist = "Sort by: Artist",
	Title = "Sort by: Title",
}

-- Color mode labels
local COLOR_LABELS = {
	Default = "Color: Default",
	Difficulty = "Color: Difficulty",
	NPS = "Color: NPS",
}

--[[
	SongList - Main song list container matching archive SongSelection structure

	Archive layout:
	- bg: Background frame at (0.017, 0.012), size (0.966, 0.887)
	- SongButtonContainer: ScrollingFrame at (0.017, 0.0125), size (0.966, 0.8875)
	- SortByButton: Position (0.259, 0.917), size (0.431, 0.031)
	- ColorButton: Position (0.707, 0.917), size (0.276, 0.031)
	- SearchField: Position (0.259, 0.959), size (0.597, 0.029)
	- ClearSearchButton: Position (0.879, 0.959), size (0.103, 0.029)
]]
local function SongList(props)
	-- Local state for search and filters
	local searchTerm, setSearchTerm = useState("")
	local sortMode, setSortMode = useState("Default")
	local colorMode, setColorMode = useState("Default")

	-- Debounce search term (300ms delay)
	local debouncedSearch = useDebounce(searchTerm, 0.3)

	-- Get filtered, sorted, and colored songs
	local songs = useSongList(debouncedSearch, sortMode, colorMode)

	-- Cycle through sort modes
	local function cycleSortMode()
		local modes = { "Default", "Difficulty", "Artist", "Title" }
		for i, mode in ipairs(modes) do
			if mode == sortMode then
				setSortMode(modes[(i % #modes) + 1])
				return
			end
		end
	end

	-- Cycle through color modes
	local function cycleColorMode()
		local modes = { "Default", "Difficulty", "NPS" }
		for i, mode in ipairs(modes) do
			if mode == colorMode then
				setColorMode(modes[(i % #modes) + 1])
				return
			end
		end
	end

	-- Clear search
	local function clearSearch()
		setSearchTerm("")
	end

	-- Render function for VirtualList
	local renderSongButton = useCallback(function(song, index, layoutProps)
		return e(SongButton, {
			key = song.ID,
			song = song,
			size = layoutProps.Size,
			color = song.Color,
		})
	end, {})

	return e(UI.Frame, {
		Size = props.size or UDim2.fromScale(0.35406363, 1),
		Position = props.position or UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		-- Background frame - Position (0.017, 0.012), Size (0.966, 0.887)
		bg = e(UI.Frame, {
			Position = UDim2.fromScale(0.017, 0.012),
			Size = UDim2.fromScale(0.966, 0.887),
			BackgroundColor3 = Color3.fromRGB(25, 25, 25),
			BorderSizePixel = 0,
			ZIndex = 0,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
		}),

		-- Song button container (ScrollingFrame) - Position (0.017, 0.0125), Size (0.966, 0.8875)
		SongButtonContainer = e(VirtualList, {
			items = songs,
			itemHeight = 38,
			itemsPerPage = 50,
			renderItem = renderSongButton,
			position = UDim2.fromScale(0.017241379, 0.0125),
			size = UDim2.fromScale(0.9655172, 0.8875),
		}),

		-- Sort by button - Position (0.259, 0.917), Size (0.431, 0.031)
		SortByButton = e(UI.TextButton, {
			Text = SORT_LABELS[sortMode],
			Position = UDim2.fromScale(0.25862086, 0.91711897),
			Size = UDim2.fromScale(0.43103451, 0.03054096),
			BackgroundColor3 = Color3.fromRGB(35, 35, 35),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 11,
			TextWrapped = true,
			Font = Enum.Font.GothamMedium,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			[React.Event.MouseButton1Click] = cycleSortMode,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),

		-- Color button - Position (0.707, 0.917), Size (0.276, 0.031)
		ColorButton = e(UI.TextButton, {
			Text = COLOR_LABELS[colorMode],
			Position = UDim2.fromScale(0.7068966, 0.91711897),
			Size = UDim2.fromScale(0.2758620, 0.03054109),
			BackgroundColor3 = Color3.fromRGB(35, 35, 35),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 11,
			TextWrapped = true,
			Font = Enum.Font.GothamMedium,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			[React.Event.MouseButton1Click] = cycleColorMode,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),

		-- Search field - Position (0.259, 0.959), Size (0.597, 0.029)
		SearchField = e("TextBox", {
			Text = searchTerm,
			PlaceholderText = "",
			Position = UDim2.fromScale(0.25862086, 0.959375),
			Size = UDim2.fromScale(0.59665066, 0.02862477),
			BackgroundColor3 = Color3.fromRGB(188, 188, 188),
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamBold,
			ClearTextOnFocus = false,
			BorderSizePixel = 0,
			[React.Change.Text] = function(rbx)
				setSearchTerm(rbx.Text)
			end,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			Padding = e(UI.UIPadding, {
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
			}),
		}),

		-- Clear search button - Position (0.879, 0.959), Size (0.103, 0.029)
		ClearSearchButton = e(UI.TextButton, {
			Text = "Clear",
			Position = UDim2.fromScale(0.87931019, 0.959375),
			Size = UDim2.fromScale(0.10344826, 0.02862477),
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 10,
			TextWrapped = true,
			Font = Enum.Font.GothamMedium,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			[React.Event.MouseButton1Click] = clearSearch,
		}, {
			Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),
	})
end

return SongList
