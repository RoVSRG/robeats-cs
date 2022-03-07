local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)

local RateLimitService = Knit.CreateService {
    Name = "RateLimitService";
    Client = {};
}

RateLimitService.Requests = {}

function RateLimitService:CanProcessRequestWithRateLimit(player, eventName, requestsPerSecond)
    local userRequests = SPUtil:filter(self.Requests, function(request)
        return (request.player == player) and (request.eventName == eventName)
    end)

    local keysToRemove = {}

    for i, v in ipairs(userRequests) do
        if workspace.DistributedGameTime - v.time >= 1 then
            table.insert(keysToRemove, {
                globalId = v._id,
                localId = i
            })
        end
    end

    for _, v in ipairs(keysToRemove) do
        table.remove(self.Requests, v.globalId)
        table.remove(userRequests, v.localId)
    end

    if #userRequests > requestsPerSecond then
        return false
    end

    table.insert(self.Requests, {
        player = player,
        eventName = eventName,
        time = workspace.DistributedGameTime
    })

    return true
end

return RateLimitService
