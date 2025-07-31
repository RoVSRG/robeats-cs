local ScreenChief = require(game:GetService("ReplicatedStorage").Modules.ScreenChief)

script.Parent.BackButton.MouseButton1Click:Connect(function()
    ScreenChief:Switch("MainMenu")
end)