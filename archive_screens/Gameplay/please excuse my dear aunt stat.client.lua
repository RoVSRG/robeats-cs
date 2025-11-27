local MAWindow = script.Parent.MAWindow

local Settings = require(game.ReplicatedStorage.State.Options)

local originalPosition = MAWindow.Position

Settings.Use2DMode:on(function(use2DMode)
    if use2DMode then
        MAWindow.Position = originalPosition + UDim2.new(0, 200, 0, 100)
    else
        MAWindow.Position = originalPosition
    end
end)
Settings.Use2DMode:set(Settings.Use2DMode:get(), true)