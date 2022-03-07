local Roact = require(game.ReplicatedStorage.Packages.Roact)
local e = Roact.createElement

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)
local RoundedAutoScrollingFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedAutoScrollingFrame)
local RoundedImageButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedImageButton)
local RoundedTextLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextLabel)
local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)

local Player = Roact.Component:extend("Player")

Player.defaultProps = {
    OnClick = function()

    end,
    UserId = 0,
    Place = 1
}

function Player:render()
    return e(RoundedImageButton, {
        Size = UDim2.fromOffset(100, 100),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.props.Selected and Color3.fromRGB(82, 131, 143) or nil,
        Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userid=%d&width=420&height=420&format=png", self.props.UserId),
        LayoutOrder = self.props.Place,
        OnClick = function()
            self.props.OnClick(self.props.UserId)
        end
    }, {
        UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
            AspectRatio = 1
        }),
        Rank = e(RoundedTextLabel, {
            Position = UDim2.fromScale(0.065, 0.075),
            Size = UDim2.fromScale(0.8, 0.1),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Text = string.format("#%d", self.props.Place)
        })
    })
end

return Player