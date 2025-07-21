--local player = game.Players.LocalPlayer
--local playerGui = player:WaitForChild("PlayerGui")

local ScreenChief = require("@shared/Modules/ScreenChief")
local SongDatabase = require("@shared/SongDatabase")

local live = ScreenChief:GetScreenGui()

local MainMenu = ScreenChief:GetScreen("MainMenu")

MainMenu.Parent = live

SongDatabase:LoadAllSongs()
