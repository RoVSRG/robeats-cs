local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)

local UI = require(ReplicatedStorage.Components.Primitives)
local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)

local MenuBar = require(script.Parent.Components.MenuBar)
local Profile = require(script.Parent.Components.Profile)
local FunnyText = require(script.Parent.Components.FunnyText)
local PlayerCount = require(script.Parent.Components.PlayerCount)
local Gato = require(script.Parent.Components.Gato)

local e = React.createElement

local function MainMenu()
	local screenContext = React.useContext(ScreenContext)

	local children = {
		e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),

		e(FunnyText, {
			Position = UDim2.new(0, 30, 0, 38),
			Size = UDim2.fromOffset(300, 30),
			AnchorPoint = Vector2.new(0, 0.5),
			TextSize = 18,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.SourceSansLight,
		}),

		e(UI.TextButton, {
			Position = UDim2.new(0.025, 0, 0.425, 0),
			Size = UDim2.new(0.3, 0, 0.075, 0),
			Text = "PLAY",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 18,
			[React.Event.MouseButton1Click] = function()
				screenContext.switchScreen("SongSelect")
			end,
		}, {
			e(UI.UIPadding, { PaddingLeft = UDim.new(0, 10) }),
			e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),

		e(UI.TextButton, {
			Position = UDim2.new(0.025, 0, 0.525, 0),
			Size = UDim2.new(0.3, 0, 0.075, 0),
			Text = "OPTIONS",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 18,
			[React.Event.MouseButton1Click] = function()
				screenContext.switchScreen("Options")
			end,
		}, {
			e(UI.UIPadding, { PaddingLeft = UDim.new(0, 10) }),
			e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),

		e(UI.TextButton, {
			Position = UDim2.new(0.025, 0, 0.625, 0),
			Size = UDim2.new(0.3, 0, 0.075, 0),
			Text = "CHANGELOG",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 18,
			[React.Event.MouseButton1Click] = function()
				screenContext.switchScreen("Changelog")
			end,
		}, {
			e(UI.UIPadding, { PaddingLeft = UDim.new(0, 10) }),
			e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),

		e(UI.TextButton, {
			Position = UDim2.new(0.025, 0, 0.725, 0),
			Size = UDim2.new(0.3, 0, 0.075, 0),
			Text = "RANKINGS",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 18,
			[React.Event.MouseButton1Click] = function()
				screenContext.switchScreen("YourScores")
			end,
		}, {
			e(UI.UIPadding, { PaddingLeft = UDim.new(0, 10) }),
			e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),

		e(UI.TextButton, {
			Position = UDim2.new(0.025, 0, 0.825, 0),
			Size = UDim2.new(0.3, 0, 0.075, 0),
			Text = "GLOBAL LEADERBOARD",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 18,
			[React.Event.MouseButton1Click] = function()
				screenContext.switchScreen("GlobalRanking")
			end,
		}, {
			e(UI.UIPadding, { PaddingLeft = UDim.new(0, 10) }),
			e(UI.UICorner, { CornerRadius = UDim.new(0, 4) }),
		}),

		e(Profile, {
			Size = UDim2.new(0.3, 0, 0.15, 0),
			Position = UDim2.new(0.99, 0, 0.02, 0),
			AnchorPoint = Vector2.new(1, 0),
		}),

		e(PlayerCount, {
			Size = UDim2.new(0.2, 0, 0.03, 0),
			Position = UDim2.new(0.99, 0, 0.91, 0),
			AnchorPoint = Vector2.new(1, 0),
			TextScaled = true,
			TextStrokeTransparency = 0.75,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Center,
		}),

		e(Gato),

		e(MenuBar, {
			includeStudioButton = false,
		}),
	}

	if RunService:IsStudio() then
		table.insert(children, e(UI.ImageButton, {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(48, 48),
			Position = UDim2.new(0.9375, 0, 0.813118, 0),
			Image = "rbxassetid://133195173867741",
			[React.Event.MouseButton1Click] = function()
				ReplicatedStorage.Bindables.ShowSongEditor:Fire()
			end,
		}))
	end

	return e(UI.Frame, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		e(UI.Frame, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.49926254, 0),
			Size = UDim2.fromOffset(937, 506),
			BackgroundColor3 = Color3.fromRGB(26, 26, 26),
			BorderSizePixel = 0,
		}, children),
	})
end

return MainMenu
