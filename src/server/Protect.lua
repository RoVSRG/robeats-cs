local Protect = {}

function Protect.wrap(func: (...any) -> any, cooldown: number?)
    local lastCallTime = 0
    cooldown = cooldown or 1

    return function(...)
        local currentTime = tick()

        if currentTime - lastCallTime < cooldown then
            warn("Function call is being rate-limited")
            return nil
        end

        lastCallTime = currentTime

        return func(...)
    end
end

return Protect