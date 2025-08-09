local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")

local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local Skins = require(game.ReplicatedStorage.Skins)
local Color = require(game.ReplicatedStorage.Shared.Color)

local Options = require(game.ReplicatedStorage.State.Options)

local Templates = ScreenChief:GetTemplates("Options")

local SkinButton: TextButton = Templates:FindFirstChild("SkinButton")

local container = script.Parent:FindFirstChild("SkinsList")

container.CanvasSize = UDim2.new(1, 0, 0, 0)

for _, skin in Skins:key_itr() do
    local skinName = skin.Name

    local clone = SkinButton:Clone()
    clone.Name = skinName
    clone.Text = skinName
    clone.Visible = true
    clone.BackgroundColor3 = Color3.new(math.random(), math.random(), math.random())

    clone.Parent = container

    clone.MouseButton1Click:Connect(function()
        Options.Skin2D:set(skinName)

        ContentProvider:PreloadAsync({ skin })
    end)

    container.CanvasSize = UDim2.new(0, 0, 0, container.CanvasSize.Y.Offset + clone.Size.Y.Offset)
end