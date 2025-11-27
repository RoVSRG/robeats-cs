local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local SongDatabase = require(game.ReplicatedStorage.SongDatabase)

local loadingText = script.Parent:WaitForChild("Text")

local BASE_TEXT = "Loading songs"
loadingText.Text = BASE_TEXT

local function animateLoadingText()
    local dots = 0

    while not SongDatabase.IsLoaded do
        loadingText.Text = BASE_TEXT .. string.rep(".", dots)
        wait(0.3)

        dots = (dots + 1) % 4
    end
end

animateLoadingText()

ScreenChief:Switch("MainMenu")
