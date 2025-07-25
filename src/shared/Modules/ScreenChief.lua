local TweenService = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui

local screens = playerGui:WaitForChild("Screens")
local live = playerGui:WaitForChild("Main")

local ScreenChief = {}

function ScreenChief:GetCurrentScreen()
	return live:FindFirstChildWhichIsA("Frame")
end

function ScreenChief:GetScreen(name)
	local screen = screens:FindFirstChild(name) or live:FindFirstChild(name)
	
	if not screen then
		error(`"{screen}" is not a valid screen.`)
	end
	
	return screen
end

function ScreenChief:GetTemplates(name: string)
	local screen: Frame = self:GetScreen(name):FindFirstChild(name)

	if not screen:FindFirstChild("Templates") then
		error(`"{name}" does not have a Templates folder.`)
	end

	return screen:FindFirstChild("Templates")
end


function ScreenChief:GetScreenGui()
	return live
end

function ScreenChief:Switch(target)
	local current: CanvasGroup = self:GetCurrentScreen()
	local targetScreen: CanvasGroup = self:GetScreen(target)

	current.Parent = screens -- hide old screen
	targetScreen.Parent = live -- ensure target is visible (if not already)
end


return ScreenChief
