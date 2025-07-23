local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

Players.CharacterAutoLoads = false

local function createGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Main"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local scale = Instance.new("UIScale")
	scale.Parent = screenGui
	
	return screenGui
end

Players.PlayerAdded:Connect(function(player)
	local playerGui: PlayerGui = player:WaitForChild("PlayerGui")
	
	local gui = createGui()
	gui.Parent = playerGui
	
	for _, guiObject: GuiObject in ipairs(StarterGui:GetChildren()) do
		if guiObject.Name == "Dev" then
			continue
		end
		
		local element = guiObject:Clone()
		element.Parent = playerGui
	end
	
	local screens = playerGui:FindFirstChild("Screens")
	
	for _, screen in screens:GetChildren() do
		local canvasGroup = Instance.new("Frame")
		canvasGroup.BackgroundTransparency = 1
		canvasGroup.Size = UDim2.fromScale(1, 1)
		canvasGroup.Name = screen.Name
		
		screen.Parent = canvasGroup
		canvasGroup.Parent = screens
	end
end)