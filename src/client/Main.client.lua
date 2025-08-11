-- Clear all children of StarterGui so that it doesn't interfere with tagging
game:GetService("StarterGui"):ClearAllChildren()

local ContentProvider = game:GetService("ContentProvider")

local Options = require(game.ReplicatedStorage.State.Options)
-- local SettingsSerializer = require(game.ReplicatedStorage.Serialization.SettingsSer)

local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

-- local GetSettings = game.ReplicatedStorage.Remotes.Functions.GetSettings


local Transient = require(game.ReplicatedStorage.State.Transient)

-- local function handlePlayerSettings()
--     local playerSettings = GetSettings:InvokeServer()
--     SettingsSerializer.applyOptionsFromSerialized(playerSettings)
-- end

-- INITIALIZE GAME

EnvironmentSetup:initial_setup()

local live = ScreenChief:GetScreenGui()

local MainMenu = ScreenChief:GetScreen("Initialize")
MainMenu.Parent = live

for _, skin in require(game.ReplicatedStorage.Skins):key_itr() do
    task.spawn(function()
        ContentProvider:PreloadAsync({ skin })
    end)
end

SongDatabase:LoadAllSongs()

if not SongDatabase.IsLoaded then
    SongDatabase.Loaded.Event:Wait()
end

Transient.song.selected:set(math.random(1, #SongDatabase.songs))


-- for i, v in pairs(Options) do
--     print(`Option {i}: | Value: {v:get()}`)
-- end
-- Load player settings
--handlePlayerSettings()