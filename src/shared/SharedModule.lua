-- Shared utilities and modules for robeats-cs-scripts
-- This can be accessed by both client and server

local SharedModule = {}

function SharedModule.sayHello()
    return "Hello from shared module!"
end

return SharedModule
