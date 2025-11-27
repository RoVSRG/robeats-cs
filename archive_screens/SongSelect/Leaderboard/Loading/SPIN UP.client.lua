local RunService = game:GetService("RunService")

local RPM = 400

local rotation = 0

RunService.Heartbeat:Connect(function(dt)
	rotation += (RPM * dt) % 360

    script.Parent.Rotation = rotation
end)

script.Parent.Visible = false