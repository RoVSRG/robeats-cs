local Roact = require(game.ReplicatedStorage.Packages.Roact)
local e = Roact.createElement

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)
local RoundedTextLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextLabel)
local AnimatedNumberLabel = require(game.ReplicatedStorage.UI.Components.Base.AnimatedNumberLabel)

local SpreadDisplay = require(game.ReplicatedStorage.UI.Screens.Results.SpreadDisplay)

local StatCard = Roact.Component:extend("StatCard")

StatCard.defaultProps = {
    Position = UDim2.fromScale(0.7, 0.2)
}

function StatCard:render()
    local MA = if (self.props.Perfects) == 0 then 0 else self.props.Marvelouses / self.props.Perfects

    return e(RoundedFrame, {
        Position = self.props.Position,
        Size = UDim2.fromScale(0.12, 0.3),
        BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    }, {
        AccuracyText = e(RoundedTextLabel, {
            Position = UDim2.fromScale(0.03, 0.03),
            Size = UDim2.fromScale(1, 0.12),
            TextColor3 = Color3.fromRGB(75, 75, 75),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Text = "Acc %",
            TextScaled = true
        }, {
            UITextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 25
            })
        }),
        Accuracy = e(AnimatedNumberLabel, {
            Position = UDim2.fromScale(0.97, 0.03),
            Size = UDim2.fromScale(1, 0.12),
            TextColor3 = Color3.fromRGB(228, 228, 228),
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Value = self.props.Accuracy,
            TextXAlignment = Enum.TextXAlignment.Right,
            FormatValue = function(a)
                return string.format("%0.2f%%", a)
            end,
            TextScaled = true
        }, {
            UITextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 25
            })
        }),
        SpreadDisplay = e(SpreadDisplay, {
            Position = UDim2.fromScale(0.5, 0.99),
            Size = UDim2.fromScale(0.97, 0.7),
            AnchorPoint = Vector2.new(0.5, 1),
            Marvelouses = self.props.Marvelouses,
            Perfects = self.props.Perfects,
            Greats = self.props.Greats,
            Goods = self.props.Goods,
            Bads = self.props.Bads,
            Misses = self.props.Misses
        }),
        MAText = e(RoundedTextLabel, {
            Position = UDim2.fromScale(0.03, 0.16),
            Size = UDim2.fromScale(1, 0.12),
            TextColor3 = Color3.fromRGB(75, 75, 75),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Text = "MA",
            TextScaled = true
        }, {
            UITextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 25
            })
        }),
        MA = e(AnimatedNumberLabel, {
            Position = UDim2.fromScale(0.97, 0.16),
            Size = UDim2.fromScale(1, 0.12),
            TextColor3 = Color3.fromRGB(228, 228, 228),
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Value = MA,
            TextXAlignment = Enum.TextXAlignment.Right,
            FormatValue = function(a)
                return string.format("%0.1f", a)
            end,
            TextScaled = true
        }, {
            UITextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 25
            })
        }),
    })
end

return StatCard
