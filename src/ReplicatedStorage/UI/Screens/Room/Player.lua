local Players = game:GetService("Players")
local Roact = require(game.ReplicatedStorage.Packages.Roact)
local RoactRodux = require(game.ReplicatedStorage.Packages.RoactRodux)
local e = Roact.createElement

local withInjection = require(game.ReplicatedStorage.UI.Components.HOCs.withInjection)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)
local RoundedAutoScrollingFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedAutoScrollingFrame)
local RoundedTextLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextLabel)
local RoundedImageLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedImageLabel)
local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)

local Tier = require(game.ReplicatedStorage.UI.Components.Tier)

local Tiers = require(game.ReplicatedStorage.Tiers)

local Player = Roact.Component:extend("Player")

Player.defaultProps = {
    Name = "Player",
    UserId = 0,
    OnHostTransfer = function()
        
    end
}

function Player:init()
    if not self.props.Profile then
        return
    end

    local tier = Tiers:GetTierFromRating(self.props.Profile.Rating)

    self:setState({
        tier = tier.name,
        division = tier.division,
        subdivision = tier.subdivision
    })
end

function Player:render()
    return e(RoundedFrame, {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = Color3.fromRGB(19, 19, 19)
    }, {
        UserThumbnail = e(RoundedImageLabel, {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(13, 13, 13),
            Position = UDim2.fromScale(0.0135, 0.5),
            Size = UDim2.new(0.07, 0, 0.75, 0),
            Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userid=%d&width=420&height=420&format=png", self.props.UserId)
        }, {
            Tier = e(Tier, {
                imageLabelProps = {
                    Size = UDim2.fromScale(0.5, 0.5),
                    Position = UDim2.fromScale(1.53, 0.04),
                    AnchorPoint = Vector2.new(0.5, 0),
                    BackgroundColor3 = Color3.fromRGB(13, 13, 13),
                },
                tier = self.state.tier,
                division = self.state.division
            }),
            Name = e(RoundedTextLabel, {
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(255, 208, 87),
                TextScaled = true,
                Position = UDim2.fromScale(1.9, 0.04),
                Size = UDim2.fromScale(5, 0.55),
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = (if self.props.IsHost then "👑 " else "") .. self.props.Name
            }, {
                UITextSizeConstraint = e("UITextSizeConstraint", {
                    MaxTextSize = 60
                })
            }),
            Info = e(RoundedTextLabel, {
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(228, 228, 228),
                TextScaled = true,
                Position = UDim2.fromScale(1.3, 0.5),
                Size = UDim2.fromScale(5, 0.55),
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = if self.props.Profile then string.format("#%d | %0.2f [%s]", self.props.Profile.Rank, self.props.Profile.Rating, if self.state.tier then self.state.tier .. (if self.state.division then " " .. string.rep("I", self.state.division) .. " Division " .. if self.state.division == 4 then "IV" else string.rep("I", self.state.subdivision) else "") else "...") else "???"
            }, {
                UITextSizeConstraint = e("UITextSizeConstraint", {
                    MaxTextSize = 15
                })
            }),
            UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
                AspectRatio = 1
            })
        }),
        TransferHost = if (not self.props.IsHost and self.props.IsLocalPlayerHost) then e(RoundedTextButton, {
            Position = UDim2.fromScale(0.975, 0.5),
            Size = UDim2.fromScale(0.18, 0.6),
            AnchorPoint = Vector2.new(1, 0.5),
            Text = "Transfer Host",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            HoldSize = UDim2.fromScale(0.18, 0.6),
            HighlightBackgroundColor3 = Color3.fromRGB(24, 24, 24),
            OnClick = function()
                self.props.OnHostTransfer(self.props.UserId)
            end
        }, {
            UITextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 15
            })
        }) else nil,
    })
end

return RoactRodux.connect(function(state, props)
    return {
        Profile = state.profiles[tostring(props.UserId)]
    }
end)(Player)