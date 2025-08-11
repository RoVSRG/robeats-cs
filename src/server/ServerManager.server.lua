local DataStoreService = game:GetService("DataStoreService")
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
    -- Create the leaderboard for the player
    local leaderstats = createLeaderstat(player)

    -- Set up the player's country code and rank (these would typically be set elsewhere)
    local countryCode = "US" -- Example country code, replace with actual logic
    local rank = 1 -- Example rank, replace with actual logic

    leaderstats.Country.Value = countryCode
    leaderstats.Rank.Value = rank

    print("[ServerManager.lua] Leaderboard created for player:", player.Name)
end)
