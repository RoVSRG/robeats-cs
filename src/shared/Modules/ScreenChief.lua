local TweenService = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui

-- In the new structure:
-- - StarterGui.Screens contains all the screen templates  
-- - StarterGui.Dev is for visual editing (destroyed at runtime)
-- - We create a runtime ScreenGui called "Main" to hold active screens

local screens = game.StarterGui:WaitForChild("Screens")
local main = playerGui:FindFirstChild("Main")

-- Create the main ScreenGui if it doesn't exist
if not main then
	main = Instance.new("ScreenGui")
	main.Name = "Main"
	main.DisplayOrder = 1
	main.IgnoreGuiInset = true
	main.ResetOnSpawn = false
	main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	main.Parent = playerGui
end

local ScreenChief = {}

function ScreenChief:GetCurrentScreen()
	return main:FindFirstChildWhichIsA("CanvasGroup") or main:FindFirstChildWhichIsA("Frame")
end

function ScreenChief:GetScreen(name)
	-- First check if screen is already loaded in main
	local existing = main:FindFirstChild(name)
	if existing then
		return existing
	end
	
	-- Clone from the Screens folder
	local template = screens:FindFirstChild(name)
	if not template then
		error(`"{name}" is not a valid screen. Available screens in StarterGui.Screens: {table.concat(self:GetAvailableScreens(), ", ")}`)
	end
	
	-- Clone the template
	local screen = template:Clone()
	return screen
end

function ScreenChief:GetAvailableScreens(): { string }
	local screenNames = {}
	for _, screen in screens:GetChildren() do
		table.insert(screenNames, screen.Name)
	end
	return screenNames
end

function ScreenChief:GetScreenGui()
	return main
end

function ScreenChief:Switch(target)
	local current = self:GetCurrentScreen()
	local targetScreen = self:GetScreen(target)

	-- Start with target screen offscreen to the left
	targetScreen.Position = UDim2.fromScale(-1.5, 0) -- offscreen left
	targetScreen.Parent = main

	-- Transition durations
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	-- Create transition mask to prevent user interaction during transition
	local transitionMask = Instance.new("TextButton")
	transitionMask.Text = ""
	transitionMask.Transparency = 1
	transitionMask.Size = UDim2.fromScale(1, 1)
	transitionMask.Position = UDim2.fromScale(0.5, 0.5)
	transitionMask.AnchorPoint = Vector2.new(0.5, 0.5)
	transitionMask.BackgroundTransparency = 1
	transitionMask.AutoButtonColor = false
	transitionMask.ZIndex = 9999 -- make sure it's on top
	transitionMask.Parent = main

	if current then
		-- Animate current screen off to the right
		local outTween = TweenService:Create(current, tweenInfo, {
			Position = UDim2.fromScale(2.5, 0) -- offscreen right
		})
		outTween:Play()
	end

	-- Animate target screen in from the left to center
	local inTween = TweenService:Create(targetScreen, tweenInfo, {
		Position = UDim2.fromScale(0, 0) -- center screen
	})
	inTween:Play()

	inTween.Completed:Once(function()
		-- Clean up old screen
		if current then
			current:Destroy()
		end
		
		-- Ensure target is visible and properly positioned
		targetScreen.Parent = main
		transitionMask:Destroy()
		
		print(`📱 Switched to screen: {target}`)
	end)
end

-- Initialize with a default screen if none exists
function ScreenChief:Initialize(defaultScreen: string?)
	defaultScreen = defaultScreen or "MenuScreen"
	
	local current = self:GetCurrentScreen() 
	if not current then
		print(`🚀 ScreenChief: Loading default screen "{defaultScreen}"`)
		local screen = self:GetScreen(defaultScreen)
		screen.Position = UDim2.fromScale(0, 0)
		screen.Parent = main
	end
end

return ScreenChief
