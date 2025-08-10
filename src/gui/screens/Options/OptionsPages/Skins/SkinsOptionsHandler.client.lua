local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)
local Skins = require(game.ReplicatedStorage.Skins)
local Options = require(game.ReplicatedStorage.State.Options)

local Templates = ScreenChief:GetTemplates("Options")
local SkinButton: TextButton = Templates:FindFirstChild("SkinButton")

local container = script.Parent:FindFirstChild("SkinsList")
container.CanvasSize = UDim2.new(1, 0, 0, 0)

local function renderSkin(skinName: string)
    local skin = Skins:get_skin(skinName)

    local gameplayFrameBase = skin:FindFirstChild("GameplayFrame")

    if not gameplayFrameBase then
        return
    end
    
    local info = script.Parent.Metadata.Info
    info.SkinName.Text = skinName

    local mnt = script.Parent.Metadata.SkinMount
    
    for _, child in mnt:GetChildren() do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local gameplayFrame = gameplayFrameBase:Clone()
    gameplayFrame.Position = UDim2.fromScale(0.5, 1)
    gameplayFrame.Size = UDim2.fromScale(1, 1)
    gameplayFrame.Parent = mnt

    for i = 1, 4 do
        local trackMount = gameplayFrame:FindFirstChild("Tracks"):FindFirstChild("Track" .. i)

        local note = skin:FindFirstChild("NoteProto"):Clone()
        note.Parent = trackMount
        note.Position = UDim2.fromScale(0.5, math.random(30, 70) / 100)
    end
end

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
    end)

    container.CanvasSize = UDim2.new(0, 0, 0, container.CanvasSize.Y.Offset + clone.Size.Y.Offset)
end

Options.Skin2D:on(renderSkin)