local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local GuiMain = Player:WaitForChild("PlayerGui"):WaitForChild("Main")
local ViewportSize = Camera.ViewportSize

local MAIN_RESOLUTION = Vector2.new(1280, 720)
local MAX_SCALE = 1.5
local MAX_WAIT_TIME = 0.2

local function refreshScaling()
	local scale = math.min(ViewportSize.X/MAIN_RESOLUTION.X, ViewportSize.Y/MAIN_RESOLUTION.Y)
	GuiMain.UIScale.Scale = math.min(scale,MAX_SCALE)
end

local function resolutionChanged()
	if Camera.ViewportSize.X ~= ViewportSize.X or Camera.ViewportSize.Y ~= ViewportSize.Y then
		local tempSize = Camera.ViewportSize
		local waitTime = MAX_WAIT_TIME
		
		repeat 
			if Camera.ViewportSize.X == tempSize.X and Camera.ViewportSize.Y == tempSize.Y then
				waitTime = waitTime - task.wait() 
			else return
			end
		until waitTime <= 0
		
		ViewportSize = Camera.ViewportSize
		refreshScaling()
	end
end

Camera.Changed:Connect(resolutionChanged)
refreshScaling()