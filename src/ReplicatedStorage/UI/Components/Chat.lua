local Roact = require(game.ReplicatedStorage.Packages.Roact)
local e = Roact.createElement

local RoactRodux = require(game.ReplicatedStorage.Packages.RoactRodux)
local Llama = require(game.ReplicatedStorage.Packages.Llama)
local Trove = require(game.ReplicatedStorage.Packages.Trove)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)

local RoundedAutoScrollingFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedAutoScrollingFrame)
local RoundedTextLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextLabel)
local RoundedTextBox = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextBox)

local withInjection = require(game.ReplicatedStorage.UI.Components.HOCs.withInjection)

local Chat = Roact.Component:extend("Chat")

Chat.defaultProps = {
    Position = UDim2.fromScale(0, 0),
    Size = UDim2.fromScale(0.95, 0.3),
    ZIndex = 3,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Channel = "general"
}

function Chat:init()
    self.trove = Trove.new()

    self:setState({
        message = ""
    })

    self.scrollingFrame = Roact.createRef()
end

function Chat:didUpdate()
    local scrollingFrame = self.scrollingFrame:getValue()

    if scrollingFrame.CanvasPosition.Y >= scrollingFrame.AbsoluteCanvasSize.Y - scrollingFrame.AbsoluteSize.Y - 10 then
        scrollingFrame.CanvasPosition = Vector2.new(0, scrollingFrame.AbsoluteCanvasSize.Y - scrollingFrame.AbsoluteSize.Y)
    end
end

function Chat:render()
    local messages = {}

    for i, message in ipairs(self.props.messages) do
        if message.channel == self.props.Channel then
            table.insert(messages, e(RoundedTextLabel, {
                Text = string.format("<font color=\"#A1A1A1\">%s:</font> %s", message.player.Name, message.message),
                RichText = true,
                Size = UDim2.new(0.95, 0, 0, 18),
                TextSize = 16,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true,
                LayoutOrder = i
            }))
        end
    end

    return e(RoundedFrame, {
        Position = self.props.Position,
        Size = self.props.Size,
        BackgroundColor3 = Color3.fromRGB(14, 14, 14),
        BackgroundTransparency = 0.5,
        ZIndex = self.props.ZIndex
    }, {
        MessageContainer = e(RoundedAutoScrollingFrame, {
            Position = UDim2.fromScale(0.02, 0),
            Size = UDim2.fromScale(0.98, 0.91),
            BackgroundTransparency = 1,
            [Roact.Ref] = self.scrollingFrame,
            UIListLayoutProps = {
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                Padding = UDim.new(0, 3)
            }
        }, messages),
        MessageTextBox = e(RoundedTextBox, {
            Position = UDim2.fromScale(0.5, 0.98),
            Size = UDim2.new(0.97, 0, 0, 25),
            AnchorPoint = Vector2.new(0.5, 1),
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundColor3 = Color3.fromRGB(27, 27, 27),
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            Text = self.state.message,
            TextWrapped = true,
            PlaceholderText = "Type a message...",
            [Roact.Change.Text] = function(message)
                self:setState({
                    message = message.Text
                })
            end,
            [Roact.Event.FocusLost] = function(_, enterPressed)
                if not enterPressed then
                    return
                end

                if self.state.message == "" then
                    return
                end
                
                self.props.chatService:Chat(self.props.Channel, self.state.message)

                self:setState({
                    message = ""
                })
            end
        })
    })
end

function Chat:willUnmount()
    self.trove:Destroy()
end

local Injected = withInjection(Chat, {
    chatService = "ChatService"
})

return RoactRodux.connect(function(state)
    return {
        messages = state.chat.messages
    }
end)(Injected)
