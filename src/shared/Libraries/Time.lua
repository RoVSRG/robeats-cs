local RunService = game:GetService("RunService")

local function formatDuration(ms)
	local totalSeconds = math.floor(ms / 1000)
	local minutes = math.floor(totalSeconds / 60)
	local seconds = totalSeconds % 60
	return string.format("%d:%02d", minutes, seconds)
end

--[[
    @param callback function
    @param interval number (in seconds)
    @return function
]]
local function setInterval(callback, interval)
	local timeSinceLastCall = 0

	local connection = RunService.Heartbeat:Connect(function(dt)
		timeSinceLastCall += dt

		if timeSinceLastCall >= interval then
			timeSinceLastCall = 0
			callback()
		end
	end)

	return function()
		connection:Disconnect()
	end
end

return {
    formatDuration = formatDuration,
    setInterval = setInterval,
}