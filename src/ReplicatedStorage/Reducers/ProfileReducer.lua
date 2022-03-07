local Rodux = require(game.ReplicatedStorage.Packages.Rodux)
local Llama = require(game.ReplicatedStorage.Packages.Llama)
local createReducer = Rodux.createReducer

local join = Llama.Dictionary.join
local removeKey = Llama.Dictionary.removeKey

return createReducer({}, {
    addProfile = function(state, action)
        return join(state, {
            [tostring(action.player.UserId)] = action.profile
        })
    end,
    updateProfile = function(state, action)
        return join(state, {
            [tostring(action.player.UserId)] = action.profile
        })
    end,
    removeProfile = function(state, action)
        return removeKey(state, tostring(action.player.UserId))
    end
})
