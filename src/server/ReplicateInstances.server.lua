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
	
	for _, guiObject: GuiObject in ipairs(StarterGui:GetChildren()) do
		if guiObject.Name == "Dev" then
			continue
		end
		
		local element = guiObject:Clone()
		element.Parent = playerGui
	end
	
	local screens = playerGui:FindFirstChild("Screens")
	
	for _, screen in screens:GetChildren() do
		local wrapperFrame = Instance.new("Frame")
		wrapperFrame.BackgroundTransparency = 1
		wrapperFrame.Size = UDim2.fromScale(1, 1)
		wrapperFrame.Name = screen.Name
		
		screen.Parent = wrapperFrame
		wrapperFrame.Parent = screens
	end
	
	gui.Parent = playerGui
end)