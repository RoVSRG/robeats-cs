local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Llama = require(game.ReplicatedStorage.Packages.Llama)
local e = Roact.createElement

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)
local RoundedAutoScrollingFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedAutoScrollingFrame)
local RoundedTextLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextLabel)
local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)

local Player = require(script.Player)

local PlayerSelection = Roact.Component:extend("PlayerSelection")

PlayerSelection.defaultProps = {
    Position = UDim2.fromScale(0.4157, 0.975),
    Size = UDim2.fromScale(0.74, 0.19),
    AnchorPoint = Vector2.new(0, 1),
    Players = {},
    OnPlayerSelected = function()

    end
}

function PlayerSelection:render()
    local playersList = Llama.Dictionary.values(self.props.Players)

    table.sort(playersList, function(a, b)
        return a.score > b.score
    end)

    local players = Llama.List.map(playersList, function(player, index)
        return e(Player, {
            UserId = player.player.UserId,
            Place = index,
            Selected = self.props.SelectedPlayer == player.player.UserId,
            OnClick = self.props.OnPlayerSelected
        })
    end)

    return e(RoundedAutoScrollingFrame, {
        Position = self.props.Position,
        Size = self.props.Size,
        AnchorPoint = self.props.AnchorPoint,
        BackgroundTransparency = 1,
        UIListLayoutProps = {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 15)
        }
    }, players)
end

return PlayerSelection