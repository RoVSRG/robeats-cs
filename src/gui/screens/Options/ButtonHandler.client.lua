local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)

script.Parent.BackButton.MouseButton1Click:Connect(function()
	ScreenChief:Switch("MainMenu")
end)