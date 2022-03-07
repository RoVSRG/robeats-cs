local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local Actions = require(game.ReplicatedStorage.Actions)

local SettingsController = Knit.CreateController { Name = "SettingsController" }

function SettingsController:KnitStart()
    local store = Knit.GetController("StateController").Store
    local SettingsService = Knit.GetService("SettingsService")

    local _, settings = SettingsService:GetSettings():await()

    if settings then
        for i, v in pairs(settings) do
            store:dispatch(Actions.setPersistentOption(i, v))
        end 
    end
end

return SettingsController