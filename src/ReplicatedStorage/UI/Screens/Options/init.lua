local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Rodux = require(game.ReplicatedStorage.Packages.Rodux)
local Llama = require(game.ReplicatedStorage.Packages.Llama)
local RoactRodux = require(game.ReplicatedStorage.Packages.RoactRodux)
local Flipper = require(game.ReplicatedStorage.Packages.Flipper)
local RoactFlipper = require(game.ReplicatedStorage.Packages.RoactFlipper)
local e = Roact.createElement
local f = Roact.createFragment
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local RunService = game:GetService("RunService")

local Skin = require(game.ReplicatedStorage.UI.Screens.Options.Skin)

local Skins = require(game.ReplicatedStorage.Skins)
local Actions = require(game.ReplicatedStorage.Actions)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)
local RoundedAutoScrollingFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedAutoScrollingFrame)
local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)

local IntValue = require(script.IntValue)
local KeybindValue = require(script.KeybindValue)
local BoolValue = require(script.BoolValue)
local MultipleChoiceValue = require(script.MultipleChoiceValue)
local EnumValue = require(script.EnumValue)
local ColorValue = require(script.ColorValue)
local ButtonValue = require(script.ButtonValue)

local withInjection = require(game.ReplicatedStorage.UI.Components.HOCs.withInjection)

local Options = Roact.Component:extend("Options")

Options.categoryList = {"⚙ General", "🖥️ Interface", "➕ Extra", "⬜ 2D", "📱 Mobile"}

function noop() end

function Options:init()
    self.motor = Flipper.SingleMotor.new(self.props.location.state.OptionsVisible and 1 or 0)
    self.motorBinding = RoactFlipper.getBinding(self.motor)

    self:setState({
        selectedCategory = 1,
        skinMenuOpen = false
    })

    self.motor:onComplete(function()
        if self.motor:getValue() == 0 then
            self.props.settingsService:SetSettings(self.props.options)
                :andThen(function()
                    DebugOut:puts("Successfully saved settings!")
                end)
                :catch(function()
                    DebugOut:warnf("There was an error saving settings!")
                end)
        end
    end)
end

function Options:getSettingElements()
    local elements = {}

    SPUtil:switch(self.state.selectedCategory):case(1, function()
        --field of view
        elements.FOV = e(IntValue, {
            Value = self.props.options.FOV;
            OnChanged = function(value)
                self.props.setOption("FOV", value)
            end;
            Name = "Field of View (FOV)";
            FormatValue = function(value)
                return string.format("%d", value)
            end;
            MaxValue = 120,
            MinValue = 1,
            LayoutOrder = 5
        });

        --Notespeed
        elements.NoteSpeed = e(IntValue, {
            Value = self.props.options.NoteSpeed,
            OnChanged = function(value)
                self.props.setOption("NoteSpeed", value)
            end,
            FormatValue = function(value)
                if value >= 0 then
                    return string.format("+%d", value)
                end
                return string.format("%d", value)
            end,
            Name = "Note Speed",
            MinValue = 0,
            MaxValue = 100,
            LayoutOrder = 3
        })

        --Audio Offset
        elements.AudioOffset = e(IntValue, {
            Value = self.props.options.AudioOffset,
            OnChanged = function(value)
                self.props.setOption("AudioOffset", value)
            end,
            Name = "Audio Offset",
            FormatValue = function(value)
                return string.format("%d ms", value)
            end,
            LayoutOrder = 4,
            MinValue = -300,
            MaxValue = 300
        })
        --Keybinds

        elements.InGameKeybinds = e(KeybindValue, {
            Values = {
                self.props.options.Keybind1,
                self.props.options.Keybind2,
                self.props.options.Keybind3,
                self.props.options.Keybind4
            },
            Name = "In-Game Keybinds",
            OnChanged = function(index, value)
                self.props.setOption(string.format("Keybind%d", index), value)
            end,
            LayoutOrder = 1
        });


        elements.JudgementVisibility = e(MultipleChoiceValue, {
            Values = self.props.options.JudgementVisibility,
            ValueNames = { "Miss", "Bad", "Good", "Great", "Perfect", "Marvelous" },
            OnChanged = function(noteResult, value)
                local judgements = Llama.Dictionary.copy(self.props.options.JudgementVisibility)
                judgements[noteResult] = value

                self.props.setOption("JudgementVisibility", judgements)
            end,
            Name = "Judgement Visibility",
            LayoutOrder = 3
        })

        elements.TimingPreset = e(EnumValue, {
            Value = self.props.options.TimingPreset,
            ValueNames = { "Lenient", "Standard", "Strict", "ROFAST GAMER" },
            OnChanged = function(name)
                self.props.setOption("TimingPreset", name)
            end,
            Name = "Timing Preset",
            LayoutOrder = 2
        })
    end)
    
    --UI settings
    :case(2, function()
        elements.ComboPosition = e(EnumValue,{
            Value = self.props.options.ComboPosition,
            ValueNames = {"Left", "Middle", "Right", "Top", "Bottom"},
            OnChanged = function(name)
                self.props.setOption("ComboPosition", name)
            end,
            Name = "Combo Position",
            LayoutOrder = 0;
        })

        elements.InGameLeaderboardPosition = e(EnumValue, {
            Value = self.props.options.InGameLeaderboardPosition,
            ValueNames = {"Left", "Right"},
            OnChanged = function(name)
                self.props.setOption("InGameLeaderboardPosition", name)
            end,
            Name = "In-Game Leaderboard Position",
            LayoutOrder = 1;
        })

        elements.LaneCover = e(IntValue, {
            Value = self.props.options.LaneCover,
            OnChanged = function(value)
                self.props.setOption("LaneCover", value)
            end,
            FormatValue = function(value)
                return string.format("%0d%%", value)
            end,
            Name = "Lane Cover",
            incrementValue = 5,
            MinValue = 0,
            MaxValue = 100,
            LayoutOrder = 3
        })

        elements.NoteColor = e(ColorValue, {
            Value = self.props.options.NoteColor,
            OnChanged = function(value)
                self.props.setOption("NoteColor", value)
            end,
            Name = "Note Color",
            LayoutOrder = 4
        })
    end)
    --extras
    :case(3, function()
        elements.BaseTransparency = e(IntValue, {
            Name = "Base Transparency",
            incrementValue = 0.1;
            Value = self.props.options.BaseTransparency,
            OnChanged = function(value)
                self.props.setOption("BaseTransparency", value)
            end,
            FormatValue = function(value)
                return string.format("%0.1f", value)
            end,
            MaxValue = 1,
            MinValue = 0,
            LayoutOrder = 2
        });


        elements.TimeOfDay = e(IntValue, {
            Value = self.props.options.TimeOfDay,
            OnChanged = function(value)
                self.props.setOption("TimeOfDay", value)
            end,
            Name = "Time of Day",
            FormatValue = function(value)
                return string.format("%d", value)
            end,
            MaxValue = 24,
            MinValue = 0,
            LayoutOrder = 1
        });

        elements.TransparentHeldNote = e(BoolValue, {
            Value = self.props.options.TransparentHeldNote,
            OnChanged = function(value)
                self.props.setOption("TransparentHeldNote", value)
            end,
            Name = "Held Note Transparent",
            LayoutOrder = 3
        })

        elements.HitLighting = e(BoolValue, {
            Value = self.props.options.HitLighting,
            OnChanged = function(value)
                self.props.setOption("HitLighting", value)
            end,
            Name = "Hit Lighting",
            LayoutOrder = 4
        });

        elements.HidePlayerList = e(BoolValue, {
            Value = not self.props.options.HidePlayerList,
            OnChanged = function(value)
                self.props.setOption("HidePlayerList", not value)
            end,
            Name = "Playerlist Visible",
            LayoutOrder = 5
        });

        elements.HideChat = e(BoolValue, {
            Value = not self.props.options.HideChat,
            OnChanged = function(value)
                self.props.setOption("HideChat", not value)
            end,
            Name = "Chat Visible",
            LayoutOrder = 6
        });

        elements.HideLNTails = e(BoolValue, {
            Value = self.props.options.HideLNTails,
            OnChanged = function(value)
                self.props.setOption("HideLNTails", value)
            end,
            Name = "Hide LN Tails",
            LayoutOrder = 7
        })

        elements.HideLeaderboard = e(BoolValue, {
            Value = self.props.options.HideLeaderboard,
            OnChanged = function(value)
                self.props.setOption("HideLeaderboard", value)
            end,
            Name = "Hide In-Game Leaderboard",
            LayoutOrder = 8
        })
    end)
    -- 2D related
    :case(4, function()
        elements.Use2DLane = e(BoolValue, {
            Value = self.props.options.Use2DLane,
            OnChanged = function(value)
                self.props.setOption("Use2DLane", value)
            end,
            Name = "2D Toggle",
            LayoutOrder = 1
        })

        elements.Upscroll = e(BoolValue, {
            Value = self.props.options.Upscroll,
            OnChanged = function(value)
                self.props.setOption("Upscroll", value)
            end,
            Name = "Upscroll Mode",
            LayoutOrder = 2
        })

        elements.NoteColorAffects2D = e(BoolValue, {
            Value = self.props.options.NoteColorAffects2D,
            OnChanged = function(value)
                self.props.setOption("NoteColorAffects2D", value)
            end,
            Name = "Let Note Color determine 2D object colors",
            LayoutOrder = 3
        })

        elements.PlayfieldWidth = e(IntValue, {
            Value = self.props.options.PlayfieldWidth,
            OnChanged = function(value)
                self.props.setOption("PlayfieldWidth", value)
            end,
            Name = "Playfield Width",
            FormatValue = function(value)
                return string.format("%d", value)
            end,
            MaxValue = 100,
            MinValue = 5,
            LayoutOrder = 4
        })

        elements.PlayfieldHitPos = e(IntValue, {
            Value = self.props.options.PlayfieldHitPos,
            OnChanged = function(value)
                self.props.setOption("PlayfieldHitPos", value)
            end,
            Name = "Playfield Hit Position",
            FormatValue = function(value)
                return string.format("%d", value)
            end,
            MaxValue = 60,
            MinValue = 1,
            LayoutOrder = 5
        })

        elements.SelectSkin = e(ButtonValue, {
            Value = self.props.options.Skin2D,
            ValueNames = Skins:key_list()._table,
            OnClick = function()
                self:setState({
                    skinMenuOpen = not self.state.skinMenuOpen
                })
            end,
            Name = "Select Skin",
            ButtonText = "Open Skin Selection Panel",
            LayoutOrder = 6
        })
    end):case(5, function()
        elements.DividersEnabled = e(BoolValue, {
            Value = self.props.options.DividersEnabled,
            OnChanged = function(value)
                self.props.setOption("DividersEnabled", value)
            end,
            Name = "Mobile Dividers Enabled"
        })
    end)
    

    return elements
end

function Options:render()
    if self.state.skinMenuOpen then
        return e(Skin, {
            Position = self.motorBinding:map(function(a)
                return UDim2.fromScale(1.5, 0.5):Lerp(UDim2.fromScale(0.5, 0.5), a)
            end),
            Visible = self.motorBinding:map(function(a)
                return a > 0
            end),
            OnBack = function()
                self:setState({
                    skinMenuOpen = false
                })
            end,
            ZIndex = 3
        })
    end

    local options = self:getSettingElements()

    local categories = {}

    for i, category in ipairs(self.categoryList) do
        local backgroundColor3
        local highlightBackgroundColor3

        if i == self.state.selectedCategory then
            backgroundColor3 = Color3.fromRGB(5, 64, 71)
            highlightBackgroundColor3 = Color3.fromRGB(17, 110, 121)
        else
            backgroundColor3 = Color3.fromRGB(20, 20, 20)
            highlightBackgroundColor3 = Color3.fromRGB(48, 45, 45)
        end

        local categoryButton = e(RoundedTextButton, {
            Size = UDim2.new(1, 0, 0, 50),
            HoldSize = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = backgroundColor3,
            HighlightBackgroundColor3 = highlightBackgroundColor3,
            Text = string.format("  - %s", category),
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            LayoutOrder = i,
            OnClick = function()
                self:setState({
                    selectedCategory = i
                })
            end
        }, {
            UITextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 20,
                MinTextSize = 12
            }),
            UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
                AspectRatio = 5,
                AspectType = Enum.AspectType.ScaleWithParentSize
            })
        })

        table.insert(categories, categoryButton)
    end

    return e(RoundedFrame, {
        Position = self.motorBinding:map(function(a)
            return UDim2.fromScale(1.5, 0.5):Lerp(UDim2.fromScale(0.5, 0.5), a)
        end),
        Visible = self.motorBinding:map(function(a)
            return a > 0
        end),
        BackgroundColor3 = Color3.fromRGB(22, 22, 22),
        Size = UDim2.fromScale(0.8, 0.8),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 3
    }, {
        SettingsContainer = e(RoundedAutoScrollingFrame, {
            Size = UDim2.fromScale(0.6, 0.8),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0.32, 0.5),
            BackgroundColor3 = Color3.fromRGB(23, 23, 23),
            UIListLayoutProps = {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }
        }, {
            Options = f(options)
        }),
        SettingsCategoriesContainer = e(RoundedAutoScrollingFrame, {
            Size = UDim2.fromScale(0.23, 0.8),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0.08, 0.5),
            BackgroundColor3 = Color3.fromRGB(23, 23, 23),
            UIListLayoutProps = {
                Padding = UDim.new(0, 4),
            }
        }, {
            CategoryButtons = f(categories)
        }),
        BackButton = e(RoundedTextButton, {
            Size = UDim2.fromScale(0.05, 0.05),
            HoldSize = UDim2.fromScale(0.06, 0.06),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.05, 0.95),
            BackgroundColor3 = Color3.fromRGB(212, 23, 23),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "Back",
            TextSize = 12,
            OnClick = function()
                self.props.history:goBack()
            end
        }),
    })
end

function Options:didUpdate(prevProps)
    if self.props.location.state.OptionsVisible == prevProps.location.state.OptionsVisible then
        return
    end

    self.motor:setGoal(Flipper.Spring.new(self.props.location.state.OptionsVisible and 1 or 0, {
        frequency = 4,
        dampingRatio = 1.2
    }))
end

local Injected = withInjection(Options, {
    settingsService = "SettingsService"
})

return RoactRodux.connect(function(state)
    return {
        options = state.options.persistent
    }
end,
function(dispatch)
    return {
        setOption = function(...)
            dispatch(Actions.setPersistentOption(...))
        end
    }
end)(Injected)