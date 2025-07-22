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

function ScreenChief:GetScreenGui()
	return live
end

function ScreenChief:Switch(target)
	local TweenService = game:GetService("TweenService")

	local current: CanvasGroup = self:GetCurrentScreen()
	local targetScreen: CanvasGroup = self:GetScreen(target)

	-- Start with target screen offscreen to the left
	targetScreen.Position = UDim2.fromScale(-1.5, 0) -- offscreen left
	targetScreen.Parent = live

	-- Transition durations
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	-- Animate current screen off to the right
	local outTween = TweenService:Create(current, tweenInfo, {
		Position = UDim2.fromScale(2.5, 0) -- offscreen right
	})

	-- Animate target screen in from the left to center
	local inTween = TweenService:Create(targetScreen, tweenInfo, {
		Position = UDim2.fromScale(0, 0) -- center screen
	})

	-- Optional mask to prevent user interaction during transition
	local transitionMask = Instance.new("TextButton")
	transitionMask.Text = ""
	transitionMask.Transparency = 1
	transitionMask.Size = UDim2.fromScale(1,1)
	transitionMask.Position = UDim2.fromScale(0.5, 0.5)
	transitionMask.AnchorPoint = Vector2.new(0.5, 0.5)
	transitionMask.BackgroundTransparency = 1
	transitionMask.AutoButtonColor = false
	transitionMask.ZIndex = 9999 -- make sure it's on top (another 9 for good measure)
	transitionMask.Parent = live

	outTween:Play()
	inTween:Play()

	inTween.Completed:Once(function()
		current.Parent = screens -- hide old screen
		targetScreen.Parent = live -- ensure target is visible (if not already)
		transitionMask:Destroy()
	end)
end


return ScreenChief
