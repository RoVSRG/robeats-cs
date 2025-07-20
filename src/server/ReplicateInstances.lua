local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

Players.CharacterAutoLoads = false

local function createGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Main"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local scale = Instance.new("UIScale")
	scale.Parent = screenGui
	
	local styleLink = Instance.new("StyleLink")
	styleLink.StyleSheet = game:GetService("ReplicatedStorage").Design.MainStyleSheet
	styleLink.Parent = screenGui
	
	return screenGui
end

Players.PlayerAdded:Connect(function(player)
	local playerGui = player:WaitForChild("PlayerGui")
	
	local gui = createGui(playerGui)
	gui.Parent = playerGui
	
	for _, gui in ipairs(StarterGui:GetChildren()) do
		if gui.Name == "Dev" then
			for _, element in gui:GetChildren() do
				if element:IsA("Frame") then
					element:Clone().Parent = playerGui:FindFirstChild("Screens")
				end
			end
			
			continue
		end
		
		local element = gui:Clone()
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