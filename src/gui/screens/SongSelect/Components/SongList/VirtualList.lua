local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)

local e = React.createElement
local useState = React.useState
local useMemo = React.useMemo

--[[
	PaginatedList - Pagination-based list component

	Shows a fixed number of items per page with Previous/Next navigation.
	Much simpler and more reliable than virtual scrolling.

	Props:
		items: table - Full list of items to display
		itemHeight: number - Fixed height per item (default: 38)
		itemsPerPage: number - Number of items per page (default: 50)
		renderItem: function(item, index) - Function to render each item
		size: UDim2 - Size of the container (optional)
]]
local function PaginatedList(props)
	local items = props.items or {}
	local itemHeight = props.itemHeight or 38
	local itemsPerPage = props.itemsPerPage or 50
	local renderItem = props.renderItem

	-- Track current page (1-indexed)
	local currentPage, setCurrentPage = useState(1)

	-- Calculate pagination
	local totalPages = math.ceil(#items / itemsPerPage)
	local startIndex = (currentPage - 1) * itemsPerPage + 1
	local endIndex = math.min(currentPage * itemsPerPage, #items)

	-- Get items for current page
	local pageItems = useMemo(function()
		local page = {}
		for i = startIndex, endIndex do
			if items[i] then
				table.insert(page, items[i])
			end
		end
		return page
	end, { startIndex, endIndex, items })

	-- Reset to page 1 when items change (e.g., after search/filter)
	React.useEffect(function()
		setCurrentPage(1)
	end, { #items })

	-- Build children for current page
	local children = {
		Layout = e(UI.UIListLayout, {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),
	}

	for i, item in ipairs(pageItems) do
		children["Item_" .. (startIndex + i - 1)] = renderItem(item, startIndex + i - 1, {
			Size = UDim2.new(1, -10, 0, itemHeight),
		})
	end

	-- Navigation buttons
	local function handlePrevious()
		if currentPage > 1 then
			setCurrentPage(currentPage - 1)
		end
	end

	local function handleNext()
		if currentPage < totalPages then
			setCurrentPage(currentPage + 1)
		end
	end

	return e(UI.Frame, {
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position or UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		-- Song list (scrollable)
		ScrollingFrame = e("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, -30), -- Leave room for pagination controls
			Position = UDim2.fromScale(0, 0),
			CanvasSize = UDim2.fromOffset(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 8,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Active = true,
		}, children),

		-- Pagination controls
		PaginationControls = e(UI.Frame, {
			Size = UDim2.new(1, 0, 0, 25),
			Position = UDim2.new(0, 0, 1, -25),
			BackgroundColor3 = Color3.fromRGB(21, 21, 21),
			BorderSizePixel = 0,
		}, {
			Layout = e(UI.UIListLayout, {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
			}),

			-- Previous button
			PrevButton = e(UI.TextButton, {
				Text = "◀",
				Size = UDim2.new(0, 40, 0, 20),
				BackgroundColor3 = currentPage > 1 and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(40, 40, 40),
				TextColor3 = currentPage > 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100),
				TextSize = 14,
				Font = UI.Theme.fonts.bold,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				LayoutOrder = 1,
				[React.Event.MouseButton1Click] = handlePrevious,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			}),

			-- Page indicator
			PageLabel = e(UI.TextLabel, {
				Text = string.format("Page %d / %d", currentPage, math.max(1, totalPages)),
				Size = UDim2.new(0, 120, 0, 20),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextSize = 12,
				Font = UI.Theme.fonts.body,
				LayoutOrder = 2,
			}),

			-- Next button
			NextButton = e(UI.TextButton, {
				Text = "▶",
				Size = UDim2.new(0, 40, 0, 20),
				BackgroundColor3 = currentPage < totalPages and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(40, 40, 40),
				TextColor3 = currentPage < totalPages and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(100, 100, 100),
				TextSize = 14,
				Font = UI.Theme.fonts.bold,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				LayoutOrder = 3,
				[React.Event.MouseButton1Click] = handleNext,
			}, {
				Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
			}),
		}),
	})
end

return PaginatedList
