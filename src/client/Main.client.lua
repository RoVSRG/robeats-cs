-- Clear all children of StarterGui so that it doesn't interfere with tagging
game:GetService("StarterGui"):ClearAllChildren()

local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)

local Transient = require(game.ReplicatedStorage.State.Transient)

EnvironmentSetup:initial_setup()

local live = ScreenChief:GetScreenGui()

local MainMenu = ScreenChief:GetScreen("Initialize")
MainMenu.Parent = live

SongDatabase:LoadAllSongs()

if not SongDatabase.IsLoaded then
    SongDatabase.Loaded.Event:Wait()
end

Transient.song.selected:set(math.random(1, #SongDatabase.songs))
