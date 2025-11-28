local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local defaults = {
	colors = {
		background = Color3.fromRGB(26, 26, 26),
		panel = Color3.fromRGB(17, 17, 17),
		panelMuted = Color3.fromRGB(22, 22, 22),
		textPrimary = Color3.fromRGB(255, 255, 255),
		textSubtle = Color3.fromRGB(200, 200, 200),
		button = Color3.fromRGB(17, 17, 17),
		buttonHover = Color3.fromRGB(255, 255, 255),
	},
	fonts = {
		body = Enum.Font.Gotham,
		bold = Enum.Font.GothamBold,
		light = Enum.Font.SourceSansLight,
	},
	textSize = 18,
	corner = UDim.new(0, 4),
	padding = UDim.new(0, 10),
}

local ThemeContext = React.createContext(defaults)

return {
	Context = ThemeContext,
	defaults = defaults,
}
