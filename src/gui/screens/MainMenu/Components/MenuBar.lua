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

	return e("TextButton", {
		Text = text,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = hover and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(17, 17, 17),
		TextColor3 = hover and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		AutoButtonColor = false,
		BorderSizePixel = 0,

		[React.Event.MouseEnter] = function() setHover(true) end,
		[React.Event.MouseLeave] = function() setHover(false) end,
		[React.Event.MouseButton1Click] = onClick,
	}, {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Padding = e("UIPadding", { PaddingLeft = UDim.new(0, 10) }),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

local function MenuBar(props)
	local isStudio = RunService:IsStudio()
	local context = useContext(ScreenContext)

	return e("Frame", {
		Size = UDim2.new(0, 250, 0.6, 0),
		Position = UDim2.new(0.05, 0, 0.2, 0), -- Left side
		BackgroundTransparency = 1,
	}, {
		Layout = e("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),

		Play = e(MenuButton, {
			text = "Play",
			onClick = function() context.switchScreen("SongSelect") end,
		}),
		
		Options = e(MenuButton, {
			text = "Options",
			onClick = function() context.switchScreen("Options") end,
		}),
		
		Rankings = e(MenuButton, {
			text = "Rankings",
			onClick = function() context.switchScreen("YourScores") end,
		}),
		
		GlobalLB = e(MenuButton, {
			text = "Global Leaderboard",
			onClick = function() context.switchScreen("GlobalRanking") end,
		}),
		
		Changelog = e(MenuButton, {
			text = "Changelog",
			onClick = function() context.switchScreen("Changelog") end,
		}),

		Editor = isStudio and e(MenuButton, {
			text = "Song Editor (Studio)",
			onClick = function() 
				ReplicatedStorage.Bindables.ShowSongEditor:Fire()
			end,
		})
	})
end

return MenuBar