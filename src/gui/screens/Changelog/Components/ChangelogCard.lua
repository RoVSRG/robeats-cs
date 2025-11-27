--[[
	ChangelogCard Component

	A single update card showing version, title, and bullet points.
	Mimics the archive's card appearance with random colors.

	Props:
		- version: number - Update version number
		- title: string - Update title
		- lines: table - Array of bullet point strings
		- color: Color3 - Card background color
		- layoutOrder: number - Layout order (for sorting)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

local function ChangelogCard(props)
	local version = props.version or 0
	local title = props.title or "No Title"
	local lines = props.lines or {}
	local color = props.color or Color3.fromRGB(100, 100, 100)

	-- Build children for the card
	local children = {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),

		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),

		UIListLayout = e("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),

		-- Version header
		Header = e("TextLabel", {
			Text = "Patch #" .. tostring(version) .. "  –  " .. title,
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromHex("#ededed"),
			Font = Enum.Font.GothamBold,
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = 1,
		}),
	}

	-- Add bullet points
	for index, line in ipairs(lines) do
		children["Line_" .. index] = e("TextLabel", {
			Text = "• " .. line,
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromHex("#ededed"),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = index + 1,
		})
	end

	return e("Frame", {
		Size = UDim2.new(1, -10, 0, 40),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.layoutOrder or 0,
	}, children)
end

return ChangelogCard
