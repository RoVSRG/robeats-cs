local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local React = require(ReplicatedStorage.Packages.React)
local SongDatabase = require(ReplicatedStorage.SongDatabase)

local ScreenContext = require(ReplicatedStorage.Contexts.ScreenContext)
local Screens = require(ReplicatedStorage.ScreenRegistry)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local MAIN_RESOLUTION = Vector2.new(1280, 720)
local MAX_SCALE = 1.5

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
		local mainGui = playerGui:FindFirstChild("Main")
		if not mainGui then
			return function() end -- Return empty cleanup function
		end

		local uiScale = mainGui:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		uiScale.Parent = mainGui

		local function refreshScaling(camera)
			if not camera then
				return
			end

			local viewportSize: Vector2 = camera.ViewportSize
			local scale = math.min(viewportSize.X / MAIN_RESOLUTION.X, viewportSize.Y / MAIN_RESOLUTION.Y)
			uiScale.Scale = math.min(scale, MAX_SCALE)
		end

		local viewportConn: RBXScriptConnection? = nil
		local function connectCamera(camera)
			if viewportConn then
				viewportConn:Disconnect()
				viewportConn = nil
			end

			if camera then
				viewportConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
					refreshScaling(camera)
				end)
				refreshScaling(camera)
			end
		end

		local cameraConn = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			connectCamera(Workspace.CurrentCamera)
		end)

		connectCamera(Workspace.CurrentCamera)

		return function()
			if cameraConn then
				cameraConn:Disconnect()
			end
			if viewportConn then
				viewportConn:Disconnect()
			end
		end
	end, {})

	useEffect(function()
		if not isLoaded then
			if SongDatabase.IsLoaded then
				setIsLoaded(true)
				return function() end -- Empty cleanup
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
		return function() end -- Empty cleanup when already loaded
	end, {isLoaded})

	local function switchScreen(screenName)
		print("Switching to screen:", screenName)
		setCurrentScreen(screenName)
	end

	local function renderScreen()
		if not isLoaded then
			return e(LoadingScreen)
		end

		local ScreenComponent = Screens[currentScreen]

		if ScreenComponent then
			-- Pass screenName and onBack props for PlaceholderScreen compatibility
			return e(ScreenComponent, {
				screenName = currentScreen,
				onBack = function()
					switchScreen("MainMenu")
				end,
			})
		end

		-- Fallback for completely unknown screens (shouldn't happen)
		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		}, {
			Label = e("TextLabel", {
				Text = "Unknown screen: " .. currentScreen,
				TextColor3 = Color3.fromRGB(255, 100, 100),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		})
	end

	return e(ScreenContext.Provider, {
		value = {
			currentScreen = currentScreen,
			switchScreen = switchScreen
		}
	}, {
		Content = renderScreen()
	})
end

return App
