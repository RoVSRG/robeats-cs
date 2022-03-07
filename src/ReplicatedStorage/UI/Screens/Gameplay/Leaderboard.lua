local Roact = require(game.ReplicatedStorage.Packages.Roact)
local e = Roact.createElement
local f = Roact.createFragment
local Llama = require(game.ReplicatedStorage.Packages.Llama)

local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local LeaderboardSlot = require(game.ReplicatedStorage.UI.Screens.Gameplay.LeaderboardSlot)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)

local Leaderboard = Roact.Component:extend("Leaderboard")

Leaderboard.defaultProps = {
    SongKey = 1,
    LocalRating = 0,
    LocalAccuracy = 0
}

function Leaderboard:init()
    self:setState({
        scores = {}
    })

    local ScoreService = Knit.GetService("ScoreService")

    ScoreService:GetScores(SongDatabase:get_hash_for_key(self.props.SongKey), 8):andThen(function(scores)
        self:setState({
            scores = scores
        })
    end)
end

function Leaderboard:render()
    local children = {}

    local scores = Llama.Dictionary.copy(self.state.scores)

    local localSlot = string.format("LocalPlayer(%d)", game.Players.LocalPlayer.UserId)

    table.insert(scores, {
        PlayerName = game.Players.LocalPlayer.Name,
        UserId = game.Players.LocalPlayer.UserId,
        Rating = self.props.LocalRating,
        Accuracy = self.props.LocalAccuracy,
        _id = localSlot
    })

    table.sort(scores, function(a, b)
        return a.Rating > b.Rating
    end)

    for itr_score_index, itr_score in ipairs(scores) do
        local itr_score_element = e(LeaderboardSlot, {
            PlayerName = itr_score.PlayerName,
            UserId = itr_score.UserId,
            Rating = itr_score.Rating,
            Accuracy = itr_score.Accuracy,
            Place = itr_score_index,
            IsLocalProfile = itr_score._id == localSlot
        })

        children[itr_score._id] = itr_score_element
    end

    return e(RoundedFrame, {
        Position = self.props.Position,
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.fromScale(0.175, 0.5),
        BackgroundTransparency = 1
    }, children)
end

return Leaderboard