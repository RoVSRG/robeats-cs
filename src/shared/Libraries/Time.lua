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
    local startTime = os.time()
    local currentTime = startTime
    local elapsedTime = 0

	local stop = false
    
	task.spawn(function()
		while RunService.Heartbeat:Wait() and not stop do
			currentTime = os.time()
			elapsedTime = currentTime - startTime

			if elapsedTime >= interval then
				callback()
			end
		end
	end)

	return function()
		stop = true
	end
end

return {
    formatDuration = formatDuration,
    setInterval = setInterval,
}