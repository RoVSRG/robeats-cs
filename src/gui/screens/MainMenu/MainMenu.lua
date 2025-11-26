local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local MenuBar = require(script.Parent.Components.MenuBar)
local Profile = require(script.Parent.Components.Profile)
local FunnyText = require(script.Parent.Components.FunnyText)
local PlayerCount = require(script.Parent.Components.PlayerCount)

local e = React.createElement

local function MainMenu()
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0,
	}, {
		-- Background Image could go here
		
		Title = e("TextLabel", {
			Text = "RoBeats CS",
			Font = Enum.Font.FredokaOne,
			TextSize = 48,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.new(0.3, 0, 0.15, 0),
			Position = UDim2.new(0.05, 0, 0.05, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		
		FunnyText = e(FunnyText, {
			Position = UDim2.new(0.35, 0, 0.08, 0),
			Size = UDim2.new(0.3, 0, 0.05, 0),
			TextSize = 20,
			TextColor3 = Color3.fromRGB(255, 200, 200),
		}),
		
		MenuBar = e(MenuBar),
		
		Profile = e(Profile),
		
		PlayerCount = e(PlayerCount),
		
		MusicPlayer = e("Frame", {
			Size = UDim2.new(0, 250, 0, 80),
			Position = UDim2.new(0.95, 0, 0.85, 0),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BackgroundTransparency = 0.5,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Label = e("TextLabel", {
				Text = "🎵 Now Playing Placeholder",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				Font = Enum.Font.Gotham,
				TextSize = 14,
			})
		}),

		Version = e("TextLabel", {
			Text = "v2.0.0 - React Refactor",
			Size = UDim2.new(0, 200, 0, 20),
			Position = UDim2.new(1, -10, 0.95, 0),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(100, 100, 100),
			Font = Enum.Font.Code,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
	})
end

return MainMenu
