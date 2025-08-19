local Protect = {}

function Protect.wrap(func: (...any) -> any, cooldown: number?)
    local callHistoryPerPlayer = {}
    cooldown = cooldown or 0.5

    return function(player, ...)
        local currentTime = tick()
        callHistoryPerPlayer[player.UserId] = callHistoryPerPlayer[player.UserId] or 0

        local lastCallTime = callHistoryPerPlayer[player.UserId]
        if currentTime - lastCallTime < cooldown then
            warn("Function call is being rate-limited")
            return nil
        end

        callHistoryPerPlayer[player.UserId] = currentTime

        return func(player, ...)
    end
end

return Protect