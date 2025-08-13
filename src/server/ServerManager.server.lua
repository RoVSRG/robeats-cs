local DataStoreService = game:GetService("DataStoreService")
local LocalizationService = game:GetService("LocalizationService")

local OptionsStore = DataStoreService:GetDataStore("OptionsStore")

local GetSettings = game.ReplicatedStorage.Remotes.Functions.GetSettings
local SaveSettings = game.ReplicatedStorage.Remotes.Events.SaveSettings
local createLeaderstat = require(game.ServerScriptService.Playerboard)

GetSettings.OnServerInvoke = function(player)
    local success, data = pcall(function()
        print("[Options.lua] Attempting to retrieve settings for player:", player.Name)
        return OptionsStore:GetAsync("OPTIONS_" .. player.UserId)
    end)

    if not success then
        warn("Failed to retrieve settings for player:", player.Name, "Error:", data)
        return nil
    end

    if data == nil then
        data = { }
    end

    return data
end

SaveSettings.OnServerEvent:Connect(function(player, settings)
    local success, errorMessage = pcall(function()
        OptionsStore:SetAsync("OPTIONS_" .. player.UserId, settings)
        print("[Options.lua] Successfully saved options for player:", player.Name)
    end)

    if not success then
        warn("Failed to save settings for player:", player.Name, "Error:", errorMessage)
    end
end)

game.Players.PlayerAdded:Connect(function(player)
    local leaderstats = createLeaderstat(player)

    local countryCode = LocalizationService:GetCountryRegionForPlayerAsync(player) or "??"
    local rank = "#?"

    leaderstats.Rank.Value = rank
    leaderstats.Rating.Value = 0
    leaderstats.Country.Value = countryCode
end)
