--local player = game.Players.LocalPlayer
--local playerGui = player:WaitForChild("PlayerGui")
-- Test comment for file watcher

local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)

-- Initialize ScreenChief with default screen
ScreenChief:Initialize("MenuScreen")

-- Load songs
SongDatabase:LoadAllSongs()

print("🎮 Robeats client initialized!")
print("📱 Available screens:", table.concat(ScreenChief:GetAvailableScreens(), ", "))
