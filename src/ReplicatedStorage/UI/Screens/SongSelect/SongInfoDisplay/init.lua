local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Flipper = require(game.ReplicatedStorage.Packages.Flipper)
local RoactFlipper = require(game.ReplicatedStorage.Packages.RoactFlipper)
local Llama = require(game.ReplicatedStorage.Packages.Llama)

local Rating = require(game.ReplicatedStorage.RobeatsGameCore.Enums.Rating)

local e = Roact.createElement
local f = Roact.createFragment

-- hjsdgrfkhjbsdgfhkjdsfghjbksdfghjbk

local NpsGraph = require(script.Parent.NpsGraph)
local GridInfoDisplay = require(script.GridInfoDisplay)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)
local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)
local RoundedImageLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedImageLabel)
local RoundedTextLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextLabel)

local SongInfoDisplay = Roact.Component:extend("SongInfoDisplay")

SongInfoDisplay.defaultProps = {
    Size = UDim2.fromScale(1, 1),
    SongRate = 100,
    OnUprate = function() end,
    OnDownrate = function() end,
    ShowRateButtons = true
}

local function noop() end

function SongInfoDisplay:init()
    self.onLeaderboardClick = self.props.onLeaderboardClick

    self.motor = Flipper.GroupMotor.new({
        title = 0;
        artist = 0;
    })
    self.motorBinding = RoactFlipper.getBinding(self.motor)
end

function SongInfoDisplay:didUpdate(prevProps)
    if self.props.SongKey ~= prevProps.SongKey then
        self.motor:setGoal({
            title = Flipper.Instant.new(0);
            artist = Flipper.Instant.new(0);
        })
        self.motor:step(0)
        self.motor:setGoal({
            title = Flipper.Spring.new(1, {
                frequency = 2;
                dampingRatio = 2.5;
            });
            artist = Flipper.Spring.new(1, {
                frequency = 2.5;
                dampingRatio = 2.5;
            });
        })
    end
end

function SongInfoDisplay:didMount()
    self.motor:setGoal({
        title = Flipper.Spring.new(1, {
            frequency = 4;
            dampingRatio = 2.5;
        });
        artist = Flipper.Spring.new(1, {
            frequency = 2.5;
            dampingRatio = 2.5;
        });
    })
end

function SongInfoDisplay:render()
    if self.props.SongKey == nil then
        return e(RoundedTextLabel, {
            Position = self.props.Position,
            Size = self.props.Size,
            AnchorPoint = self.props.AnchorPoint,
            Text = "Please select a map.",
            TextColor3 = Color3.fromRGB(221, 85, 85)
        })
    end
    
    local total_notes, total_holds, total_left_hand_objects, total_right_hand_objects = SongDatabase:get_note_metrics_for_key(self.props.SongKey)

    return e(RoundedFrame, {
        Position = self.props.Position,
        Size = self.props.Size,
        AnchorPoint = self.props.AnchorPoint,
        BackgroundColor3 = self.props.BackgroundColor3
    }, {
        SongCover = e(RoundedImageLabel, {
            Size = UDim2.fromScale(1, 1),
            ScaleType = Enum.ScaleType.Crop,
            Image = SongDatabase:get_image_for_key(self.props.SongKey),
            BackgroundTransparency = 1;
            ZIndex = 0
        }, {
            Gradient = e("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.75, 0.9),
                    NumberSequenceKeypoint.new(1, 1),
                });
                Rotation = -180;
            }),
        }),
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0, 4),
        }),
        SongDataContainer = e(RoundedFrame, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.02, 0, 0.035, 0),
            Size = UDim2.new(1, 0, 0.5, 0),
        }, {
            UIListLayout = e("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0.04, 0)
            }),
            TitleDisplay = e(RoundedTextLabel, {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = 1,
                Size = UDim2.new(0.75, 0, 0.5, 0);
                TextTransparency = self.motorBinding:map(function(a)
                    return 1-a.artist
                end);
                Font = Enum.Font.Gotham,
                Text = string.format("%s [%0.2fx Rate]", SongDatabase:get_title_for_key(self.props.SongKey), self.props.SongRate / 100),
                
                TextColor3 = Color3.fromRGB(255, 187, 14),
                TextScaled = true,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, {
                TextSizeConstraint = e("UITextSizeConstraint", {
                    MaxTextSize = 60,
                })
            }),
            ArtistDisplay = e(RoundedTextLabel, {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.75, 0, 0.3, 0);
                TextTransparency = self.motorBinding:map(function(a)
                    return 1-a.title
                end);
                Text = string.format("%s // %s", SongDatabase:get_artist_for_key(self.props.SongKey), SongDatabase:get_mapper_for_key(self.props.SongKey)),
                TextColor3 = Color3.fromRGB(255, 187, 14),
                TextScaled = true,
                LayoutOrder = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, {
                UITextSizeConstraint = e("UITextSizeConstraint", {
                    MaxTextSize = 40,
                })
            }),
        }),
        NpsGraph = e(NpsGraph, {
            Size = UDim2.fromScale(0.3, 0.45),
            Position = UDim2.fromScale(0.99, 0.925),
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            SongKey = self.props.SongKey,
            SongRate = self.props.SongRate
        }),
        SongMapDataContainer = e(RoundedFrame, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.025, 0, 0.78, 0),
            Size = UDim2.new(1, 0, 0.45, 0),
            AnchorPoint = Vector2.new(0, 0.5)
        }, {
            UIListLayout = e("UIGridLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Horizontal,
                FillDirectionMaxCells = 4,
                CellSize = UDim2.fromScale(0.1165, 0.33)
            }),
            DifficultyDisplay = e(GridInfoDisplay, {
                Value = SongDatabase:get_difficulty_for_key(self.props.SongKey, self.props.SongRate / 100),
                FormatValue = function(value)
                    return string.format("Difficulty: %d", value)
                end,
                LayoutOrder = 1
            }),
            TotalNotesDisplay = e(GridInfoDisplay, {
                Value = total_notes,
                FormatValue = function(value)
                    return string.format("Total Notes: %d", value)
                end,
                LayoutOrder = 2
            }),
            TotalHoldsDisplay = e(GridInfoDisplay, {
                Value = total_holds,
                FormatValue = function(value)
                    return string.format("Total Holds: %d", value)
                end,
                LayoutOrder = 3
            }),
            TotalObjectsDisplay = e(GridInfoDisplay, {
                Value = total_notes + total_holds,
                FormatValue = function(value)
                    return string.format("Total Objects: %d", value)
                end,
                LayoutOrder = 4
            });
            TotalLeftHandObjectsDisplay = e(GridInfoDisplay, {
                Value = total_left_hand_objects,
                FormatValue = function(value)
                    return string.format("LH Objects: %s", value)
                end,
                LayoutOrder = 5
            });
            TotalRightHandObjectsDisplay = e(GridInfoDisplay, {
                Value = total_right_hand_objects,
                FormatValue = function(value)
                    return string.format("RH Objects: %s", value)
                end,
                LayoutOrder = 6
            });
            LeftRightHandRatioDisplay = e(GridInfoDisplay, {
                Value = total_left_hand_objects / total_right_hand_objects,
                FormatValue = function(value)
                    return string.format("L/R Ratio: %0.2f", value)
                end,
                LayoutOrder = 7
            });
            TotalLengthDisplay = e(GridInfoDisplay, {
                Value = SongDatabase:get_song_length_for_key(self.props.SongKey) / (self.props.SongRate / 100),
                FormatValue = function(value)
                    return string.format("Total Length: %s", SPUtil:format_ms_time(value))
                end,
                LayoutOrder = 8
            })
        }),
        RateDown = self.props.ShowRateButtons and e(RoundedTextButton, {
            Text = "-",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundColor3 = Color3.fromRGB(90, 27, 27),
            Size = UDim2.fromScale(0.05, 0.2),
            HoldSize = UDim2.fromScale(0.055, 0.2),
            Position = UDim2.fromScale(0.55, 0.935),
            AnchorPoint = Vector2.new(0, 1),
            OnClick = self.props.OnDownrate
        }),
        RateUp = self.props.ShowRateButtons and e(RoundedTextButton, {
            Text = "+",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundColor3 = Color3.fromRGB(55, 105, 40),
            Size = UDim2.fromScale(0.05, 0.2),
            HoldSize = UDim2.fromScale(0.055, 0.2),
            Position = UDim2.fromScale(0.61, 0.935),
            AnchorPoint = Vector2.new(0, 1),
            OnClick = self.props.OnUprate
        })
    })
end

return SongInfoDisplay