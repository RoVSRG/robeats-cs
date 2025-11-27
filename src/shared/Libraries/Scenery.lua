--[[

Scenery: Utility for 3D environment setup & camera manipulation

>> CREDITS <<
Creator: SectorJack

IMPORTANT NOTE: A SCENE MUST ALWAYS HAVE
- (Folder) Lighting, even if there's no effects inside
- (Part) CameraPart OR (Folder) AutoCamera

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

--// Modules
local Modules = ReplicatedStorage.Modules

local Flow = require(Modules.Libraries.Flow)

--// Variables
local Camera = workspace.CurrentCamera
local Scenes = ReplicatedStorage.Scenes

--// System
local Scenery = {}
Scenery.Scene = nil
Scenery.Flow = nil

function Scenery:Setup(sceneName)
	
	local scene = Scenes:FindFirstChild(sceneName)
	if not scene then
		warn(`[Scenery]: Scene "{sceneName}" was not found!`)
		return
	end
	
	if Scenery.Scene then
		Scenery:Takedown()
	end
	Scenery.Scene = scene
	Scenery.Scene.Parent = workspace
	
	for i, effect in pairs(Scenery.Scene.Lighting:GetChildren()) do
		effect:Clone().Parent = Lighting
	end
	
	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.FieldOfView = Scenery.Scene:GetAttribute("FOV") or 70
	
	local autoCamera = scene:FindFirstChild("AutoCamera") --Dynamic Camera
	if autoCamera then
		
		local flow = {}
		local i = 1
		local pan = autoCamera:FindFirstChild(tostring(i))
		while pan do
			
			local panTime = pan:GetAttribute("Time")
			local panOffset = pan:GetAttribute("Offset")
			local pointA = pan.A
			local pointB = pan.B
			
			table.insert(flow, function()
				Camera.CFrame = pointA.Value * panOffset
			end)
			table.insert(flow, TweenService:Create(
				Camera,
				TweenInfo.new(panTime, Enum.EasingStyle.Linear),
				{CFrame = pointB.Value * panOffset}
			))
			
			i += 1
			pan = autoCamera:FindFirstChild(tostring(i))
		end
		Scenery.Flow = Flow.new(flow)
		Scenery.Flow:Play()
	
		return scene
	end
	
	local cameraPart = scene:FindFirstChild("CameraPart") --Static Camera
	if cameraPart then
		Camera.CameraSubject = cameraPart
		Camera.CFrame = cameraPart.CFrame
		return scene
	end
	
	warn(`[Scenery]: AutoCamera and CameraPart missing in Scene "{sceneName}"!`)
end

function Scenery:Takedown()
	
	if not Scenery.Scene then
		warn(`[Scenery]: No scene is active!`)
		return
	end
	
	if Scenery.Flow then
		Scenery.Flow:Stop()
		Scenery.Flow = nil
	end
	
	for i, effect in pairs(Lighting:GetChildren()) do
		if effect:IsA("Sky") then continue end
		effect:Destroy()
	end

	Scenery.Scene.Parent = Scenes
	Scenery.Scene = nil
	
	Camera.CameraSubject = nil
end

return Scenery
