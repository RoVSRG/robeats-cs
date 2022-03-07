local Rodux = require(game.ReplicatedStorage.Packages.Rodux)
local Llama = require(game.ReplicatedStorage.Packages.Llama)

local MAX_MESSAGE_HISTORY = 100

local defaultState = {
    messages = {}
}

return Rodux.createReducer(defaultState, {
    addChatMessage = function(state, action)
        local messages = Llama.Dictionary.copy(state.messages)

        table.insert(messages, {
            channel = action.channel,
            message = action.message,
            player = action.player,
            time = action.time
        })

        local channelMessages = Llama.List.filter(messages, function(message)
            return message.channel == action.channel
        end)

        if #channelMessages > MAX_MESSAGE_HISTORY then
            local removedMessage = table.remove(channelMessages, 1)

            messages = Llama.List.removeValue(messages, removedMessage)
        end

        return Llama.Dictionary.merge(state, {
            messages = messages
        })
    end
})
