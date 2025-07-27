--local player = game.Players.LocalPlayer
--local playerGui = player:WaitForChild("PlayerGui")
-- Test comment for file watcher

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
