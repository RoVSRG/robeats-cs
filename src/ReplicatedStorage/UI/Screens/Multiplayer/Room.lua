local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Llama = require(game.ReplicatedStorage.Packages.Llama)
local e = Roact.createElement

local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)
local RoundedAutoScrollingFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedAutoScrollingFrame)
local RoundedTextLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextLabel)
local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)

local Room = Roact.Component:extend("Room")

Room.defaultProps = {
    Name = "Room",
    Players = {},
    SongKey = 1,
    OnJoinClick = function()
    
    end
}

function Room:render()
    local hostName = self.props.Host and self.props.Host.Name or "Player"

    return e(RoundedFrame, {
        Size = UDim2.new(1, 0, 0, 110),
        BackgroundColor3 = Color3.fromRGB(26, 25, 25)
    }, {
        Name = e(RoundedTextLabel, {
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(255, 208, 87),
            TextScaled = true,
            Position = UDim2.fromScale(0.015, 0.04),
            Size = UDim2.fromScale(1, 0.35),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = if self.props.Locked then "🔒 " .. self.props.Name else self.props.Name,
            TextTruncate = Enum.TextTruncate.AtEnd
        }, {
            UITextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 60
            })
        }),
        Info = e(RoundedTextLabel, {
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(226, 226, 226),
            TextScaled = true,
            Position = UDim2.fromScale(0.015, 0.327),
            Size = UDim2.fromScale(1, 0.35),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = string.format("Host: %s, Number of Players: %d", hostName, Llama.Dictionary.count(self.props.Players))
        }, {
            UITextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 22
            })
        }),
        CurrentSongInfo = e(RoundedTextLabel, {
            BackgroundTransparency = 1,
            TextScaled = true,
            Position = UDim2.fromScale(0.015, 0.56),
            Size = UDim2.fromScale(1, 0.35),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Color3.fromRGB(161, 161, 161),
            Font = Enum.Font.Gotham,
            Text = string.format("Playing: %s - %s [%0.2fx rate]", SongDatabase:get_title_for_key(self.props.SongKey), SongDatabase:get_artist_for_key(self.props.SongKey), self.props.SongRate / 100)
        }, {
            UITextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 18
            })
        }),
        SongCover = e("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1;
            BorderSizePixel = 0,
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0.5, 0, 1, 0),
            ScaleType = Enum.ScaleType.Crop,
            Image = SongDatabase:get_image_for_key(self.props.SongKey)
        }, {
            e("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.75, 0.9),
                    NumberSequenceKeypoint.new(1, 1)
                }),
                Rotation = 180
            }),
            e("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),
        }),
        JoinButton = e(RoundedTextButton, {
            Size = UDim2.fromScale(0.075, 0.3),
            HoldSize = UDim2.fromScale(0.075, 0.3),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.953, 0.74),
            BackgroundColor3 = if self.props.InProgess then  Color3.fromRGB(46, 46, 46) else Color3.fromRGB(35, 65, 44),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "Join",
            TextSize = 15,
            ZIndex = 2,
            OnClick = function()
                if not self.props.InProgess then
                    self.props.OnJoinClick(self.props.RoomId)
                end
            end
        }),
    })
end

return Room