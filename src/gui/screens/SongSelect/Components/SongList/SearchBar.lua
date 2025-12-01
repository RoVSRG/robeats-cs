local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)

local e = React.createElement

--[[
	SearchBar - Search input with clear button

	Props:
		searchTerm: string - Current search term
		onSearchChange: function(newTerm) - Callback when search changes
		size: UDim2 - Size of the search bar (optional)
		position: UDim2 - Position of the search bar (optional)
]]
local function SearchBar(props)
	local searchTerm = props.searchTerm or ""
	local onSearchChange = props.onSearchChange

	local function handleTextChange(rbx)
		if onSearchChange then
			onSearchChange(rbx.Text)
		end
	end

	local function handleClear()
		if onSearchChange then
			onSearchChange("")
		end
	end

	return e(UI.Frame, {
		Size = props.size or UDim2.new(1, 0, 0, 40),
		Position = props.position or UDim2.fromScale(0, 0),
		BackgroundColor3 = Color3.fromRGB(21, 21, 21),
		BorderSizePixel = 0,
	}, {
		Corner = e(UI.UICorner, { CornerRadius = UDim.new(0, 8) }),

		-- Search input field (using raw TextBox since UI.Primitives doesn't have it)
		SearchField = e("TextBox", {
			Text = searchTerm,
			PlaceholderText = "Search songs...",
			Size = UDim2.new(1, -50, 1, 0),
			Position = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(230, 230, 230),
			PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
			TextSize = 14,
			Font = UI.Theme.fonts.body,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			BorderSizePixel = 0,
			[React.Change.Text] = handleTextChange,
		}, {
			Padding = e(UI.UIPadding, {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
		}),

		-- Clear button
		ClearButton = e(UI.TextButton, {
			Text = "X",
			Size = UDim2.new(0, 40, 0, 40),
			Position = UDim2.new(1, -40, 0, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			TextSize = 18,
			Font = UI.Theme.fonts.bold,
			AutoButtonColor = false,
			Visible = searchTerm ~= "",
			[React.Event.MouseButton1Click] = handleClear,
		}),
	})
end

return SearchBar
