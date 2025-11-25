local RunService = game:GetService("RunService")

local SDK = require(game.ServerScriptService.Services.SDK)

local function pingServer()
	local success = pcall(function()
		SDK.Root.get()
	end)
	return success
end

local serverWorking = nil
local lastPingTime = tick()

local PING_INTERVAL = 15 -- Check server status every 15 seconds

local queue = {}
local processing = false

local function addToQueue(func, ...)
	local args = table.pack(...)
	local callback = nil

	-- Check if last argument is a callback function
	if args.n > 0 and type(args[args.n]) == "function" then
		callback = args[args.n]
		args.n = args.n - 1 -- Remove callback from args
	end

	print("Adding to queue:")

	table.insert(queue, {
		func = func,
		args = args,
		callback = callback,
	})
end

local processingWorking = false

RunService.Heartbeat:Connect(function()
	if processingWorking then
		return
	end

	processingWorking = true

	local currentTime = tick()

	local interval = serverWorking and PING_INTERVAL or 5 -- Use shorter interval if server is down

	if (currentTime - lastPingTime >= interval) or (serverWorking == nil) then
		lastPingTime = currentTime

		local wasWorking = serverWorking
		serverWorking = pingServer()

		if not serverWorking and wasWorking then
			warn("Server is not reachable. Please check your connection or server status.")
		end

		if serverWorking and not wasWorking then
			print("API is back online! Processing", #queue, "queued items...")
		end
	end

	processingWorking = false
end)

RunService.Heartbeat:Connect(function()
	-- Only process if we have items in queue and not already processing
	if #queue == 0 or processing then
		return
	end

	-- Only process if server is working
	if not serverWorking then
		return
	end

	processing = true

	-- Process all queued items
	local currentQueue = queue
	queue = {} -- Clear the queue for new items

	for i, queueItem in ipairs(currentQueue) do
		if not serverWorking then
			break
		end

		local success, result = pcall(function()
			return queueItem.func(table.unpack(queueItem.args))
		end)

		if success and queueItem.callback then
			-- Call the callback with the result
			local callbackSuccess, _ = pcall(function()
				queueItem.callback(result)
			end)

			if not callbackSuccess then
				warn("Queue callback failed for queued request")
			end
		elseif not success then
			serverWorking = pingServer() -- Re-check server status after failure
		end
	end

	processing = false
end)

local function refreshServerStatus()
	lastPingTime = 0 -- Force immediate ping on next addToQueue call
end

local function getQueueStatus()
	return {
		serverWorking = serverWorking,
		queueLength = #queue,
		processing = processing,
		lastPingTime = lastPingTime,
	}
end

return {
	pingServer = pingServer,
	addToQueue = addToQueue,
	refreshServerStatus = refreshServerStatus,
	getQueueStatus = getQueueStatus,
}
