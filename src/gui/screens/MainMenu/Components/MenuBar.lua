local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)

local e = React.createElement
local useState = React.useState
local useContext = React.useContext

local function MenuButton(props)
	local hover, setHover = useState(false)
	local text = props.text
	local onClick = props.onClick
	local size = props.Size or props.size or UDim2.new(1, 0, 0, 40)
	local position = props.Position or props.position
	local anchorPoint = props.AnchorPoint or props.anchorPoint or Vector2.new(0, 0)

	return e("TextButton", {
		Text = text,
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundColor3 = hover and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(17, 17, 17),
		TextColor3 = hover and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,

		[React.Event.MouseEnter] = function() setHover(true) end,
		[React.Event.MouseLeave] = function() setHover(false) end,
		[React.Event.MouseButton1Click] = onClick,
	}, {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		Padding = e("UIPadding", { PaddingLeft = UDim.new(0, 10) }),
	})
end

local function MenuBar(props)
	local isStudio = RunService:IsStudio()
	local context = useContext(ScreenContext)
	local buttons = props.buttons or {
		{
			text = "Play",
			onClick = function() context.switchScreen("SongSelect") end,
		},
		{
			text = "Options",
			onClick = function() context.switchScreen("Options") end,
		},
		{
			text = "Rankings",
			onClick = function() context.switchScreen("YourScores") end,
		},
		{
			text = "Global Leaderboard",
			onClick = function() context.switchScreen("GlobalRanking") end,
		},
		{
			text = "Changelog",
			onClick = function() context.switchScreen("Changelog") end,
		},
	}

	local includeStudioButton = if props.includeStudioButton == nil then true else props.includeStudioButton

	if isStudio and includeStudioButton then
		table.insert(buttons, {
			text = "Song Editor (Studio)",
			onClick = function()
				ReplicatedStorage.Bindables.ShowSongEditor:Fire()
			end,
		})
	end

	local shouldUseLayout = true
	for _, button in ipairs(buttons) do
		if button.Position or button.position then
			shouldUseLayout = false
			break
		end
	end

	return e("Frame", {
		Size = props.Size or UDim2.new(0, 250, 0.6, 0),
		Position = props.Position or UDim2.new(0.05, 0, 0.2, 0),
		AnchorPoint = props.AnchorPoint,
		BackgroundTransparency = 1,
	}, {
		Layout = shouldUseLayout and e("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = props.Padding or UDim.new(0, 10),
		}) or nil,
		Buttons = e(React.Fragment, nil, (function()
			local children = {}
			for index, button in ipairs(buttons) do
				children[index] = e(MenuButton, {
					text = button.text,
					onClick = button.onClick,
					Size = button.Size,
					Position = button.Position or button.position,
					AnchorPoint = button.AnchorPoint or button.anchorPoint,
					LayoutOrder = index,
				})
			end
			return children
		end)())
	})
end

return MenuBar
