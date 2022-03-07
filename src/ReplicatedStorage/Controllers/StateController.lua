local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local StateController = Knit.CreateController { Name = "StateController" }

local Rodux = require(game.ReplicatedStorage.Packages.Rodux)

local OptionsReducer = require(game.ReplicatedStorage.Reducers.OptionsReducer)
local PermissionsReducer = require(game.ReplicatedStorage.Reducers.PermissionsReducer)
local MultiplayerReducer = require(game.ReplicatedStorage.Reducers.MultiplayerReducer)
local ProfileReducer = require(game.ReplicatedStorage.Reducers.ProfileReducer)
local ChatReducer = require(game.ReplicatedStorage.Reducers.ChatReducer)

local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)

local Actions = require(game.ReplicatedStorage.Actions)

local PermissionsService
local StateService

function StateController:KnitInit()
    PermissionsService = Knit.GetService("PermissionsService")
    StateService = Knit.GetService("StateService")

    local combinedReducers = Rodux.combineReducers({
        options = OptionsReducer,
        permissions = PermissionsReducer,
        multiplayer = MultiplayerReducer,
        profiles = ProfileReducer,
        chat = ChatReducer
    })

    local _, initialState = StateService:GetState():await()

    self.Store = Rodux.Store.new(combinedReducers, initialState)

    self.Store:dispatch(Actions.setTransientOption("SongKey", math.random(1, SongDatabase:get_key_count())))
end

function StateController:KnitStart()
    StateService.ActionDispatched:Connect(function(action)
        self.Store:dispatch(action)

        -- print(action, self.Store:getState().profiles)
    end)

    local _, hasAdmin = PermissionsService:HasModPermissions():await()

    self.Store:dispatch(Actions.setAdmin(hasAdmin))
end

return StateController
