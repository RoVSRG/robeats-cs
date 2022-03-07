local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Rodux = require(game.ReplicatedStorage.Packages.Rodux)
local RoactRodux = require(game.ReplicatedStorage.Packages.RoactRodux)
local e = Roact.createElement

local OptionsReducer = require(game.ReplicatedStorage.Reducers.OptionsReducer)
local PermissionsReducer = require(game.ReplicatedStorage.Reducers.PermissionsReducer)
local MultiplayerReducer = require(game.ReplicatedStorage.Reducers.MultiplayerReducer)

local Promise = require(game.ReplicatedStorage.Packages.Promise)

local Actions = require(game.ReplicatedStorage.Actions)

local DIContext = require(game.ReplicatedStorage.Contexts.DIContext)

local Fitumi = require(game.ReplicatedStorage.Packages.Fitumi)
local a = Fitumi.a

local MainMenu = require(script.Parent.MainMenu)

return function(target)
    local combinedReducers = Rodux.combineReducers({
        options = OptionsReducer,
        permissions = PermissionsReducer,
        multiplayer = MultiplayerReducer
    })
        
    local store = Rodux.Store.new(combinedReducers)

    store:dispatch(Actions.setAdmin(true))

    local storeProvider = Roact.createElement(RoactRodux.StoreProvider, {
        store = store
    }, {
        App = Roact.createElement(MainMenu)
    })

    local fakePreviewController = a.fake()
    local fakeScoreService = a.fake()

    a.callTo(fakePreviewController.GetSoundInstance, fakePreviewController)
        :returns(Instance.new("Sound"))

    a.callTo(fakeScoreService.GetProfilePromise, fakeScoreService)
        :returns(Promise.Resolve({Rank = 13}))

    local app = Roact.createElement(DIContext.Provider, {
        value = {
            PreviewController = fakePreviewController,
            ScoreService = fakeScoreService
        }
    }, {
        StoreProvider = storeProvider
    })

    local handle = Roact.mount(app, target)

    return function ()
        Roact.unmount(handle)
    end
end