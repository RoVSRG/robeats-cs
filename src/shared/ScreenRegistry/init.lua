--[[
	Screen Registry

	Explicit static imports for all game screens.
	This replaces runtime screen discovery with type-safe compile-time imports.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local React = require(ReplicatedStorage.Packages.React)

-- Import existing screens from StarterGui.Screens
local Screens = StarterGui:WaitForChild("Screens")
local MainMenu = require(Screens.MainMenu.MainMenu)
local SongSelect = require(Screens.SongSelect.SongSelect)
local Options = require(Screens.Options.Options)
local Changelog = require(Screens.Changelog.Changelog)
local Gameplay = require(Screens.Gameplay.Gameplay)
local Results = require(Screens.Results.Results)

-- Placeholder component for screens not yet implemented
local function PlaceholderScreen(props)
	local screenName = props.screenName or "Unknown"
	local e = React.createElement

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
	}, {
		Label = e("TextLabel", {
			Text = "Screen not implemented yet: " .. screenName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 24,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),
		BackButton = e("TextButton", {
			Text = "Back to Menu",
			Size = UDim2.fromOffset(200, 50),
			Position = UDim2.fromScale(0.5, 0.6),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.Gotham,
			TextSize = 18,
			[React.Event.MouseButton1Click] = function()
				-- Will be overridden by App.lua when rendering
				if props.onBack then
					props.onBack()
				end
			end,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) })
		})
	})
end

-- Screen registry
-- As screens are implemented, replace PlaceholderScreen with actual imports
local ScreenRegistry = {
	MainMenu = MainMenu,
	SongSelect = SongSelect,
	Options = Options,
	Changelog = Changelog,
	GlobalRanking = PlaceholderScreen,
	YourScores = PlaceholderScreen,
	Gameplay = Gameplay,
	Results = Results,
	Initialize = PlaceholderScreen,
}

return ScreenRegistry
