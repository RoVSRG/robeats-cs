local Roact = require(game.ReplicatedStorage.Packages.Roact)
local RoactRouter = require(game.ReplicatedStorage.Packages.RoactRouter)
local Room = require(game.ReplicatedStorage.UI.Screens.Room)

local Rodux = require(game.ReplicatedStorage.Packages.Rodux)
local RoactRodux = require(game.ReplicatedStorage.Packages.RoactRodux)
local e = Roact.createElement

local HttpService = game:GetService("HttpService")

local MultiplayerReducer = require(game.ReplicatedStorage.Reducers.MultiplayerReducer)

return function(target)
    local combinedReducers = Rodux.combineReducers({
        multiplayer = MultiplayerReducer
    })
        
    local store = Rodux.Store.new(combinedReducers)
    local id = HttpService:GenerateGUID(false)
    store:dispatch({ type = "createRoom", id = id })

    local player = {
        Name = "lol",
        UserId = 0
    }

    store:dispatch({ type = "addPlayer", roomId = id, player = player })

    local history = RoactRouter.History.new()
    history:push("/room", {
        roomId = id
    })

    local router = Roact.createElement(RoactRouter.Router, {
        history = history
    }, {
        Room = Roact.createElement(RoactRouter.Route, {
            path = "/room",
            exact = true,
            component = Room
        })
    })

    local storeProvider = Roact.createElement(RoactRodux.StoreProvider, {
        store = store
    }, {
        App = router
    })

    local handle = Roact.mount(storeProvider, target)

    return function()
        Roact.unmount(handle)
    end
end