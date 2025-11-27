local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local Iris = require(game.ReplicatedStorage.Libraries.Iris)

local Bindables = game.ReplicatedStorage.Bindables

local root = Instance.new("ScreenGui", playerGui)

local SongEditor = require(script.Parent:WaitForChild("Windows"):WaitForChild("SongEditor"))

Iris.Init(root)

local connection

-- External signal to (re)open the Song Editor window
Bindables.ShowSongEditor.Event:Connect(function()
	SongEditor.open()
	if not connection then
		connection = Iris:Connect(function()
			SongEditor.draw()
		end)
	end
end)
