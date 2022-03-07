local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local Chat

local AssertType

local ChatService = Knit.CreateService {
    Name = "ChatService";
    Client = {};
}

local RateLimitService
local StateService

function ChatService:KnitInit()
    Chat = game:GetService("Chat")

    AssertType = require(game.ReplicatedStorage.Shared.AssertType)

    RateLimitService = Knit.GetService("RateLimitService")
    StateService = Knit.GetService("StateService")
end

function ChatService.Client:Chat(player, channel, message)
    if not RateLimitService:CanProcessRequestWithRateLimit(player, "Chat", 3) then
        return
    end

    AssertType:is_string(message)

    message = Chat:FilterStringForBroadcast(message, player)

    StateService.Store:dispatch({
        type = "addChatMessage",
        channel = channel,
        message = message,
        player = player,
        time = os.time()
    })
end

return ChatService