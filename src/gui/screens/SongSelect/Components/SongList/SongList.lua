local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local VirtualList = require(script.Parent.VirtualList)
local SongButton = require(script.Parent.SongButton)
local SearchBar = require(script.Parent.SearchBar)
local FilterControls = require(script.Parent.FilterControls)

-- Fix paths: go up from SongList -> SongList/ -> Components/ -> SongSelect/ -> hooks/
local SongSelectFolder = script.Parent.Parent.Parent
local useDebounce = require(SongSelectFolder.hooks.useDebounce)
local useSongList = require(SongSelectFolder.hooks.useSongList)

local e = React.createElement
local useState = React.useState
local useCallback = React.useCallback

--[[
	SongList - Main song list container with search, filters, and virtual scrolling

	Props:
		size: UDim2 - Size of the list container
		position: UDim2 - Position of the list container
		viewportHeight: number - Height of viewport for virtualization
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

	-- Render function for PaginatedList
	-- Memoize this to prevent recreating the function every render
	local renderSongButton = useCallback(function(song, index, layoutProps)
		return e(SongButton, {
			key = song.ID,
			song = song,
			size = layoutProps.Size,
			color = song.Color,
		})
	end, {})

	return e(UI.Frame, {
		Size = props.size or UDim2.new(0.35, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(29, 28, 29),
		BorderSizePixel = 0,
	}, {
		Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),
		Padding = e(UI.UIPadding, {
			PaddingTop = UDim.new(0, 5),
			PaddingBottom = UDim.new(0, 5),
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
		}),

		Layout = e(UI.UIListLayout, {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),

		-- Search bar
		SearchBar = e(SearchBar, {
			searchTerm = searchTerm,
			onSearchChange = setSearchTerm,
			size = UDim2.new(1, 0, 0, 35),
		}),

		-- Filter controls (Sort/Color)
		FilterControls = e(FilterControls, {
			sortMode = sortMode,
			colorMode = colorMode,
			onSortChange = setSortMode,
			onColorChange = setColorMode,
			size = UDim2.new(1, 0, 0, 35),
		}),

		-- Paginated list
		PaginatedList = e(VirtualList, {
			items = songs,
			itemHeight = 38,
			itemsPerPage = 50, -- Show 50 songs per page
			renderItem = renderSongButton,
			size = UDim2.new(1, 0, 1, -80),
		}),
	})
end

return SongList
