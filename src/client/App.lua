local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local SongDatabase = require(ReplicatedStorage.SongDatabase)

local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)

-- Import Screens
local MainMenu = require(script.Parent.Parent.gui.screens.MainMenu.MainMenu)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function LoadingScreen()
	local dots, setDots = useState(0)
	
	useEffect(function()
		local running = true
		task.spawn(function()
			while running do
				task.wait(0.3)
				setDots(function(d) 
					return (d + 1) % 4 
				end)
			end
		end)
		return function() 
			running = false 
		end
	end, {})
	
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 10, 10),
	}, {
		Label = e("TextLabel", {
			Text = "Loading songs" .. string.rep(".", dots),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 24
		})
	})
end

local function App()
	local isLoaded, setIsLoaded = useState(SongDatabase.IsLoaded)
	local currentScreen, setCurrentScreen = useState("MainMenu")

	useEffect(function()
		if not isLoaded then
			if SongDatabase.IsLoaded then
				setIsLoaded(true)
			else
				local conn
				conn = SongDatabase.Loaded.Event:Connect(function()
					setIsLoaded(true)
					conn:Disconnect()
				end)
				return function() 
					if conn then 
						conn:Disconnect() 
					end 
				end
			end
		end
	end, {isLoaded})

	local function switchScreen(screenName)
		print("Switching to screen:", screenName)
		setCurrentScreen(screenName)
	end

	local function renderScreen()
		if not isLoaded then
			return e(LoadingScreen)
		end
		
		if currentScreen == "MainMenu" then
			return e(MainMenu)
		else
			-- Generic Placeholder for missing/archived screens
			return e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			}, {
				Label = e("TextLabel", {
					Text = "Screen not implemented yet: " .. currentScreen,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Font = Enum.Font.GothamBold,
					TextSize = 24
				}),
				BackButton = e("TextButton", {
					Text = "Back to Menu",
					Size = UDim2.fromOffset(200, 50),
					Position = UDim2.fromScale(0.5, 0.6),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(50, 50, 50),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					[React.Event.MouseButton1Click] = function()
						switchScreen("MainMenu")
					end
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) })
				})
			})
		end
	end

	return e(ScreenContext.Provider, {
		value = {
			currentScreen = currentScreen,
			switchScreen = switchScreen
		}
	}, {
		AppContainer = e("ScreenGui", {
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
		}, {
			Content = renderScreen()
		})
	})
end

return App