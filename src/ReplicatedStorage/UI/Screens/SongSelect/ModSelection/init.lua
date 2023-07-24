local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Flipper = require(game.ReplicatedStorage.Packages.Flipper)
local RoactFlipper = require(game.ReplicatedStorage.Packages.RoactFlipper)
local e = Roact.createElement
local f = Roact.createFragment
local Llama = require(game.ReplicatedStorage.Packages.Llama)

local Mods = require(game.ReplicatedStorage.RobeatsGameCore.Enums.Mods)

local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)
local RoundedTextLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextLabel)
local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)

local ModButton = require(script.ModButton)

local ModSelection = Roact.Component:extend("ModSelection")

ModSelection.defaultProps = {
    ActiveMods = {},
    OnModSelected = function() end,
    OnBackClicked = function() end,
    Mods = {
        [Mods.Mirror] = { 
            name = "Mirror",
            color = Color3.fromRGB(85, 212, 46)
        },
        [Mods.Sway] = {
            name = "Sway",
            color = Color3.fromRGB(188, 107, 226)
        }
    },
    Visible = true
}

function ModSelection:init()
    self.motor = Flipper.SingleMotor.new(self.props.Visible and 1 or 0)
    self.motorBinding = RoactFlipper.getBinding(self.motor)
end

function ModSelection:didUpdate()
    self.motor:setGoal(Flipper.Spring.new(self.props.Visible and 1 or 0, {
        frequency = 8,
        dampingRatio = 2.5
    }))
end

function ModSelection:render()
    local mods = {}

    for modId, mod in pairs(self.props.Mods) do
        mods[mod.name] = e(ModButton, {
            Name = mod.name,
            Color = mod.color,
            Selected = Llama.List.includes(self.props.ActiveMods, modId),
            OnClick = function()
                local isInMods = Llama.Dictionary.includes(self.props.ActiveMods, modId)

                local newMods

                if isInMods then
                    newMods = Llama.List.removeValue(self.props.ActiveMods, modId)
                else
                    newMods = Llama.List.push(self.props.ActiveMods, modId)
                end

                self.props.OnModSelected(newMods)
            end
        })
    end

    return e(RoundedFrame, {
        Size = UDim2.fromScale(0.7, 0.75),
        Position = self.motorBinding:map(function(a)
            return UDim2.fromScale(1.4, 0.5):Lerp(UDim2.fromScale(0.5, 0.5), a)
        end),
        BackgroundColor3 = Color3.fromRGB(22, 22, 22),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 2
    }, {
        ModContainer = e(RoundedFrame, {
            Size = UDim2.fromScale(0.95, 0.8),
            Position = UDim2.fromScale(0.5, 0.57),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1
        }, {
            Mods = f(mods),
            UIGridLayout = e("UIGridLayout")
        }),
        TitleDisplay = e(RoundedTextLabel, {
            Size = UDim2.fromScale(0.95, 0.1),
            Position = UDim2.fromScale(0.5, 0.04),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Text = "Mod Selection",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true
        }, {
            UITextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 27
            })
        }),
        BackButton = e(RoundedTextButton, {
            Size = UDim2.fromScale(0.05, 0.05),
            HoldSize = UDim2.fromScale(0.06, 0.06),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.035, 0.96),
            BackgroundColor3 = Color3.fromRGB(212, 23, 23),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "Back",
            TextSize = 12,
            OnClick = self.props.OnBackClicked
        })
    })
end

return ModSelection