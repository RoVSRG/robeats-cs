local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Multiplayer = require(game.ReplicatedStorage.UI.Screens.Multiplayer)

local Rodux = require(game.ReplicatedStorage.Packages.Rodux)
local RoactRodux = require(game.ReplicatedStorage.Packages.RoactRodux)
local e = Roact.createElement

local OptionsReducer = require(game.ReplicatedStorage.Reducers.OptionsReducer)
local PermissionsReducer = require(game.ReplicatedStorage.Reducers.PermissionsReducer)
local MultiplayerReducer = require(game.ReplicatedStorage.Reducers.MultiplayerReducer)

return function(target)
    local combinedReducers = Rodux.combineReducers({
        options = OptionsReducer,
        permissions = PermissionsReducer,
        multiplayer = MultiplayerReducer
    })
        
    local store = Rodux.Store.new(combinedReducers)

    local id = "testRoom"

    local action = {
        type = "createRoom"
    }

    action.id = id

    store:dispatch(action)

    local storeProvider = Roact.createElement(RoactRodux.StoreProvider, {
        store = store
    }, {
        App = Roact.createElement(Multiplayer)
    })

    local handle = Roact.mount(storeProvider, target)

    return function()
        Roact.unmount(handle)
    end
end