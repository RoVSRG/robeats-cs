local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local ScreenContext = React.createContext({
	currentScreen = "MainMenu",
	switchScreen = function(screenName) end
})

return ScreenContext
