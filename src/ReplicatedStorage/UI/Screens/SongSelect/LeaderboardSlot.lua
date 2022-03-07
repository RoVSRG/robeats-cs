local Roact = require(game.ReplicatedStorage.Packages.Roact)
local e = Roact.createElement
local Flipper = require(game.ReplicatedStorage.Packages.Flipper)
local RoactFlipper = require(game.ReplicatedStorage.Packages.RoactFlipper)

local Mods = require(game.ReplicatedStorage.RobeatsGameCore.Enums.Mods)

local withInjection = require(game.ReplicatedStorage.UI.Components.HOCs.withInjection)

local RoundedTextLabel =  require(game.ReplicatedStorage.UI.Components.Base.RoundedTextLabel)
local RoundedImageLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedImageLabel)
local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)
local ButtonLayout = require(game.ReplicatedStorage.UI.Components.Base.ButtonLayout)

local RunService = game:GetService("RunService")

local LeaderboardSlot = Roact.Component:extend("LeaderboardSlot")

LeaderboardSlot.defaultProps = {
    Data = {
        UserId = 0,
        Place = 0,
        Accuracy = 0,
        Score = 0,
        Marvelouses = 0,
        Mean = 0,
        Rating = 0,
        Perfects = 0,
        Greats = 0,
        Goods = 0,
        Bads = 0,
        Misses = 0,
        Rate = 100,
        PlayerName = "Player1",
    },
    OnClick = function() end,
    OnBan = function() end,
    OnDelete = function() end
}

LeaderboardSlot.PlaceColors = {
	[1] = Color3.fromRGB(204, 204, 8);
	[2] = Color3.fromRGB(237, 162, 12);
	[3] = Color3.fromRGB(237, 106, 12);
}

LeaderboardSlot.SpreadString = "<font color=\"rgb(125, 125, 125)\">%d</font> <font color=\"rgb(55, 55, 55)\">/</font> <font color=\"rgb(99, 91, 15)\">%d</font> <font color=\"rgb(55, 55, 55)\">/</font> <font color=\"rgb(23, 99, 15)\">%d</font> <font color=\"rgb(55, 55, 55)\">/</font> <font color=\"rgb(15, 39, 99)\">%d</font> <font color=\"rgb(55, 55, 55)\">/</font> <font color=\"rgb(91, 15, 99)\">%d</font> <font color=\"rgb(55, 55, 55)\">/</font> <font color=\"rgb(99, 15, 21)\">%d</font>"

function LeaderboardSlot:init()
    self.scoreService = self.props.scoreService

    self.motor = Flipper.SingleMotor.new(0)
    self.motorBinding = RoactFlipper.getBinding(self.motor)

    self:setState({
        dialogOpen = false
    })
end

function LeaderboardSlot:didUpdate()
    self.motor:setGoal(Flipper.Spring.new(self.state.dialogOpen and 1 or 0, {
        dampingRatio = 2.5,
        frequency = 12
    }))
end

function LeaderboardSlot:render()
    local localUserId = game.Players.LocalPlayer and game.Players.LocalPlayer.UserId or 0

    return e(RoundedTextButton, {
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        HighlightBackgroundColor3 = Color3.fromRGB(24, 24, 24),
        BorderMode = Enum.BorderMode.Inset,
        BorderSizePixel = 0,
        Size = UDim2.new(0.9835, 0, 0, 25),
        HoldSize = UDim2.new(0.96, 0, 0, 25),
        Text = "",
        LayoutOrder = self.props.Data.Place,
        OnClick = function()
            self.props.OnClick(self.props.Data)
        end,
        OnRightClick = function()
            if self.props.IsAdmin then
                self:setState(function(state)
                    return {
                        dialogOpen = not state.dialogOpen
                    }
                end)
            end
        end;
        OnLongPress = function()
            if self.props.IsAdmin then
                self:setState(function(state)
                    return {
                        dialogOpen = not state.dialogOpen
                    }
                end)
            end
        end
    }, {
        Dialog = e(ButtonLayout, {
            Size = UDim2.fromScale(1, 1),
            Position = self.motorBinding:map(function(a)
                return UDim2.fromScale(1, 0):Lerp(UDim2.fromScale(0, 0), a)
            end),
            Padding = UDim.new(0, 8),
            DefaultSpace = 3,
            MaxTextSize = 15,
            Visible = self.motorBinding:map(function(a)
                return a > 0
            end),
            Buttons = {
                {
                    Text = "Delete score",
                    Color = Color3.fromRGB(238, 8, 8),
                    OnClick = function()
                        self.props.OnDelete(self.props.Data._id)
                    end
                },
                {
                    Text = "Ban user",
                    Color = Color3.fromRGB(240, 184, 0),
                    OnClick = function()
                        self.props.OnBan(self.props.Data.UserId, self.props.Data.PlayerName)
                    end
                },
                {
                    Text = "Back",
                    Color = Color3.fromRGB(37, 37, 37),
                    OnClick = function()
                        self:setState(function(state)
                            return {
                                dialogOpen = not state.dialogOpen
                            }
                        end)
                    end
                }
            }
        }),
        UserThumbnail = e(RoundedImageLabel, {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(13, 13, 13),
            Position = UDim2.new(0.09, 0, 0.5, 0),
            Size = UDim2.new(0.07, 0, 0.75, 0),
            Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userid=%d&width=420&height=420&format=png", self.props.Data.UserId)
        }, {
            e("UIAspectRatioConstraint", {
                AspectType = Enum.AspectType.ScaleWithParentSize,
                DominantAxis = Enum.DominantAxis.Height,
            }),
            Rating = e(RoundedTextLabel, {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(1.25, 0, 0.6, 0),
                Size = UDim2.new(12.75, 0, 0.35, 0),
                Font = Enum.Font.GothamSemibold,
                Text = if self.props.Data.Rating ~= 0 then string.format("Rating: %0.2f", self.props.Data.Rating) else string.format("Score: %d", self.props.Data.Score),
                TextColor3 = Color3.fromRGB(80, 80, 80),
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, {
                e("UITextSizeConstraint", {
                    MaxTextSize = 29,
                    MinTextSize = 3,
                })
            }),
            Spread = e(RoundedTextLabel, {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(4, 0, 0.6, 0),
                Size = UDim2.new(4.25, 0, 0.35, 0),
                Font = Enum.Font.GothamSemibold,
                RichText = true,
                Text = string.format(self.SpreadString, self.props.Data.Marvelouses, self.props.Data.Perfects, self.props.Data.Greats, self.props.Data.Goods, self.props.Data.Bads, self.props.Data.Misses),
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, {
                e("UITextSizeConstraint", {
                    MaxTextSize = 12,
                    MinTextSize = 4,
                })
            }),
            --self.props.Data.Marvelouses, self.props.Data.Perfects, self.props.Data.Greats, self.props.Data.Goods, self.props.Data.Bads, self.props.Data.Misses
            Player = e(RoundedTextLabel, {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(1.25, 0, 0, 0),
                Size = UDim2.new(15.3, 0, 0.55, 0),
                Font = Enum.Font.GothamSemibold,
                Text = if self.props.friendsController:IsFriend(self.props.Data.UserId) then "👥 " .. self.props.Data.PlayerName else self.props.Data.PlayerName,
                TextColor3 = (self.props.Data.UserId == localUserId) and Color3.fromRGB(25, 207, 231) or Color3.fromRGB(94, 94, 94),
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, {
                e("UITextSizeConstraint", {
                    MaxTextSize = 49,
                })
            });
            Mods = e(RoundedTextLabel, {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(8.6, 0, -0.1, 0),
                Size = UDim2.new(2.2, 0, 0.55, 0),
                Font = Enum.Font.GothamSemibold,
                Text = Mods:get_string_for_mods(self.props.Data.Mods or {}),
                RichText = true,
                TextColor3 = Color3.fromRGB(105, 105, 105),
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, {
                e("UITextSizeConstraint", {
                    MaxTextSize = 13,
                    MinTextSize = 7;
                })
            });
            AccuracyRate = e(RoundedTextLabel, {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(8.6, 0, 0.22, 0),
                Size = UDim2.new(2.2, 0, 0.55, 0),
                Font = Enum.Font.GothamSemibold,
                Text = string.format("<font color=\"rgb(181, 189, 181)\">%0.2f%%</font> | %0.2fx", self.props.Data.Accuracy, self.props.Data.Rate / 100),
                RichText = true,
                TextColor3 = Color3.fromRGB(105, 105, 105),
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, {
                e("UITextSizeConstraint", {
                    MaxTextSize = 13,
                    MinTextSize = 7;
                })
            })
        }),

        Place = e(RoundedTextLabel, {
            BackgroundColor3 = Color3.fromRGB(54, 54, 54),
            BorderSizePixel = 0,
            Position = UDim2.fromScale(0.0075, 0.1),
            Size = UDim2.fromScale(0.075, 0.755),
            Font = Enum.Font.GothamBold,
            Text = string.format("#%d", self.props.Data.Place),
            TextColor3 = Color3.fromRGB(71, 71, 70),
            TextScaled = true,
            BackgroundTransparency = 1;
        }, {
            e("UITextSizeConstraint", {
                MaxTextSize = 19,
                MinTextSize = 7,
            }),
        }),
        UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
            AspectRatio = 9,
            AspectType = Enum.AspectType.ScaleWithParentSize,
        })
    })
end

local Injected = withInjection(LeaderboardSlot, {
    friendsController = "FriendsController"
})

return Injected