local Roact = require(game.ReplicatedStorage.Packages.Roact)
local Flipper = require(game.ReplicatedStorage.Packages.Flipper)
local RoactFlipper = require(game.ReplicatedStorage.Packages.RoactFlipper)
local e = Roact.createElement
local f = Roact.createFragment

local RunService = game:GetService("RunService")

local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)

local withInjection = require(game.ReplicatedStorage.UI.Components.HOCs.withInjection)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)

local AudioVisualizer = Roact.Component:extend("AudioVisualizer")

function AudioVisualizer:init()
    self.motor = Flipper.SingleMotor.new(0)
    self.motorBinding = RoactFlipper.getBinding(self.motor)

    self.previewController = self.props.previewController

    local SoundInstance = self.previewController:GetSoundInstance()

    self.animateLinesPerFrame = SPUtil:bind_to_frame(function()
        self.motor:setGoal(Flipper.Spring.new(SoundInstance.PlaybackLoudness, {
            dampingRatio = 1.5,
            frequency = 10
        }))
    end)
end

function AudioVisualizer:render()
    local lines = {}

    local numOfLines = 120

    for i = 1, numOfLines do
        local lineElement = e("Frame", {
            Size = self.motorBinding:map(function(a)
                a += math.random(-40, 40)

                return UDim2.fromScale(1/numOfLines, a/650)
            end),
            BackgroundColor3 = Color3.fromRGB(99, 99, 99),
            LayoutOrder = i,
            BorderSizePixel = 0
        })

        table.insert(lines, lineElement)
    end

    return e(RoundedFrame, {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0.15),
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        ClipsDescendants = true
    }, {
        UIListLayout = e("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Bottom
        }),
        Lines = f(lines)
    })
end

function AudioVisualizer:willUnmount()
    if self.animateLinesPerFrame then
        self.animateLinesPerFrame:Disconnect()
    end
end

return withInjection(AudioVisualizer, {
    previewController = "PreviewController"
})