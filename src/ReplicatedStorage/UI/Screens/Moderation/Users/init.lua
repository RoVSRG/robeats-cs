local Roact = require(game.ReplicatedStorage.Packages.Roact)
local e = Roact.createElement
local f = Roact.createFragment

local RoundedAutoScrollingFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedAutoScrollingFrame)

local UserButton = require(script.UserButton)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)
local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)

local Users = Roact.Component:extend("Users")

function Users:init()
    
end

function Users:render()
    local buttons = {}

    for _, player in ipairs(game.Players:GetPlayers()) do
        buttons[player.UserId] = e(UserButton, {
            UserId = player.UserId,
            PlayerName = player.Name,
            OnKick = function(userId, playerName)
                self.props.history:push("/moderation/kick", {
                    userId = userId,
                    playerName = playerName
                })
            end,
            OnBan = function(userId, playerName)
                self.props.history:push("/moderation/ban", {
                    userId = userId,
                    playerName = playerName
                })
            end
        })
    end

    return e(RoundedFrame, {

    }, {
        ButtonContainer = e(RoundedAutoScrollingFrame, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(0.7, 0.8),
            BackgroundColor3 = Color3.fromRGB(24, 24, 24)
        }, {
            UIListLayout = e("UIListLayout", {
                Padding = UDim.new(0, 2)
            }),
            Buttons = f(buttons)
        }),
        BackButton = e(RoundedTextButton, {
            Size = UDim2.fromScale(0.05, 0.05),
            HoldSize = UDim2.fromScale(0.06, 0.06),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.04, 0.95),
            BackgroundColor3 = Color3.fromRGB(212, 23, 23),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "Back",
            TextSize = 12,
            OnClick = function()
                self.props.history:goBack()
            end
        })
    })
end

return Users