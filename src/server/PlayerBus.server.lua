local SDK = require(game.ServerScriptService.Services.SDK)

local DataStoreService = game:GetService("DataStoreService")
local LocalizationService = game:GetService("LocalizationService")

local OptionsStore = DataStoreService:GetDataStore("OptionsStore")

local GetSettings = game.ReplicatedStorage.Remotes.Functions.GetSettings
local SaveSettings = game.ReplicatedStorage.Remotes.Events.SaveSettings
local Leaderstats = require(game.ServerScriptService.Leaderstats)

local Events = game.ServerScriptService.Events

local function fetchProfile(player)
	-- Updated to use getProfile with number
	local profile = SDK.Players.getProfile(player.UserId)
	return profile
end

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
		data = {}
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

Events.PlayerUpdated.Event:Connect(function(player, profile)
	Leaderstats.update(player, profile)
end)

game.Players.PlayerAdded:Connect(function(player)
	print("Player added:", player.Name)

	local leaderstats = Leaderstats.create(player)

	local countryCode = LocalizationService:GetCountryRegionForPlayerAsync(player) or "??"
	local rank = "#?"

	leaderstats.Rank.Value = rank
	leaderstats.Rating.Value = 0
	leaderstats.Country.Value = countryCode

	local profile = fetchProfile(player)

	if profile then
		Leaderstats.update(player, profile)
	end
end)