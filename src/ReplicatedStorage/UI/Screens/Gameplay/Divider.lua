local Roact = require(game.ReplicatedStorage.Packages.Roact)
local e = Roact.createElement

local Flipper = require(game.ReplicatedStorage.Packages.Flipper)
local RoactFlipper = require(game.ReplicatedStorage.Packages.RoactFlipper)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)

local Divider = Roact.Component:extend("Divider")

function Divider:init()
    self.motor = Flipper.SingleMotor.new(0)
    self.motorBinding = RoactFlipper.getBinding(self.motor)
end

function Divider:didUpdate()
    self.motor:setGoal(Flipper.Spring.new(if self.props.Pressed then 1 else 0, {
        frequency = 3,
        dampingRatio = 0.5
    }))
end

function Divider:render()
    return e(RoundedFrame, {
        Size = UDim2.fromScale(1/self.props.LaneCount, 1),
        Position = UDim2.fromScale(self.props.Lane/self.props.LaneCount, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = self.motorBinding:map(function(a)
            return 1 - (a * 0.2)
        end),
        ZIndex = 0
    })
end

return Divider
