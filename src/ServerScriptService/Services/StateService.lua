local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local Rodux = require(game.ReplicatedStorage.Packages.Rodux)

local MultiplayerReducer = require(game.ReplicatedStorage.Reducers.MultiplayerReducer)
local ProfileReducer = require(game.ReplicatedStorage.Reducers.ProfileReducer)

local StateService = Knit.CreateService {
    Name = "StateService";
    Client = {};
}

local function replicationMiddleware(nextDispatch)
    return function(action)
        StateService.Client.ActionDispatched:FireAll(action)
        return nextDispatch(action)
    end
end

function StateService:KnitInit()
    local combinedReducers = Rodux.combineReducers({
        multiplayer = MultiplayerReducer,
        profiles = ProfileReducer
    })

    self.Store = Rodux.Store.new(combinedReducers, nil, { replicationMiddleware })
end

function StateService.Client:GetState()
    return StateService.Store:getState()
end

StateService.Client.ActionDispatched = Knit.CreateSignal()

return StateService