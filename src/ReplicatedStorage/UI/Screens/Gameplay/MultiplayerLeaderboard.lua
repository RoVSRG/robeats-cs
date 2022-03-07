local Roact = require(game.ReplicatedStorage.Packages.Roact)
local e = Roact.createElement
local f = Roact.createFragment
local Llama = require(game.ReplicatedStorage.Packages.Llama)

local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local LeaderboardSlot = require(game.ReplicatedStorage.UI.Screens.Gameplay.LeaderboardSlot)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)

local MultiplayerLeaderboard = Roact.Component:extend("MultiplayerLeaderboard")

MultiplayerLeaderboard.defaultProps = {
    SongKey = 1,
    LocalRating = 0,
    LocalAccuracy = 0,
    Scores = {}
}

function MultiplayerLeaderboard:render()
    local scores = Llama.Dictionary.values(self.props.Scores)

    table.sort(scores, function(a, b)
        return a.score > b.score
    end)

    local children = {}

    for itr_score_index, itr_score in ipairs(scores) do
        local player = itr_score.player

        if player then
            children[tostring(player.UserId)] = e(LeaderboardSlot, {
                PlayerName = player.Name,
                UserId = player.UserId,
                Score = itr_score.score,
                Accuracy = itr_score.accuracy,
                Place = itr_score_index,
                IsLocalProfile = player.UserId == game.Players.LocalPlayer.UserId
            })
        end
    end

    return e(RoundedFrame, {
        Position = self.props.Position,
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.fromScale(0.175, 0.5),
        BackgroundTransparency = 1
    }, children)
end

return MultiplayerLeaderboard