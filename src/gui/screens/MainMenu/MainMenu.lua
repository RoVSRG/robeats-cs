local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)

local MenuBar = require(script.Parent.Components.MenuBar)
local Profile = require(script.Parent.Components.Profile)
local FunnyText = require(script.Parent.Components.FunnyText)
local PlayerCount = require(script.Parent.Components.PlayerCount)

local e = React.createElement
local useContext = React.useContext

local BUTTON_SIZE = UDim2.new(0.3, 0, 0.075, 0)
local BUTTON_X = 0.025
local BUTTON_Y_START = 0.425
local BUTTON_Y_STEP = 0.1

local function MainMenu()
	local screenContext = useContext(ScreenContext)

	local buttons = {
		{
			text = "Play",
			Position = UDim2.new(BUTTON_X, 0, BUTTON_Y_START + BUTTON_Y_STEP * 0, 0),
			Size = BUTTON_SIZE,
			onClick = function()
				screenContext.switchScreen("SongSelect")
			end,
		},
		{
			text = "Options",
			Position = UDim2.new(BUTTON_X, 0, BUTTON_Y_START + BUTTON_Y_STEP * 1, 0),
			Size = BUTTON_SIZE,
			onClick = function()
				screenContext.switchScreen("Options")
			end,
		},
		{
			text = "Changelog",
			Position = UDim2.new(BUTTON_X, 0, BUTTON_Y_START + BUTTON_Y_STEP * 2, 0),
			Size = BUTTON_SIZE,
			onClick = function()
				screenContext.switchScreen("Changelog")
			end,
		},
		{
			text = "Rankings",
			Position = UDim2.new(BUTTON_X, 0, BUTTON_Y_START + BUTTON_Y_STEP * 3, 0),
			Size = BUTTON_SIZE,
			onClick = function()
				screenContext.switchScreen("YourScores")
			end,
		},
		{
			text = "Global Leaderboard",
			Position = UDim2.new(BUTTON_X, 0, BUTTON_Y_START + BUTTON_Y_STEP * 4, 0),
			Size = BUTTON_SIZE,
			onClick = function()
				screenContext.switchScreen("GlobalRanking")
			end,
		},
	}

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		MainPanel = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(937, 506),
			BackgroundColor3 = Color3.fromRGB(26, 26, 26),
			BorderSizePixel = 0,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),

			BottomBar = e("Frame", {
				Size = UDim2.new(1, 0, 0.05, 0),
				Position = UDim2.new(0, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.fromRGB(22, 22, 22),
				BorderSizePixel = 0,
			}),

			FunnyText = e(FunnyText, {
				Position = UDim2.new(0.0056, 0, 0.0745, 0),
				Size = UDim2.new(0.684, 0, 0.08, 0),
				TextSize = 18,
				TextScaled = true,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.SourceSans,
			}),

			MenuButtons = e(MenuBar, {
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0, 0),
				Padding = UDim.new(0, 0),
				buttons = buttons,
				includeStudioButton = false,
			}),

			Profile = e(Profile, {
				Size = UDim2.fromScale(0.3, 0.15),
				Position = UDim2.fromScale(0.99, 0.02),
				AnchorPoint = Vector2.new(1, 0),
				CornerRadius = UDim.new(0, 4),
			}),

			PlayerCount = e(PlayerCount, {
				Size = UDim2.new(0.2, 0, 0.03, 0),
				Position = UDim2.new(0.99, 0, 0.91, 0),
				AnchorPoint = Vector2.new(1, 0),
				TextScaled = true,
				TextStrokeTransparency = 0.75,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.Gotham,
			}),

			SongEditor = RunService:IsStudio() and e("ImageButton", {
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(48, 48),
				Position = UDim2.new(0.9375, 0, 0.8131, 0),
				Image = "rbxassetid://133195173867741",
				[React.Event.MouseButton1Click] = function()
					ReplicatedStorage.Bindables.ShowSongEditor:Fire()
				end,
			}),
		}),
	})
end

return MainMenu
