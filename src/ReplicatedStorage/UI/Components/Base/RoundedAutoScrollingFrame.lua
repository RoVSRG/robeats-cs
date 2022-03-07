local Roact = require(game.ReplicatedStorage.Packages.Roact)
local e = Roact.createElement
local f = Roact.createFragment

local Llama = require(game.ReplicatedStorage.Packages.Llama)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)

local RoundedAutoScrollingFrame = Roact.Component:extend("Button")

RoundedAutoScrollingFrame.defaultProps = {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(29, 29, 29);
    ZIndex = 1,
    UIListLayoutProps = {},
    BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
    TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
    ScrollBarThickness = 2
}

function RoundedAutoScrollingFrame:init()
    self.listLayoutRef = Roact.createRef()
end

function RoundedAutoScrollingFrame:didMount()
    local listLayout = self.listLayoutRef:getValue()

    local roundedScrollingFrame = listLayout.Parent
    self.onContentSizeChanged = listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listLayout.Parent.CanvasSize = UDim2.new(0, 0, 0, roundedScrollingFrame.UIListLayout.AbsoluteContentSize.Y)
    end)
end

function RoundedAutoScrollingFrame:render()
    local children = Llama.Dictionary.join(self.props[Roact.Children], {
        Corner = e("UICorner", {
            CornerRadius = UDim.new(0,4);
        });
        UIListLayout = e("UIListLayout", Llama.Dictionary.join(self.props.UIListLayoutProps, {
            [Roact.Ref] = self.listLayoutRef
        }))
    })

    local props = {
        BackgroundTransparency = 1
    }

    for i, v in pairs(self.props) do
        if i ~= Roact.Children and i ~= "UIListLayoutProps" and i ~= "BackgroundTransparency" then
            props[i] = v
        end
    end

    return f({
        e("ScrollingFrame", props, children),
        e(RoundedFrame, {
            Size = self.props.Size,
            Position = self.props.Position,
            AnchorPoint = self.props.AnchorPoint,
            BackgroundColor3 = self.props.BackgroundColor3,
            BackgroundTransparency = self.props.BackgroundTransparency,
            ZIndex = self.props.ZIndex - 1,
        })
    })
end

function RoundedAutoScrollingFrame:willUnmount()
    self.onContentSizeChanged:Disconnect()
end

return RoundedAutoScrollingFrame