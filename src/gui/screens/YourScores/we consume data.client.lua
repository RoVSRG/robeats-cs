local ScreenChief = require(game:GetService("ReplicatedStorage").Modules.ScreenChief)
local Time = require(game:GetService("ReplicatedStorage").Libraries.Time)
local SongDatabase = require(game:GetService("ReplicatedStorage").SongDatabase)

local GetYourScores = game:GetService("ReplicatedStorage").Remotes.Functions.GetYourScores

local ScoreTemplate = ScreenChief:GetTemplates("YourScores"):FindFirstChild("Score")

if not SongDatabase.IsLoaded then
    SongDatabase.Loaded.Event:Wait()
end

local function getYourScores()
    local response = GetYourScores:InvokeServer()

    if not response.success then
        warn(response.error)
        return
    end

    local list = script.Parent.List
    for _, child in list:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    list.CanvasSize = UDim2.new(0, 0, 0, 0)

    local result = response.result
    local scores = result.scores

    for i, score in scores do
        local song = SongDatabase:GetSongByKey(score.hash)

        local scoreInstance = ScoreTemplate:Clone()
        local songInfo = scoreInstance.SongInfo

        songInfo.ScoreData.Text = string.format("Rating: %0.2f | Score: %d | Accuracy: %0.2f%% | Rate: %0.2fx", score.rating, score.score, score.accuracy, score.rate / 100)
        songInfo.Song.Text = tostring(i) .. ". " .. song.SongName .. " - " .. song.ArtistName

        scoreInstance.Parent = list

        list.CanvasSize += UDim2.new(0, 0, 0, scoreInstance.Size.Y.Offset + list.UIListLayout.Padding.Offset)
    end
end

script.Parent.BackButton.MouseButton1Click:Connect(function()
    ScreenChief:Switch("MainMenu")
end)

Time.setInterval(getYourScores, 60)
getYourScores()