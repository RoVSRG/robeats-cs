local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local Iris = require(game.ReplicatedStorage.Libraries.Iris)

local Bindables = game.ReplicatedStorage.Bindables

local root = Instance.new("ScreenGui", playerGui)

Iris.Init(root)

Bindables.ShowSongEditor.Event:Connect(function()
	Iris:Connect(require(script.Parent.Windows.SongEditor))
end)
