local Roact = require(game.ReplicatedStorage.Packages.Roact)
local e = Roact.createElement
local Flipper = require(game.ReplicatedStorage.Packages.Flipper)
local RoactFlipper = require(game.ReplicatedStorage.Packages.RoactFlipper)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)
local RoundedTextLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextLabel)
local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)
local RoundedTextBox = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextBox)

local JoinLockedRoomDialog = Roact.Component:extend("JoinLockedRoomDialog")

JoinLockedRoomDialog.defaultProps = {
    OnJoin = function()
        
    end,
    OnBack = function()
        
    end
}

function JoinLockedRoomDialog:init()
    self.motor = Flipper.SingleMotor.new(0)
    self.motorBinding = RoactFlipper.getBinding(self.motor)

    self.state = {
        password = ""
    }
end

function JoinLockedRoomDialog:didUpdate()
    self.motor:setGoal(Flipper.Spring.new(if self.props.IsOpen then 1 else 0, {
        frequency = 8,
        dampingRatio = 2.5
    }))
end

function JoinLockedRoomDialog:render()
    return e(RoundedFrame, {
        Position = self.motorBinding:map(function(a)
            return UDim2.fromScale(1.5, 0.5):Lerp(UDim2.fromScale(0.5, 0.5), a)
        end),
        Size = UDim2.fromScale(0.3, 0.3),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    }, {
        Title = e(RoundedTextLabel, {
            Size = UDim2.fromScale(1, 0.2),
            Position = UDim2.fromScale(0.05, 0.05),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Text = "Room Name",
            TextScaled = true,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }),
        PasswordTitle = e(RoundedTextLabel, {
            Size = UDim2.fromScale(1, 0.1),
            Position = UDim2.fromScale(0.05, 0.35),
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Text = "Password",
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }),
        Password = e(RoundedTextBox, {
            Size = UDim2.fromScale(0.9, 0.2),
            Position = UDim2.fromScale(0.5, 0.55),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Text = self.state.password,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundColor3 = Color3.fromRGB(18, 18, 18),
            PlaceholderText = "",
            TextXAlignment = Enum.TextXAlignment.Left,
            TextScaled = true,
            [Roact.Change.Text] = function(password)
                self:setState({
                    password = password.Text
                })
            end
        }, {
            TextSizeConstraint = e("UITextSizeConstraint", {
                MaxTextSize = 20
            })
        }),
        JoinButton = e(RoundedTextButton, {
            Size = UDim2.fromScale(0.47, 0.14),
            HoldSize = UDim2.fromScale(0.47, 0.14),
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.fromScale(0.51, 0.97),
            BackgroundColor3 = Color3.fromRGB(3, 104, 8),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "Join",
            TextSize = 12,
            OnClick = function()
                self.props.OnJoin(self.state)
            end
        }),
        BackButton = e(RoundedTextButton, {
            Size = UDim2.fromScale(0.47, 0.14),
            HoldSize = UDim2.fromScale(0.47, 0.14),
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.fromScale(0.49, 0.97),
            BackgroundColor3 = Color3.fromRGB(212, 23, 23),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "Back",
            TextSize = 12,
            OnClick = function()
                self.props.OnBack()
            end
        })
    })
end

return JoinLockedRoomDialog
