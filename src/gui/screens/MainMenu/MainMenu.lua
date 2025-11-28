local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local UI = require(ReplicatedStorage.Util.UI)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)

local MenuBar = require(script.Parent.Components.MenuBar)
local Profile = require(script.Parent.Components.Profile)
local FunnyText = require(script.Parent.Components.FunnyText)
local PlayerCount = require(script.Parent.Components.PlayerCount)

local function MainMenu()
	local screenContext = React.useContext(ScreenContext)

	return UI.Frame({
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		children = {
			MainPanel = UI.Frame({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.49926254, 0),
				Size = UDim2.fromOffset(937, 506),
				BackgroundColor3 = Color3.fromRGB(26, 26, 26),
				BorderSizePixel = 0,
				children = {
					UI.Corner({ CornerRadius = UDim.new(0, 4) }),

					FunnyText = FunnyText({
						Position = UDim2.new(0, 30, 0, 38),
						Size = UDim2.fromOffset(300, 30),
						AnchorPoint = Vector2.new(0, 0.5),
						TextSize = 18,
						TextScaled = true,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						Font = Enum.Font.SourceSansLight,
					}),

					PlayButton = UI.Button({
						Position = UDim2.new(0.025, 0, 0.425, 0),
						Size = UDim2.new(0.3, 0, 0.075, 0),
						Text = "PLAY",
						TextProps = {
							TextXAlignment = Enum.TextXAlignment.Left,
						},
						onClick = function()
							screenContext.switchScreen("SongSelect")
						end,
					}),

					OptionsButton = UI.Button({
						Position = UDim2.new(0.025, 0, 0.525, 0),
						Size = UDim2.new(0.3, 0, 0.075, 0),
						Text = "OPTIONS",
						TextProps = {
							TextXAlignment = Enum.TextXAlignment.Left,
						},
						onClick = function()
							screenContext.switchScreen("Options")
						end,
					}),

					ChangelogButton = UI.Button({
						Position = UDim2.new(0.025, 0, 0.625, 0),
						Size = UDim2.new(0.3, 0, 0.075, 0),
						Text = "CHANGELOG",
						TextProps = {
							TextXAlignment = Enum.TextXAlignment.Left,
						},
						onClick = function()
							screenContext.switchScreen("Changelog")
						end,
					}),

					RankingsButton = UI.Button({
						Position = UDim2.new(0.025, 0, 0.725, 0),
						Size = UDim2.new(0.3, 0, 0.075, 0),
						Text = "RANKINGS",
						TextProps = {
							TextXAlignment = Enum.TextXAlignment.Left,
						},
						onClick = function()
							screenContext.switchScreen("YourScores")
						end,
					}),

					GlobalLBButton = UI.Button({
						Position = UDim2.new(0.025, 0, 0.825, 0),
						Size = UDim2.new(0.3, 0, 0.075, 0),
						Text = "GLOBAL LEADERBOARD",
						TextProps = {
							TextXAlignment = Enum.TextXAlignment.Left,
						},
						onClick = function()
							screenContext.switchScreen("GlobalRanking")
						end,
					}),

					Profile = Profile({
						Size = UDim2.new(0.3, 0, 0.15, 0),
						Position = UDim2.new(0.99, 0, 0.02, 0),
						AnchorPoint = Vector2.new(1, 0),
					}),

					PlayerCount = PlayerCount({
						Size = UDim2.new(0.2, 0, 0.03, 0),
						Position = UDim2.new(0.99, 0, 0.91, 0),
						AnchorPoint = Vector2.new(1, 0),
						TextScaled = true,
						TextStrokeTransparency = 0.75,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						Font = Enum.Font.Gotham,
						TextXAlignment = Enum.TextXAlignment.Center,
					}),

					ShowSongEditor = RunService:IsStudio() and UI.Element("ImageButton", {
						AutoButtonColor = false,
						BackgroundTransparency = 1,
						Size = UDim2.fromOffset(48, 48),
						Position = UDim2.new(0.9375, 0, 0.813118, 0),
						Image = "rbxassetid://133195173867741",
						[React.Event.MouseButton1Click] = function()
							ReplicatedStorage.Bindables.ShowSongEditor:Fire()
						end,
					}) or nil,

					MenuBar = MenuBar({
						includeStudioButton = false,
					}),
				},
			}),
		},
	})
end

return MainMenu
