local RunService = game:GetService("RunService")

local Http = require(game.ServerScriptService.Utils.Http)

local function pingServer()
    local success, result = pcall(function()
        return Http.get("/")
    end)

    if not success then
        return false
    end

    if not result.success then
        return false
    end

    return true
end

local serverWorking = nil
local lastPingTime = tick()

local PING_INTERVAL = 15 -- Check server status every 15 seconds

local queue = {}
local processing = false

local function addToQueue(func, ...)
    print("Adding to queue:")

    table.insert(queue, {
        func = func,
        args = table.pack(...)
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

        local success, _ = pcall(function()
            queueItem.func(table.unpack(queueItem.args))
        end)
        
        if not success then
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
        lastPingTime = lastPingTime
    }
end

return {
    pingServer = pingServer,
    addToQueue = addToQueue,
    refreshServerStatus = refreshServerStatus,
    getQueueStatus = getQueueStatus
}