local Flipper = require(game.ReplicatedStorage.Packages.Flipper)

local Knit = require(game:GetService("ReplicatedStorage").Knit)

local PreviewController = Knit.CreateController { Name = "PreviewController" }

local function noop() end

local Audio
local AudioVolumeMotor

function PreviewController:KnitInit()
    Audio = Instance.new("Sound")
    Audio.Parent = game.SoundService

    AudioVolumeMotor = Flipper.SingleMotor.new(0)
end

function PreviewController:KnitStart()
    AudioVolumeMotor:onStep(function(a)
        Audio.Volume = a
    end)    
end

function PreviewController:PlayId(id, callback)
    if Audio.SoundId == id then return end

    callback = callback or noop
    AudioVolumeMotor:setGoal(Flipper.Instant.new(0))

    Audio.SoundId = id

    local con
    con = Audio.Loaded:Connect(function()
        con:Disconnect()
        callback(Audio)

        Audio:Play()

        -- Start animating the volume
        self:Speak()
    end)

    return Audio
end

function PreviewController:SetRate(rate)
    Audio.PlaybackSpeed = rate
end

function PreviewController:Silence()
    AudioVolumeMotor:setGoal(Flipper.Spring.new(0, {
        frequency = 7,
        dampingRatio = 6
    }))
end

function PreviewController:Speak()
    AudioVolumeMotor:setGoal(Flipper.Spring.new(0.5, {
        frequency = 2.7,
        dampingRatio = 6
    }))
end

return PreviewController