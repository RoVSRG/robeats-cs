local Roact = require(game.ReplicatedStorage.Packages.Roact)
local RoactRodux = require(game.ReplicatedStorage.Packages.RoactRodux)
local Llama = require(game.ReplicatedStorage.Packages.Llama)
local e = Roact.createElement
local f = Roact.createFragment

local Skins = require(game.ReplicatedStorage.Skins)

local Actions = require(game.ReplicatedStorage.Actions)

local RoundedFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedFrame)
local RoundedAutoScrollingFrame = require(game.ReplicatedStorage.UI.Components.Base.RoundedAutoScrollingFrame)
local RoundedTextButton = require(game.ReplicatedStorage.UI.Components.Base.RoundedTextButton)
local RoundedImageLabel = require(game.ReplicatedStorage.UI.Components.Base.RoundedImageLabel)

local function noop() end

local Skin = Roact.Component:extend("Skin")

Skin.defaultProps = {
    Size = UDim2.fromScale(0.8, 0.8),
    OnSkinSelected = function()

    end,
    OnBack = function()
        
    end
}

function Skin:init()
    self.gameplayFrame = Roact.createRef()
end

function Skin:didMount()
    self:applyGameplayFrame()
end

function Skin:didUpdate()
    self:applyGameplayFrame()
end

function Skin:applyGameplayFrame()
    local skin = Skins:get_skin(self.props.selectedSkin)

    if not skin then
        return
    end

    local mount = self.gameplayFrame:getValue()

    if mount:FindFirstChild("GameplayFrame") then
        mount:FindFirstChild("GameplayFrame"):Destroy()
    end

    local gameplayFrame = skin.GameplayFrame:Clone()
    gameplayFrame.Position = UDim2.fromScale(gameplayFrame.Position.X.Scale, 1.17)
    gameplayFrame.Size = UDim2.fromScale(0.4, 1.5)

    for i = 1, 4 do
        local previewSingle = skin.NoteProto:Clone()
        previewSingle.Parent = gameplayFrame.Tracks:FindFirstChild(string.format("Track%d", i))

        local previewHeld = skin.HeldNoteProto:Clone()
        previewHeld.Parent = gameplayFrame.Tracks:FindFirstChild(string.format("Track%d", i))
    end

    gameplayFrame.Parent = mount
end

function Skin:render()
    -- skin.NoteProto:FindFirstChildWhichIsA("ImageLabel").Image

    local skins = Llama.List.map(Skins:key_list()._table, function(skinName)
        return e(RoundedTextButton, {
            Size = UDim2.new(1, 0, 0, 40),
            HoldSize = UDim2.new(1, 0, 0, 40),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundColor3 = (self.props.selectedSkin == skinName) and Color3.fromRGB(19, 178, 206) or nil,
            Text = string.format("   %s", skinName),
            TextXAlignment = Enum.TextXAlignment.Left,
            OnClick = function()
                self.props.setSkin(skinName)
            end
        })
    end)

    -- local receptors = {}
    -- local objects = {}

    for i = 1, 4 do
        -- local triggerButton = skin.GameplayFrame.TriggerButtons:FindFirstChild(string.format("Button%d", i))
        -- local receptorImage = triggerButton:FindFirstChild("ReceptorImage") and triggerButton:FindFirstChild("ReceptorImage").Image

        -- receptors[i] = e(RoundedImageLabel, {
        --     Position = UDim2.fromScale((0.35 * i / 3) + 0.2, 0.95),
        --     Size = UDim2.fromScale(0.2, 0.2),
        --     AnchorPoint = Vector2.new(0.5, 1),
        --     Image = receptorImage
        -- }, {
        --     UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
        --         AspectRatio = 1
        --     })
        -- })

        -- local objectImage = skin.NoteProto:FindFirstChildWhichIsA("ImageLabel").Image

        -- objects[i] = e(RoundedImageLabel, {
        --     Position = UDim2.fromScale((0.35 * i / 3) + 0.2, 0.6*(i / 5)+0.2),
        --     Size = UDim2.fromScale(0.2, 0.2),
        --     AnchorPoint = Vector2.new(0.5, 1),
        --     Image = objectImage
        -- }, {
        --     UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
        --         AspectRatio = 1
        --     })
        -- })
    end

    return e(RoundedFrame, {
        Size = self.props.Size,
        Position = self.props.Position,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(22, 22, 22),
        ZIndex = self.props.ZIndex,
        Visible = self.props.Visible
    }, {
        SkinListContainer = e(RoundedAutoScrollingFrame, {
            Size = UDim2.fromScale(0.3, 0.8),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0.1, 0.5),
            BackgroundTransparency = 1,
            VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left,
            BorderSizePixel = 0
        }, {
            CategoryButtons = f(skins)
        }),
        SkinPreview = e(RoundedFrame, {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.32, 0),
            Size = UDim2.fromScale(0.65, 1),
            ClipsDescendants = true,
            [Roact.Ref] = self.gameplayFrame
        }),
        BackButton = e(RoundedTextButton, {
            Size = UDim2.fromScale(0.05, 0.05),
            HoldSize = UDim2.fromScale(0.06, 0.06),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.04, 0.95),
            BackgroundColor3 = Color3.fromRGB(212, 23, 23),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Text = "Back",
            TextSize = 12,
            OnClick = self.props.OnBack
        }),
    })
end

return RoactRodux.connect(function(state)
    return {
        selectedSkin = state.options.persistent.Skin2D
    }
end,
function(dispatch)
    return {
        setSkin = function(skin)
            dispatch(Actions.setPersistentOption("Skin2D", skin))
        end
    }
end)(Skin)