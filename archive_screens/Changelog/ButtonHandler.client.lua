local ScreenChief = require(game.ReplicatedStorage.Modules.ScreenChief)

script.Parent.OkButton.MouseButton1Click:Connect(function()
	ScreenChief:Switch("MainMenu")
end)