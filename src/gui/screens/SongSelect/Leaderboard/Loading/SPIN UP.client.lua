local RunService = game:GetService("RunService")

local RPM = 60

local rotation = 0

RunService.Heartbeat:Connect(function(dt)
	rotation += (RPM / 60) * dt % 360

    script.Parent.Rotation = rotation
end)

script.Parent.Visible = false